//
//  ReadingSettingsView.swift
//  readeck
//
//  Created by Ilyas Hallak on 08.11.25.
//

import SwiftUI

struct ReadingSettingsView: View {
    @State private var viewModel: SettingsGeneralViewModel

    init(viewModel: SettingsGeneralViewModel = SettingsGeneralViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Listen to Article", isOn: $viewModel.enableTTS)
                        .onChange(of: viewModel.enableTTS) {
                            guard !viewModel.isLoading else { return }
                            Task {
                                await viewModel.saveGeneralSettings()
                            }
                        }

                    Text("Activate Listen to Article to have your articles read to you. This feature is currently in beta — you may encounter occasional issues.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                if viewModel.enableTTS {
                    NavigationLink {
                        TTSLanguageSettingsView()
                    } label: {
                        HStack {
                            Label("Language & Voices", systemImage: "waveform")
                            Spacer()
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Disable Back Swipe in Reader", isOn: $viewModel.disableReaderBackSwipe)
                        .onChange(of: viewModel.disableReaderBackSwipe) {
                            guard !viewModel.isLoading else { return }
                            Task {
                                await viewModel.saveGeneralSettings()
                            }
                        }

                    Text("Disables the edge swipe gesture to go back in the article reader. This makes it easier to select and highlight text near the screen edges.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Picker("After Archiving", selection: $viewModel.archiveAdvanceMode) {
                        ForEach(ArchiveAdvanceMode.allCases) { mode in
                            Text(mode.localizedTitle).tag(mode)
                        }
                    }
                    .onChange(of: viewModel.archiveAdvanceMode) {
                        guard !viewModel.isLoading else { return }
                        Task {
                            await viewModel.saveGeneralSettings()
                        }
                    }

                    Text("Choose what happens when you archive or delete the article you're reading: stay on it, open the next one in your list, or return to the list.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Show Unread Count on App Icon", isOn: $viewModel.showUnreadBadge)
                        .onChange(of: viewModel.showUnreadBadge) {
                            guard !viewModel.isLoading else { return }
                            Task {
                                await viewModel.updateUnreadBadge()
                            }
                        }

                    Text("Shows the number of unread articles as a badge on the app icon. Updates when you open the app or archive an article.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            } header: {
                Text("Reading Settings")
            }
        }
        .task {
            await viewModel.loadGeneralSettings()
        }
    }
}

#Preview {
    List {
        ReadingSettingsView(viewModel: .init(
            MockUseCaseFactory()
        ))
    }
    .listStyle(.insetGrouped)
}
