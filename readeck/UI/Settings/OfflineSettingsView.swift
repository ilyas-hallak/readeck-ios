//
//  OfflineSettingsView.swift
//  readeck
//
//  Created by Claude on 17.11.25.
//

import SwiftUI

struct OfflineSettingsView: View {
    @State private var viewModel = OfflineSettingsViewModel()
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Enable Offline Reading", isOn: $viewModel.offlineSettings.enabled)
                        .onChange(of: viewModel.offlineSettings.enabled) {
                            Task {
                                await viewModel.saveSettings()
                            }
                        }

                    Text("Automatically download articles for offline use.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                if viewModel.offlineSettings.enabled {
                    // Max articles slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Maximum Articles")
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
                            Text("Max. Articles Offline")
                        }
                        .onChange(of: viewModel.offlineSettings.maxUnreadArticles) {
                            Task {
                                await viewModel.saveSettings()
                            }
                        }
                    }

                    // Save images toggle
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Save Images", isOn: $viewModel.offlineSettings.saveImages)
                            .onChange(of: viewModel.offlineSettings.saveImages) {
                                Task {
                                    await viewModel.saveSettings()
                                }
                            }

                        Text("Also download images for offline use.")
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
                                Text("Sync Now")
                                    .foregroundColor(viewModel.isSyncing ? .secondary : .blue)

                                if let progress = viewModel.syncProgress {
                                    Text(progress)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if let lastSync = viewModel.offlineSettings.lastSyncDate {
                                    Text("Last synced: \(lastSync.formatted(.relative(presentation: .named)))")
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
                                Text("Cached Articles")
                                Text("\(viewModel.cachedArticlesCount) articles (\(viewModel.cacheSize))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }

                    #if DEBUG
                    // Debug: Toggle offline mode simulation
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(isOn: Binding(
                            get: { !appSettings.isNetworkConnected },
                            set: { isOffline in
                                appSettings.isNetworkConnected = !isOffline
                            }
                        )) {
                            HStack {
                                Image(systemName: "airplane")
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Simulate Offline Mode")
                                        .foregroundColor(.orange)
                                    Text("DEBUG: Toggle network status")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    #endif
                }
            } header: {
                Text("Offline Reading")
            }
        }
        .task {
            await viewModel.loadSettings()
        }
    }
}
