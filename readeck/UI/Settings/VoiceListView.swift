import SwiftUI
import AVFoundation

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
                Section {
                    ForEach(group.voices, id: \.identifier) { voice in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(voice.name)
                            }
                            Spacer()
                            if selectedVoiceId == voice.identifier {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
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
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            voiceManager.setVoice(voice, for: languageCode)
                        }
                    }
                } header: {
                    Text(group.quality)
                } footer: {
                    Text(qualityDescription(for: group.quality))
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

    private func qualityDescription(for quality: String) -> String {
        switch quality {
        case "Premium":
            return String(localized: "Highest quality — most natural sounding. Requires download in iOS Settings.")
        case "Enhanced":
            return String(localized: "Good quality with natural intonation. Requires download in iOS Settings.")
        default:
            return String(localized: "Built-in voice. No download required.")
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
