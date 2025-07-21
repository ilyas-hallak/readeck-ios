//
//  SettingsContainerView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct SettingsContainerView: View {
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(version) (\(build))"
    }
    
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
            
            AppInfo()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    func AppInfo() -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Version \(appVersion)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 8) {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.secondary)
                Text("Developer: Ilyas Hallak")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .foregroundColor(.secondary)
                Text("From Bremen with 💚")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .multilineTextAlignment(.center)
        .opacity(0.7)
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
