//
//  SettingsGeneralView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct SettingsGeneralView: View {
    @State private var viewModel: SettingsGeneralViewModel
    @State private var showReleaseNotes = false

    init(viewModel: SettingsGeneralViewModel = SettingsGeneralViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            Section {
                Button(action: {
                    showReleaseNotes = true
                }) {
                    HStack {
                        Label("What's New", systemImage: "sparkles")
                        Spacer()
                        Text("Version \(VersionManager.shared.currentVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Toggle("Read Aloud Feature", isOn: $viewModel.enableTTS)
                    .onChange(of: viewModel.enableTTS) {
                        Task {
                            await viewModel.saveGeneralSettings()
                        }
                    }
            } header: {
                Text("General")
            } footer: {
                Text("Activate the Read Aloud Feature to read aloud your articles. This is a really early preview and might not work perfectly.")
            }

            #if DEBUG
            Section {
                Toggle("Automatic sync", isOn: $viewModel.autoSyncEnabled)
                if viewModel.autoSyncEnabled {
                    Stepper("Sync interval: \(viewModel.syncInterval) minutes", value: $viewModel.syncInterval, in: 1...60)
                }
            } header: {
                Text("Sync Settings")
            }

            Section {
                Toggle("Safari Reader Mode", isOn: $viewModel.enableReaderMode)
                Toggle("Automatically mark articles as read", isOn: $viewModel.autoMarkAsRead)
            } header: {
                Text("Reading Settings")
            }

            if let successMessage = viewModel.successMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(successMessage)
                            .foregroundColor(.green)
                    }
                }
            }
            if let errorMessage = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            #endif
        }
        .sheet(isPresented: $showReleaseNotes) {
            ReleaseNotesView()
        }
        .task {
            await viewModel.loadGeneralSettings()
        }
    }
}

#Preview {
    List {
        SettingsGeneralView(viewModel: .init(
            MockUseCaseFactory()
        ))
    }
    .listStyle(.insetGrouped)
}
