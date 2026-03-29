import SwiftUI
import AVFoundation

struct TTSLanguageSettingsView: View {
    @AppStorage("tts_preferred_language") private var preferredLanguage: String = "en-US"
    @ObservedObject private var voiceManager = VoiceManager.shared
    @State private var previewingVoiceId: String? = nil

    private let supportedLanguages: [(code: String, name: String)] = [
        ("de-DE", "Deutsch"),
        ("en-US", "English (US)"),
        ("en-GB", "English (UK)"),
        ("es-ES", "Español"),
        ("fr-FR", "Français"),
        ("it-IT", "Italiano"),
        ("pt-PT", "Português"),
        ("nl-NL", "Nederlands"),
        ("pl-PL", "Polski"),
        ("ru-RU", "Русский"),
        ("ja-JP", "日本語"),
        ("zh-CN", "中文"),
        ("ko-KR", "한국어"),
        ("ar-SA", "العربية"),
        ("tr-TR", "Türkçe"),
        ("sv-SE", "Svenska"),
        ("da-DK", "Dansk"),
        ("nb-NO", "Norsk"),
        ("fi-FI", "Suomi"),
        ("cs-CZ", "Čeština"),
        ("hu-HU", "Magyar"),
        ("ro-RO", "Română"),
        ("sk-SK", "Slovenčina"),
        ("uk-UA", "Українська"),
        ("el-GR", "Ελληνικά"),
        ("he-IL", "עברית"),
        ("hi-IN", "हिन्दी"),
        ("th-TH", "ไทย"),
        ("id-ID", "Bahasa Indonesia"),
        ("vi-VN", "Tiếng Việt"),
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

// MARK: - Voice List for a specific language

struct VoiceListView: View {
    let languageCode: String
    let languageName: String
    @ObservedObject private var voiceManager = VoiceManager.shared
    @State private var previewingVoiceId: String? = nil

    private var voicesByQuality: [(quality: String, voices: [AVSpeechSynthesisVoice])] {
        let voices = voiceManager.getAvailableVoices(for: languageCode)
        var groups: [(String, [AVSpeechSynthesisVoice])] = []

        let premium = voices.filter { $0.quality == .premium }
        let enhanced = voices.filter { $0.quality == .enhanced }
        let standard = voices.filter { $0.quality == .default }

        if !premium.isEmpty { groups.append(("Premium", premium)) }
        if !enhanced.isEmpty { groups.append(("Enhanced", enhanced)) }
        if !standard.isEmpty { groups.append(("Default", standard)) }

        return groups
    }

    private var selectedVoiceId: String? {
        voiceManager.getSelectedVoiceIdentifier(for: languageCode)
    }

    var body: some View {
        List {
            // Auto option
            Section {
                Button {
                    voiceManager.clearPerLanguageVoice(for: languageCode)
                } label: {
                    HStack {
                        Text("Automatic (best available)")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedVoiceId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }

            ForEach(voicesByQuality, id: \.quality) { group in
                Section(group.quality) {
                    ForEach(group.voices, id: \.identifier) { voice in
                        Button {
                            voiceManager.setVoice(voice, for: languageCode)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(voice.name)
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                                if selectedVoiceId == voice.identifier {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                                // Preview button
                                Button {
                                    if previewingVoiceId == voice.identifier {
                                        voiceManager.stopPreview()
                                        previewingVoiceId = nil
                                    } else {
                                        let sampleText = sampleSentence(for: languageCode, voiceName: voice.name)
                                        voiceManager.previewVoice(voice, sampleText: sampleText)
                                        previewingVoiceId = voice.identifier
                                    }
                                } label: {
                                    Image(systemName: previewingVoiceId == voice.identifier ? "stop.circle.fill" : "play.circle")
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(languageName)
        .onDisappear {
            voiceManager.stopPreview()
            previewingVoiceId = nil
        }
    }

    private func sampleSentence(for language: String, voiceName: String) -> String {
        switch language.prefix(2) {
        case "de": return "Hallo, ich bin \(voiceName). So werde ich deine Artikel vorlesen."
        case "en": return "Hi, I'm \(voiceName). This is how I'll read your articles."
        case "es": return "Hola, soy \(voiceName). Así leeré tus artículos."
        case "fr": return "Bonjour, je suis \(voiceName). Voici comment je lirai vos articles."
        case "it": return "Ciao, sono \(voiceName). Ecco come leggerò i tuoi articoli."
        default: return "Hello, I'm \(voiceName). This is how I'll read your articles."
        }
    }
}

#Preview {
    NavigationStack {
        TTSLanguageSettingsView()
    }
}
