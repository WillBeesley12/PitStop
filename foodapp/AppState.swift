//
//  AppState.swift
//  PitStop
//
//  Central state object that the UI observes. Coordinates between
//  SpeechService, textParseLLM, NearbyRestaurants, and RestaurantRanker.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation
import GooglePlaces

// MARK: - Screen mode

enum AppMode: Equatable {
    case askingDestination  // App opens here, driver picks destination
    case idle               // Big mic, "Tap and tell me what you're hungry for"
    case listening          // Mic open, capturing speech
    case thinking           // LLM parsing + Places search running
    case results            // Showing restaurant cards
    case error(String)
}

// MARK: - AppState

@MainActor
final class AppState: ObservableObject {

    // Parses "one", "two", "three", "1", "2", "3" from spoken text and
    // returns the matching 0-based index, or nil if no match.
    private func parseSelectionIndex(from text: String) -> Int? {
        let lower = text.lowercased()
        if lower.contains("one")   || lower.contains("1") || lower.contains("first")  { return 0 }
        if lower.contains("two")   || lower.contains("2") || lower.contains("second") { return 1 }
        if lower.contains("three") || lower.contains("3") || lower.contains("third")  { return 2 }
        return nil
    }
    // Services
    private let speechService = SpeechService()
    private let llm = textParseLLM()
    private let routeService = RouteService(apiKey: Secrets.googlePlacesAPIKey)
    private lazy var nearby = NearbyRestaurants(routeService: routeService)
    private lazy var ranker = RestaurantRanker(routeService: routeService)
    private let locationManager = CLLocationManager()

    // MARK: - Published UI state

    @Published var mode: AppMode = .askingDestination

    /// The destination the driver picked from autocomplete. Has the
    /// placeID, coordinate, and formatted address — everything routing
    /// needs. Nil until they confirm. Locked once set.
    @Published var destination: ResolvedDestination?

    @Published var liveTranscript: String = ""
    @Published var spokenQuery: String = ""
    @Published var restaurants: [ScoredRestaurant] = []
    @Published var topPickIndex: Int = 0
    @Published var ttsCurrentText: String = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        bindToSpeechService()
    }

    private func bindToSpeechService() {
        speechService.$transcribedText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                guard let self else { return }
                self.liveTranscript = text
                
                // Only auto-stop on the results screen, only while actively listening,
                // and only when we have a clear selection. The mode check + guard
                // below prevents double-firing if a late transcript arrives.
                guard case .listening = self.mode else { return }
                guard !self.restaurants.isEmpty else { return }
                guard self.parseSelectionIndex(from: text) != nil else { return }
                
                // Flip mode immediately so further transcripts skip this block
                self.mode = .results
                self.handleSelection(from: text)
                self.speechService.stopListening()
            }
            .store(in: &cancellables)
    }

    // MARK: - Destination flow

    /// Called when the driver picks a place from the autocomplete dropdown.
    func confirmDestination(_ resolved: ResolvedDestination) {
        destination = resolved
        mode = .idle
        print("📍 Destination locked: \(resolved.formattedAddress)")
        print("   placeID: \(resolved.placeID)")
        print("   coord:   \(resolved.coordinate.latitude), \(resolved.coordinate.longitude)")
    }

    // MARK: - User actions

    func micTapped() {
        switch mode {
        case .askingDestination:
            break
        case .idle, .results, .error:
            startListening()
        case .listening:
            stopListeningAndProcess()
        case .thinking:
            break
        }
    }

    func resetToIdle() {
        mode = .idle
        liveTranscript = ""
        spokenQuery = ""
        restaurants = []
        ttsCurrentText = ""
    }

    // MARK: - Pipeline

    private func startListening() {
        liveTranscript = ""
        speechService.transcribedText = ""

        do {
            try speechService.startListening()
            mode = .listening
        } catch {
            mode = .error("Couldn't start listening: \(error.localizedDescription)")
        }
    }

    private func stopListeningAndProcess() {
        let previousMode = mode
        speechService.stopListening()
        let captured = liveTranscript
        
        guard !captured.isEmpty else {
            mode = previousMode == .results ? .results : .idle
            return
        }
        
        // If we were on the results screen, the speech is a selection (one/two/three)
        if case .results = previousMode {
            handleSelection(from: captured)
            return
        }
        
        // Otherwise it's a new restaurant query — go through the LLM pipeline
        spokenQuery = captured
        mode = .thinking
        
        Task {
            await runPipeline(forText: captured)
        }
    }

    private func handleSelection(from text: String) {
        guard let index = parseSelectionIndex(from: text) else {
            print("⚠️ Couldn't parse selection from: \"\(text)\"")
            mode = .results
            return
        }
        
        guard index < restaurants.count else {
            print("⚠️ Selection \(index + 1) out of range")
            mode = .results
            return
        }
        
        guard let finalDestination = destination?.coordinate else {
            print("⚠️ No destination set, can't build multi-stop route")
            mode = .results
            return
        }
        
        let chosen = restaurants[index]
        print("🎯 User chose #\(index + 1): \(chosen.place.name ?? "?")")
        
        MapsLauncher.openGoogleMaps(
            toRestaurant: chosen.place.coordinate,
            thenDestination: finalDestination,
            restaurantName: chosen.place.name
        )
        
        mode = .results
    }

    private func runPipeline(forText text: String) async {
        // 1. LLM parses voice text into a RestaurantQuery
        let parsed = await llm.parseCommand(text)

        guard let query = parsed else {
            mode = .error("Couldn't understand that. Try again.")
            return
        }

        print("✅ Parsed — cuisine: \(query.cuisine ?? "any"), maxTravel: \(query.maxTravelMinutes ?? -1), price: \(query.priceLevel ?? -1), rush: \(query.rushLevel ?? -1)")
        if let dest = destination {
            print("📍 Routing toward: \(dest.formattedAddress)")
        }

        // 2. Fetch restaurants along the route from user → destination
        guard let origin = locationManager.location?.coordinate else {
            mode = .error("Couldn't get your current location.")
            return
        }
        guard let dest = destination?.coordinate else {
            mode = .error("No destination set.")
            return
        }

        let places = await nearby.fetchRestaurantsAlongRoute(from: origin, to: dest)

        guard !places.isEmpty else {
            mode = .error("No restaurants found nearby.")
            return
        }

        print("🍽️ Found \(places.count) candidates along route")

        // 3. Rank candidates by cuisine, price, rating, and detour
        let ranked = await ranker.rank(
            candidates: places,
            query: query,
            origin: origin,
            destination: dest
        )

        guard !ranked.isEmpty else {
            mode = .error("No restaurants match your preferences.")
            return
        }

        print("🏆 Top results:")
        for (i, r) in ranked.prefix(3).enumerated() {
            print("   \(i+1). \(r.place.name ?? "?") — detour: \(String(format: "%.1f", r.detourMinutes))min, rating: \(r.place.rating), score: \(String(format: "%.2f", r.score))")
        }

        // 4. Take top 3
        let top3 = Array(ranked.prefix(3))
        self.restaurants = top3
        self.topPickIndex = 0
        self.mode = .results

        // 5. Speak the top pick
        speakTopPick()
    }

    private func speakTopPick() {
        guard let top = restaurants.first else { return }
        let name = top.place.name ?? "this place"
        let detour = Int(top.detourMinutes.rounded())
        let line = "Top pick: \(name). \(detour) minutes out of the way. Say one, two, or three."
        ttsCurrentText = line
        speechService.speak(line)
    }
}
