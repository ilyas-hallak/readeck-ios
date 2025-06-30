//
//  SettingsContainerView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct SettingsContainerView: View {
    @State private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Server-Card immer anzeigen
                    SettingsServerView(viewModel: viewModel)
                        .cardStyle()
                    
                    // Allgemeine Einstellungen nur im normalen Modus anzeigen
                    if !viewModel.isSetupMode {
                        SettingsGeneralView(viewModel: viewModel)
                            .cardStyle()
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadSettings()
        }
    }
}

// Card Modifier für einheitlichen Look
extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    SettingsContainerView()
} 
