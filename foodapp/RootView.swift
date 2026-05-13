//
//  RootView.swift
//  PitStop
//
//  Top-level router. Shows DestinationView until the driver has confirmed
//  a destination, then swaps to MainView for the rest of the session.
//
//  This file is NEW. In PitStopApp.swift, change `MainView()` to `RootView()`.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if case .askingDestination = appState.mode {
                DestinationView()
                    .transition(.opacity)
            } else {
                MainView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isAskingDestination)
    }

    // Helper so .animation has a simple Equatable to watch
    private var isAskingDestination: Bool {
        if case .askingDestination = appState.mode { return true }
        return false
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
