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
                FontSettingsView()
                    .cardStyle()
                
                AppearanceSettingsView()
                    .cardStyle()
                
                CacheSettingsView()
                    .cardStyle()
                
                SettingsGeneralView()
                    .cardStyle()
                
                SettingsServerView()
                    .cardStyle()
                
                // Debug-only Logging Configuration
                if Bundle.main.isDebugBuild {
                    debugSettingsSection
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            
            AppInfo()
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    private var debugSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "ant.fill")
                    .foregroundColor(.orange)
                Text("Debug Settings")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("DEBUG BUILD")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
            
            NavigationLink {
                LoggingConfigurationView()
            } label: {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Logging Configuration")
                            .foregroundColor(.primary)
                        Text("Configure log levels and categories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .cardStyle()
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
                HStack(spacing: 4) {
                    Text("Developer:")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Button("Ilyas Hallak") {
                        if let url = URL(string: "https://ilyashallak.de") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                    .underline()
                }
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
