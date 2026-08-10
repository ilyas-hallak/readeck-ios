import Testing
@testable import readeck

@Suite("ArchiveAdvanceMode migration")
struct ArchiveAdvanceModeTests {

    @Test("No settings falls back to advancing to the next article")
    func defaultWhenNoSettings() {
        #expect(AppSettings(settings: nil).archiveAdvanceMode == .nextArticle)
    }

    @Test("Legacy auto-advance ON migrates to next article")
    func legacyTrueMigratesToNext() {
        let settings = Settings(autoAdvanceAfterArchive: true)
        #expect(AppSettings(settings: settings).archiveAdvanceMode == .nextArticle)
    }

    @Test("Legacy auto-advance OFF migrates to stay")
    func legacyFalseMigratesToStay() {
        let settings = Settings(autoAdvanceAfterArchive: false)
        #expect(AppSettings(settings: settings).archiveAdvanceMode == .stay)
    }

    @Test("Explicit mode wins over the legacy boolean")
    func explicitModeWins() {
        let settings = Settings(autoAdvanceAfterArchive: true, archiveAdvanceMode: .returnToList)
        #expect(AppSettings(settings: settings).archiveAdvanceMode == .returnToList)
    }
}
