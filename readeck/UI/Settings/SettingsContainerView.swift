//
//  SettingsContainerView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct SettingsContainerView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                SettingsServerView()
                    .cardStyle()
                
                FontSettingsView()
                    .cardStyle()
                
                SettingsGeneralView()
                    .cardStyle()
            }
            .padding()
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.large)
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
