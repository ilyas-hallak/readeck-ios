//
//  SettingsContainerView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct SettingsContainerView: View {
    @State private var offlineViewModel = OfflineSettingsViewModel()

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(version) (\(build))"
    }

    var body: some View {
        List {
            AppearanceSettingsView()

            Section {
                Toggle("Enable Offline Reading".localized, isOn: $offlineViewModel.offlineSettings.enabled)
                    .onChange(of: offlineViewModel.offlineSettings.enabled) {
                        Task {
                            await offlineViewModel.saveSettings()
                        }
                    }

                if offlineViewModel.offlineSettings.enabled {
                    Button(action: {
                        Task {
                            await offlineViewModel.syncNow()
                        }
                    }) {
                        HStack {
                            if offlineViewModel.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sync Now".localized)
                                    .foregroundColor(offlineViewModel.isSyncing ? .secondary : .blue)

                                if let progress = offlineViewModel.syncProgress {
                                    Text(progress)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if let lastSync = offlineViewModel.offlineSettings.lastSyncDate {
                                    Text("Last synced: \(lastSync.formatted(.relative(presentation: .named)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }
                    .disabled(offlineViewModel.isSyncing)

                    SettingsRowNavigationLink(
                        icon: "arrow.down.circle.fill",
                        iconColor: .blue,
                        title: "Offline Reading".localized,
                        subtitle: offlineViewModel.cachedArticlesCount > 0 ? String(format: "%lld articles cached".localized, offlineViewModel.cachedArticlesCount) : nil
                    ) {
                        OfflineReadingDetailView()
                    }
                }
            } header: {
                Text("Offline Reading".localized)
            } footer: {
                Text("Automatically download articles for offline use.".localized + " " + "VPN connections are detected as active internet connections.".localized)
            }

            CacheSettingsView()

            ReadingSettingsView()

            SettingsServerView()

            LegalPrivacySettingsView()

            // Debug-only Settings Section
            if !Bundle.main.isProduction {
                debugSettingsSection
            }

            // App Info Section
            appInfoSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await offlineViewModel.loadSettings()
        }
    }

    @ViewBuilder
    private var debugSettingsSection: some View {
        Section {
            SettingsRowNavigationLink(
                icon: "wrench.and.screwdriver.fill",
                iconColor: .orange,
                title: "Debug Menu",
                subtitle: "Network simulation, logging & more"
            ) {
                DebugMenuView()
                    .environmentObject(AppSettings())
            }
        } header: {
            HStack {
                Text("Debug Settings")
                Spacer()
                Text(Bundle.main.isTestFlightBuild ? "TESTFLIGHT" : "DEBUG BUILD")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
        } footer: {
            Text("Debug menu is also accessible via shake gesture")
        }
    }

    @ViewBuilder
    private var appInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Version \(appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "person.crop.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Developer:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Ilyas Hallak") {
                        if let url = URL(string: "https://ilyashallak.de") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                }

                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("From Bremen with 💚")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowBackground(Color.clear)
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
