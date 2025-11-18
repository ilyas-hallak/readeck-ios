//
//  OfflineSettingsView.swift
//  readeck
//
//  Created by Claude on 17.11.25.
//

import SwiftUI

struct OfflineSettingsView: View {
    @State private var viewModel = OfflineSettingsViewModel()

    var body: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Offline-Reading aktivieren", isOn: $viewModel.offlineSettings.enabled)
                        .onChange(of: viewModel.offlineSettings.enabled) {
                            Task {
                                await viewModel.saveSettings()
                            }
                        }

                    Text("Lade automatisch Artikel für die Offline-Nutzung herunter.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                if viewModel.offlineSettings.enabled {
                    // Max articles slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Maximale Artikel")
                            Spacer()
                            Text("\(viewModel.offlineSettings.maxUnreadArticlesInt)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: $viewModel.offlineSettings.maxUnreadArticles,
                            in: 0...100,
                            step: 10
                        ) {
                            Text("Max. Artikel offline")
                        }
                        .onChange(of: viewModel.offlineSettings.maxUnreadArticles) {
                            Task {
                                await viewModel.saveSettings()
                            }
                        }
                    }

                    // Save images toggle
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Bilder speichern", isOn: $viewModel.offlineSettings.saveImages)
                            .onChange(of: viewModel.offlineSettings.saveImages) {
                                Task {
                                    await viewModel.saveSettings()
                                }
                            }

                        Text("Lädt auch Bilder für die Offline-Nutzung herunter.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }

                    // Sync button
                    Button(action: {
                        Task {
                            await viewModel.syncNow()
                        }
                    }) {
                        HStack {
                            if viewModel.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Jetzt synchronisieren")
                                    .foregroundColor(viewModel.isSyncing ? .secondary : .blue)

                                if let progress = viewModel.syncProgress {
                                    Text(progress)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if let lastSync = viewModel.offlineSettings.lastSyncDate {
                                    Text("Zuletzt: \(lastSync.formatted(.relative(presentation: .named)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }
                    .disabled(viewModel.isSyncing)

                    // Cache stats
                    if viewModel.cachedArticlesCount > 0 {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gespeicherte Artikel")
                                Text("\(viewModel.cachedArticlesCount) Artikel (\(viewModel.cacheSize))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }

                    #if DEBUG
                    // Debug: Force offline mode
                    Button(action: {
                        simulateOfflineMode()
                    }) {
                        HStack {
                            Image(systemName: "airplane")
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Offline-Modus simulieren")
                                    .foregroundColor(.orange)
                                Text("DEBUG: Netzwerk temporär deaktivieren")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                    #endif
                }
            } header: {
                Text("Offline-Reading")
            }
        }
        .task {
            await viewModel.loadSettings()
        }
    }

    #if DEBUG
    private func simulateOfflineMode() {
        // Post notification to simulate offline mode
        NotificationCenter.default.post(
            name: Notification.Name("SimulateOfflineMode"),
            object: nil
        )
    }
    #endif
}
