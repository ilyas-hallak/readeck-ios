//
//  OfflineReadingDetailView.swift
//  readeck
//
//  Created by Ilyas Hallak on 17.11.25.
//

import SwiftUI

struct OfflineReadingDetailView: View {
    @State private var viewModel = OfflineSettingsViewModel()
    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Enable Offline Reading".localized, isOn: $viewModel.offlineSettings.enabled)
                        .onChange(of: viewModel.offlineSettings.enabled) {
                            Task {
                                await viewModel.saveSettings()
                            }
                        }

                    Text("Automatically download articles for offline use.".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                if viewModel.offlineSettings.enabled {
                    // Max articles slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Maximum Articles".localized)
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
                            Text("Max. Articles Offline".localized)
                        }
                        .onChange(of: viewModel.offlineSettings.maxUnreadArticles) {
                            Task {
                                await viewModel.saveSettings()
                            }
                        }
                    }

                    // Save images toggle
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Save Images".localized, isOn: $viewModel.offlineSettings.saveImages)
                            .onChange(of: viewModel.offlineSettings.saveImages) {
                                Task {
                                    await viewModel.saveSettings()
                                }
                            }

                        Text("Also download images for offline use.".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
            } header: {
                Text("Settings".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .textCase(nil)
            } footer: {
                Text("VPN connections are detected as active internet connections.".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.offlineSettings.enabled {
                Section {
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
                                Text("Sync Now".localized)
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

                    // Cache stats with preview link
                    if viewModel.cachedArticlesCount > 0 {
                        SettingsRowNavigationLink(
                            icon: "doc.text.magnifyingglass",
                            iconColor: .green,
                            title: "Preview Cached Articles".localized,
                            subtitle: String(format: "%lld articles (%@)".localized, viewModel.cachedArticlesCount, viewModel.cacheSize)
                        ) {
                            CachedArticlesPreviewView()
                        }
                    }
                } header: {
                    Text("Synchronization".localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }

                if Bundle.main.isDebugBuild {
                    Section {
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
                                        Text("Simulate Offline Mode".localized)
                                            .foregroundColor(.orange)
                                        Text("DEBUG: Toggle network status".localized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Debug".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Offline Reading".localized)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSettings()
        }
    }
}
