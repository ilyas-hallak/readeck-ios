import Testing
@testable import readeck

@MainActor
struct FontSettingsViewModelProgressTests {
    private let factory = TestUseCaseFactory()

    @Test func turningProgressOffOnlySavesTheVisibility() async {
        let viewModel = FontSettingsViewModel(factory: factory)
        viewModel.readingProgressStyle = .percentTopTrailing

        await viewModel.saveProgressDisplay(nil)

        #expect(viewModel.hideProgressBar)
        #expect(viewModel.readingProgressStyle == .percentTopTrailing)
        #expect(factory.mockSaveSettings.savedHideProgressBar == [true])
        #expect(factory.mockSaveSettings.savedReadingProgressStyles.isEmpty)
    }

    @Test func pickingAStyleSavesItAndShowsTheProgressAgain() async {
        let viewModel = FontSettingsViewModel(factory: factory)
        viewModel.hideProgressBar = true

        await viewModel.saveProgressDisplay(.islandRing)

        #expect(!viewModel.hideProgressBar)
        #expect(viewModel.readingProgressStyle == .islandRing)
        #expect(factory.mockSaveSettings.savedReadingProgressStyles == [.islandRing])
        #expect(factory.mockSaveSettings.savedHideProgressBar == [false])
    }

    @Test func pickingTheCurrentStyleSavesNothing() async {
        let viewModel = FontSettingsViewModel(factory: factory)

        await viewModel.saveProgressDisplay(.line)

        #expect(factory.mockSaveSettings.savedReadingProgressStyles.isEmpty)
        #expect(factory.mockSaveSettings.savedHideProgressBar.isEmpty)
    }
}
