import Testing
@testable import readeck

@MainActor
struct FontSettingsViewModelProgressTests {
    @Test func turningProgressOffKeepsTheChosenStyle() async {
        let viewModel = FontSettingsViewModel(factory: TestUseCaseFactory())
        viewModel.readingProgressStyle = .percentTopTrailing

        await viewModel.saveProgressDisplay(nil)

        #expect(viewModel.hideProgressBar)
        #expect(viewModel.readingProgressStyle == .percentTopTrailing)
    }

    @Test func pickingAStyleShowsTheProgressAgain() async {
        let viewModel = FontSettingsViewModel(factory: TestUseCaseFactory())
        viewModel.hideProgressBar = true

        await viewModel.saveProgressDisplay(.islandRing)

        #expect(!viewModel.hideProgressBar)
        #expect(viewModel.readingProgressStyle == .islandRing)
    }
}
