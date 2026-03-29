//
//  TTSLanguageSettingsView.swift
//  readeck
//
//  Created by Claude on 04.02.26.
//

import SwiftUI

struct TTSLanguageSettingsView: View {
    @AppStorage("tts_preferred_language") private var preferredLanguage: String = "en-US"

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
                    Button {
                        preferredLanguage = language.code
                    } label: {
                        HStack {
                            Text(language.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if preferredLanguage == language.code {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("Preferred Language")
            } footer: {
                Text(
                    "Articles will be read in their detected language. This setting is used as fallback."
                )
            }

            Section {
                Button {
                    openAccessibilitySettings()
                } label: {
                    HStack {
                        Label("Download Extended Voices", systemImage: "arrow.down.circle")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                Text(
                    "Download additional high-quality Siri voices in iOS Settings > Accessibility > Spoken Content > Voices."
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Language & Voices")
        .onAppear {
            VoiceManager.shared.refreshVoices()
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
