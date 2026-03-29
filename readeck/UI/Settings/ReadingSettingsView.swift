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
                    Toggle("Read Aloud Feature", isOn: $viewModel.enableTTS)
                        .onChange(of: viewModel.enableTTS) {
                            Task {
                                await viewModel.saveGeneralSettings()
                            }
                        }

                    Text("Activate the Read Aloud Feature to read aloud your articles.")
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
