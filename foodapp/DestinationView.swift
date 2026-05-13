//
//  DestinationView.swift
//  PitStop
//
//  First screen the driver sees. Text field with live Google Places
//  autocomplete suggestions appearing below as they type.
//

import SwiftUI
import GooglePlaces

struct DestinationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var autocomplete = AutocompleteService()

    @State private var typed: String = ""
    @State private var isResolving: Bool = false

    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {

            // Top bar
            HStack {
                Spacer()
                Text("PitStop")
                    .font(.system(size: 22, weight: .semibold))
                    .tracking(-0.5)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer().frame(height: 40)

            // Header
            VStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Color.accentColor)

                Text("Where are you heading?")
                    .font(.system(size: 22, weight: .semibold))
                    .tracking(-0.4)

                Text("We'll find food along the way.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 28)

            // Text field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Enter an address or place", text: $typed)
                    .focused($fieldFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .submitLabel(.search)
                    .onChange(of: typed) { _, newValue in
                        autocomplete.search(newValue)
                    }

                if autocomplete.isSearching {
                    ProgressView().scaleEffect(0.7)
                } else if !typed.isEmpty {
                    Button {
                        typed = ""
                        autocomplete.search("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 24)

            // Suggestions dropdown
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(autocomplete.suggestions.indices, id: \.self) { index in
                        let suggestion = autocomplete.suggestions[index]
                        if let placePrediction = suggestion.placeSuggestion {
                            SuggestionRow(
                                primary: placePrediction.attributedPrimaryText.string,
                                secondary: placePrediction.attributedSecondaryText?.string ?? ""
                            ) {
                                select(suggestion)
                            }
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear { fieldFocused = true }
        .overlay {
            if isResolving {
                ProgressView("Loading…")
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Selection

    private func select(_ suggestion: GMSAutocompleteSuggestion) {
        fieldFocused = false
        isResolving = true

        autocomplete.resolve(suggestion) { resolved in
            isResolving = false
            guard let resolved = resolved else { return }
            appState.confirmDestination(resolved)
        }
    }
}

// MARK: - Suggestion row

private struct SuggestionRow: View {
    let primary: String
    let secondary: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(primary)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if !secondary.isEmpty {
                        Text(secondary)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DestinationView()
        .environmentObject(AppState())
}
