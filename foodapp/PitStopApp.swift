//
//  PitStopApp.swift
//  PitStop
//

import SwiftUI
import GooglePlaces

@main
struct PitStopApp: App {
    @StateObject private var appState: AppState

    init() {
        // CRITICAL: must run before any GMSPlacesClient call.
        GMSPlacesClient.provideAPIKey(Secrets.googlePlacesAPIKey)

        // Now safe to create AppState (which creates NearbyRestaurants).
        _appState = StateObject(wrappedValue: AppState())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
