import Testing
@testable import readeck

@Suite("Font size persistence")
struct FontSizePersistenceTests {

    @Test("Saving font settings persists the font size enum alongside the numeric value")
    func savesFontSizeEnumAndNumeric() async throws {
        let repository = RecordingSettingsRepository()
        let useCase = SaveSettingsUseCase(settingsRepository: repository)

        try await useCase.execute(
            selectedFontFamily: .system,
            selectedFontSize: .large,
            fontSizeNumeric: Double(FontSize.large.size)
        )

        let saved = try #require(repository.savedSettings.last)
        #expect(saved.fontSize == .large)
        #expect(saved.fontSizeNumeric == Double(FontSize.large.size))
        #expect(saved.fontFamily == .system)
    }

    @Test("A custom numeric size still persists the matching enum case")
    func savesCustomFontSize() async throws {
        let repository = RecordingSettingsRepository()
        let useCase = SaveSettingsUseCase(settingsRepository: repository)

        try await useCase.execute(
            selectedFontFamily: .literata,
            selectedFontSize: .custom,
            fontSizeNumeric: 23
        )

        let saved = try #require(repository.savedSettings.last)
        #expect(saved.fontSize == .custom)
        #expect(saved.fontSizeNumeric == 23)
    }
}
