//
//  MainView.swift
//  PitStop
//
//  Home/listening screen. Three-part top bar (prefs / logo / settings)
//  with a big mic button in the center.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPreferences = false
    @State private var showSettings = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar
                Spacer()
                centerArea
                Spacer()
                footerHint
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationDestination(isPresented: bindingForResults) {
                ResultsView()
            }
            .sheet(isPresented: $showPreferences) {
                PreferencesView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // Push to ResultsView whenever mode becomes .results
    private var bindingForResults: Binding<Bool> {
        Binding(
            get: {
                switch appState.mode {
                case .results, .listening:
                    // Stay on ResultsView while listening for a selection
                    return !appState.restaurants.isEmpty
                default:
                    return false
                }
            },
            set: { newValue in
                if !newValue {
                    appState.resetToIdle()
                }
            }
        )
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .center) {
            Button {
                showPreferences = true
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
     
            Spacer()
     
            // CHANGED: logo + locked destination stacked vertically
            VStack(spacing: 2) {
                Text("PitStop")
                    .font(.system(size: 22, weight: .semibold))
                    .tracking(-0.5)
     
                if let dest = appState.destination {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                        Text(dest.primaryText)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 220)
                }
            }
     
            Spacer()
     
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .opacity(isListening ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: isListening)
    }

    // MARK: - Center

    private var centerArea: some View {
        VStack(spacing: 28) {
            Text(promptText)
                .font(.system(size: 14))
                .foregroundStyle(isListening ? Color.accentColor : .secondary)
                .fontWeight(isListening ? .medium : .regular)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
                .animation(.easeInOut(duration: 0.2), value: isListening)

            micButton

            // Live transcript or "Start"
            Group {
                if isListening {
                    Text(appState.liveTranscript.isEmpty ? "..." : "\u{201C}\(appState.liveTranscript)\u{201D}")
                        .font(.system(size: 16))
                        .italic()
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280, minHeight: 44)
                        .padding(.horizontal, 24)
                } else if isThinking {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Finding spots near you")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .frame(minHeight: 44)
                } else {
                    Text("Start")
                        .font(.system(size: 24, weight: .medium))
                        .tracking(-0.4)
                        .frame(minHeight: 44)
                }
            }
            .transition(.opacity)
        }
    }

    private var promptText: String {
        switch appState.mode {
        case .askingDestination: return ""
        case .idle:        return "Tap and tell me what you're hungry for"
        case .listening:   return "Listening..."
        case .thinking:    return "One sec..."
        case .results:     return ""
        case .error(let msg): return msg
        }
    }

    // MARK: - Mic button

    private var micButton: some View {
        ZStack {
            // Outer ring (idle)
            if !isListening {
                Circle()
                    .stroke(Color(.separator), lineWidth: 0.5)
                    .frame(width: 200, height: 200)
                Circle()
                    .stroke(Color(.separator), lineWidth: 0.5)
                    .frame(width: 168, height: 168)
            }

            // Pulsing rings while listening
            if isListening {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulseScale)
                Circle()
                    .fill(Color.accentColor.opacity(0.25))
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.2), value: pulseScale)
            }

            // Main button
            Button {
                appState.micTapped()
            } label: {
                ZStack {
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 140, height: 140)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48, weight: .regular))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(isThinking)
        }
        .frame(width: 220, height: 220)
        .onChange(of: isListening) { _, listening in
            pulseScale = listening ? 1.08 : 1.0
        }
    }

    private var buttonColor: Color {
        switch appState.mode {
        case .listening: return Color.accentColor
        case .thinking:  return Color.gray
        default:         return Color(red: 0.09, green: 0.37, blue: 0.65) // Deep blue
        }
    }

    // MARK: - Footer

    private var footerHint: some View {
        Text(footerText)
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .padding(.bottom, 24)
    }

    private var footerText: String {
        if isListening { return "Tap again to stop" }
        return "Driving \u{00B7} location active"
    }

    // MARK: - Helpers

    private var isListening: Bool {
        if case .listening = appState.mode { return true }
        return false
    }

    private var isThinking: Bool {
        if case .thinking = appState.mode { return true }
        return false
    }
}

// MARK: - Placeholder sheets

struct PreferencesView: View {
    var body: some View {
        NavigationStack {
            Text("Restaurant preferences go here")
                .navigationTitle("Preferences")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Settings go here")
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
}
