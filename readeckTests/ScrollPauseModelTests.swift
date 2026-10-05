import Testing
@testable import readeck

@MainActor
struct ScrollPauseModelTests {
    @Test func pausesWhenScrollingComesToRest() {
        let pause = ScrollPauseModel()

        pause.scrollPhaseChanged(isIdle: true)

        #expect(pause.isPaused)
    }

    @Test func scrollingAgainEndsThePause() {
        let pause = ScrollPauseModel()
        pause.scrollPhaseChanged(isIdle: true)

        pause.scrollPhaseChanged(isIdle: false)

        #expect(!pause.isPaused)
    }

    @Test func pauseEndsAfterTheHoldTime() async throws {
        let pause = ScrollPauseModel()

        pause.scrollPhaseChanged(isIdle: true, holdFor: .milliseconds(10))
        try await Task.sleep(for: .milliseconds(300))

        #expect(!pause.isPaused)
    }
}
