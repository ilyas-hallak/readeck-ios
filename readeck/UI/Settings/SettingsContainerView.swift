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
        List {
            AppearanceSettingsView()

            CacheSettingsView()

            SettingsGeneralView()

            SettingsServerView()

            LegalPrivacySettingsView()

            // Debug-only Logging Configuration
            #if DEBUG
            if Bundle.main.isDebugBuild {
                debugSettingsSection
            }
            #endif

            // App Info Section
            appInfoSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private var debugSettingsSection: some View {
        Section {
            SettingsRowNavigationLink(
                icon: "doc.text.magnifyingglass",
                iconColor: .blue,
                title: "Logging Configuration",
                subtitle: "Configure log levels and categories"
            ) {
                LoggingConfigurationView()
            }
        } header: {
            HStack {
                Text("Debug Settings")
                Spacer()
                Text("DEBUG BUILD")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var appInfoSection: some View {
        Section {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Version \(appVersion)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(.secondary)
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
            .padding(.vertical, 8)
        }
    }
}

// Card Modifier für einheitlichen Look (kept for backwards compatibility with other views)
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
    NavigationStack {
        SettingsContainerView()
    }
}
