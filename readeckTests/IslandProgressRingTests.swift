import Testing
@testable import readeck

struct IslandProgressRingTests {
    @Test(arguments: [(0.0, false), (58.0, false), (59.0, true), (62.0, true)])
    func detectsTheIslandFromTheStatusBarHeight(height: Double, expected: Bool) {
        #expect(IslandProgressRing.isAvailable(statusBarHeight: height) == expected)
    }
}
