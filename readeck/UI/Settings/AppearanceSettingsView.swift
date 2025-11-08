import SwiftUI

struct AppearanceSettingsView: View {
    @State private var selectedCardLayout: CardLayoutStyle = .magazine
    @State private var selectedTheme: Theme = .system
    @State private var selectedTagSortOrder: TagSortOrder = .byCount
    @State private var fontViewModel: FontSettingsViewModel
    @State private var generalViewModel: SettingsGeneralViewModel

    @EnvironmentObject private var appSettings: AppSettings

    private let loadCardLayoutUseCase: PLoadCardLayoutUseCase
    private let saveCardLayoutUseCase: PSaveCardLayoutUseCase
    private let settingsRepository: PSettingsRepository

    init(
        factory: UseCaseFactory = DefaultUseCaseFactory.shared,
        fontViewModel: FontSettingsViewModel = FontSettingsViewModel(),
        generalViewModel: SettingsGeneralViewModel = SettingsGeneralViewModel()
    ) {
        self.loadCardLayoutUseCase = factory.makeLoadCardLayoutUseCase()
        self.saveCardLayoutUseCase = factory.makeSaveCardLayoutUseCase()
        self.settingsRepository = SettingsRepository()
        self.fontViewModel = fontViewModel
        self.generalViewModel = generalViewModel
    }

    var body: some View {
        Group {
            Section {
                // Font Family
                Picker("Font family", selection: $fontViewModel.selectedFontFamily) {
                    ForEach(FontFamily.allCases, id: \.self) { family in
                        Text(family.displayName).tag(family)
                    }
                }
                .onChange(of: fontViewModel.selectedFontFamily) {
                    Task {
                        await fontViewModel.saveFontSettings()
                    }
                }

                // Font Size
                Picker("Font size", selection: $fontViewModel.selectedFontSize) {
                    ForEach(FontSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: fontViewModel.selectedFontSize) {
                    Task {
                        await fontViewModel.saveFontSettings()
                    }
                }

                // Font Preview - direkt in der gleichen Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("readeck Bookmark Title")
                        .font(fontViewModel.previewTitleFont)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text("This is how your bookmark descriptions and article text will appear in the app. The quick brown fox jumps over the lazy dog.")
                        .font(fontViewModel.previewBodyFont)
                        .lineLimit(3)

                    Text("12 min • Today • example.com")
                        .font(fontViewModel.previewCaptionFont)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color(.systemGray6))

                // Theme Picker (Menu statt Segmented)
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .onChange(of: selectedTheme) {
                    saveThemeSettings()
                }

                // Card Layout als NavigationLink
                NavigationLink {
                    CardLayoutSelectionView(
                        selectedCardLayout: $selectedCardLayout,
                        onSave: saveCardLayoutSettings
                    )
                } label: {
                    HStack {
                        Text("Card Layout")
                        Spacer()
                        Text(selectedCardLayout.displayName)
                            .foregroundColor(.secondary)
                    }
                }

                // Open external links in
                Picker("Open links in", selection: $generalViewModel.urlOpener) {
                    ForEach(UrlOpener.allCases, id: \.self) { urlOpener in
                        Text(urlOpener.displayName).tag(urlOpener)
                    }
                }
                .onChange(of: generalViewModel.urlOpener) {
                    Task {
                        await generalViewModel.saveGeneralSettings()
                    }
                }

                // Tag Sort Order
                Picker("Tag sort order", selection: $selectedTagSortOrder) {
                    ForEach(TagSortOrder.allCases, id: \.self) { sortOrder in
                        Text(sortOrder.displayName).tag(sortOrder)
                    }
                }
                .onChange(of: selectedTagSortOrder) {
                    saveTagSortOrderSettings()
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text("Choose where external links should open: In-App Browser keeps you in readeck, Default Browser opens in Safari or your default browser.\n\nTag sort order determines how tags are displayed when adding or editing bookmarks.")
            }
        }
        .task {
            await fontViewModel.loadFontSettings()
            await generalViewModel.loadGeneralSettings()
            loadSettings()
        }
    }

    private func loadSettings() {
        Task {
            // Load theme, card layout, and tag sort order from repository
            if let settings = try? await settingsRepository.loadSettings() {
                await MainActor.run {
                    selectedTheme = settings.theme ?? .system
                    selectedTagSortOrder = settings.tagSortOrder ?? .byCount
                }
            }
            selectedCardLayout = await loadCardLayoutUseCase.execute()
        }
    }

    private func saveThemeSettings() {
        Task {
            // Load current settings, update theme, and save back
            var settings = (try? await settingsRepository.loadSettings()) ?? Settings()
            settings.theme = selectedTheme
            try? await settingsRepository.saveSettings(settings)

            // Notify app about theme change
            await MainActor.run {
                NotificationCenter.default.post(name: .settingsChanged, object: nil)
            }
        }
    }

    private func saveCardLayoutSettings() {
        Task {
            await saveCardLayoutUseCase.execute(layout: selectedCardLayout)
            // Notify other parts of the app about the change
            await MainActor.run {
                NotificationCenter.default.post(name: .cardLayoutChanged, object: selectedCardLayout)
            }
        }
    }

    private func saveTagSortOrderSettings() {
        Task {
            var settings = (try? await settingsRepository.loadSettings()) ?? Settings()
            settings.tagSortOrder = selectedTagSortOrder
            try? await settingsRepository.saveSettings(settings)

            // Update AppSettings to trigger UI updates
            await MainActor.run {
                appSettings.settings?.tagSortOrder = selectedTagSortOrder
                NotificationCenter.default.post(name: .settingsChanged, object: nil)
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            AppearanceSettingsView()
        }
        .listStyle(.insetGrouped)
    }
}
