//
//  FontDebugView.swift
//  readeck
//
//  Created by Ilyas Hallak on 05.12.25.
//

import SwiftUI
import UIKit

#if DEBUG
struct FontDebugView: View {
    @State private var availableFonts: [String: [String]] = [:]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("This view shows all available font families and their font names. Use this to verify that custom fonts are loaded correctly.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Debug Info")
                }

                ForEach(availableFonts.keys.sorted(), id: \.self) { family in
                    Section {
                        ForEach(availableFonts[family] ?? [], id: \.self) { fontName in
                            Text(fontName)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                    } header: {
                        Text(family)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Available Fonts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Refresh") {
                        loadFonts()
                    }
                }
            }
            .onAppear {
                loadFonts()
            }
        }
    }

    private func loadFonts() {
        var fonts: [String: [String]] = [:]

        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            if !names.isEmpty {
                fonts[family] = names
            }
        }

        availableFonts = fonts
    }
}

#Preview {
    FontDebugView()
}
#endif
