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
                // Font Settings als NavigationLink
                NavigationLink {
                    FontSelectionView(viewModel: fontViewModel)
                } label: {
                    HStack {
                        Text("Font")
                        Spacer()
                        Text("\(fontViewModel.selectedFontFamily.displayName) · \(fontViewModel.selectedFontSize.displayName)")
                            .foregroundColor(.secondary)
                    }
                }

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
                VStack(alignment: .leading, spacing: 4) {
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

                    Text("Choose where external links should open: In-App Browser keeps you in readeck, Default Browser opens in Safari or your default browser.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                // Tag Sort Order
                VStack(alignment: .leading, spacing: 4) {
                    Picker("Tag sort order", selection: $selectedTagSortOrder) {
                        ForEach(TagSortOrder.allCases, id: \.self) { sortOrder in
                            Text(sortOrder.displayName).tag(sortOrder)
                        }
                    }
                    .onChange(of: selectedTagSortOrder) {
                        saveTagSortOrderSettings()
                    }

                    Text("Determines how tags are displayed when adding or editing bookmarks.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            } header: {
                Text("Appearance")
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
