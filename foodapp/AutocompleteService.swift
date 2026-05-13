//
//  AutocompleteService.swift
//  PitStop
//
//  Wraps Google Places Autocomplete (NEW API) + Place Details into
//  something SwiftUI can subscribe to.
//
//  Uses fetchAutocompleteSuggestions(from:) which returns the new
//  GMSAutocompleteSuggestion type (replaces deprecated
//  GMSAutocompletePrediction).
//

import Foundation
import Combine
import CoreLocation
import GooglePlaces

// MARK: - Resolved destination

/// What we hand off to the rest of the app once the driver picks an address.
struct ResolvedDestination: Equatable {
    let placeID: String
    let primaryText: String       // "Apple Park"
    let secondaryText: String     // "Cupertino, CA, USA"
    let formattedAddress: String  // "1 Apple Park Way, Cupertino, CA 95014"
    let coordinate: CLLocationCoordinate2D

    static func == (lhs: ResolvedDestination, rhs: ResolvedDestination) -> Bool {
        lhs.placeID == rhs.placeID
    }
}

// MARK: - Autocomplete service

@MainActor
final class AutocompleteService: ObservableObject {

    /// What the dropdown shows. Updates as the user types.
    @Published var suggestions: [GMSAutocompleteSuggestion] = []

    /// True while a network request is in flight.
    @Published var isSearching: Bool = false

    /// Most recent error, if any.
    @Published var errorMessage: String?

    // One per search session — discarded when the user picks something.
    private var sessionToken = GMSAutocompleteSessionToken()
    private let placesClient = GMSPlacesClient.shared()

    // Combine pipeline that debounces queries.
    private let querySubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupDebouncedSearch()
    }

    private func setupDebouncedSearch() {
        querySubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query)
            }
            .store(in: &cancellables)
    }

    /// Call this on every keystroke. Internally debounced.
    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            suggestions = []
            isSearching = false
            return
        }

        querySubject.send(trimmed)
    }

    /// Called after the debounce delay. Uses the new fetchAutocompleteSuggestions API.
    private func performSearch(_ query: String) {
        isSearching = true
        errorMessage = nil

        let request = GMSAutocompleteRequest(query: query)
        request.sessionToken = sessionToken
        // request.filter = GMSAutocompleteFilter()  // add filter here if needed later

        placesClient.fetchAutocompleteSuggestions(from: request) { [weak self] results, error in
            guard let self = self else { return }

            self.isSearching = false

            if let error = error {
                self.errorMessage = error.localizedDescription
                self.suggestions = []
                return
            }

            self.suggestions = results ?? []
        }
    }

    /// Called when the user taps a suggestion. Fetches place details using
    /// the same session token so the whole search bills as one session.
    func resolve(
        _ suggestion: GMSAutocompleteSuggestion,
        completion: @escaping (ResolvedDestination?) -> Void
    ) {
        // The suggestion wraps a placePrediction with the real data
        guard let placePrediction = suggestion.placeSuggestion else {
            completion(nil)
            return
        }

        let placeID = placePrediction.placeID
        let primary = placePrediction.attributedPrimaryText.string
        let secondary = placePrediction.attributedSecondaryText?.string ?? ""
        let fullText = placePrediction.attributedFullText.string

        let fields: GMSPlaceField = [.placeID, .name, .formattedAddress, .coordinate]

        placesClient.fetchPlace(
            fromPlaceID: placeID,
            placeFields: fields,
            sessionToken: sessionToken
        ) { [weak self] place, error in
            guard let self = self else { return }

            // Start a fresh session token for the next search
            self.sessionToken = GMSAutocompleteSessionToken()

            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(nil)
                return
            }

            guard let place = place else {
                completion(nil)
                return
            }

            let resolved = ResolvedDestination(
                placeID: placeID,
                primaryText: primary,
                secondaryText: secondary,
                formattedAddress: place.formattedAddress ?? fullText,
                coordinate: place.coordinate
            )
            completion(resolved)
        }
    }
}
