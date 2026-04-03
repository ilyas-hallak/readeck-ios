import SwiftUI
import AVFoundation

struct TTSLanguageSettingsView: View {
    @AppStorage("tts_preferred_language") private var preferredLanguage = "en-US"
    @ObservedObject private var voiceManager = VoiceManager.shared

    private let supportedLanguages: [(code: String, name: String)] = [
        ("de-DE", "Deutsch"),
        ("en-US", "English (US)"),
        ("en-GB", "English (UK)"),
        ("es-ES", "Español"),
        ("fr-FR", "Français"),
        ("it-IT", "Italiano")
    ].sorted { $0.name < $1.name }

    var body: some View {
        List {
            Section {
                ForEach(supportedLanguages, id: \.code) { language in
                    NavigationLink {
                        VoiceListView(languageCode: language.code, languageName: language.name)
                    } label: {
                        HStack {
                            Text(language.name)
                            Spacer()
                            if let voiceId = voiceManager.getSelectedVoiceIdentifier(for: language.code),
                               let voice = voiceManager.availableVoices.first(where: { $0.identifier == voiceId }) {
                                Text(voice.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Auto")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Languages & Voices")
            } footer: {
                Text("Select a voice for each language. Articles are read in their detected language.")
            }

            Section {
                Button {
                    openAccessibilitySettings()
                } label: {
                    HStack {
                        Label("Download Premium Voices", systemImage: "arrow.down.circle")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                Text("Premium voices sound more natural. Download them in iOS Settings > Accessibility > Spoken Content > Voices.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Language & Voices")
        .onAppear {
            voiceManager.refreshVoices()
        }
        .onDisappear {
            voiceManager.stopPreview()
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "App-prefs:ACCESSIBILITY&path=SPOKEN_CONTENT") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    NavigationStack {
        TTSLanguageSettingsView()
    }
}
