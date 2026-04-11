import XCTest
@testable import readeck

final class ScrollTrackerTests: XCTestCase {

    // MARK: - Reading Progress

    func testProgressCalculation() {
        var tracker = ScrollTracker()

        // First call sets initialContentEndPosition and returns progress 0
        let r1 = tracker.update(endPosition: 8000, containerHeight: 700)
        XCTAssertEqual(r1.readingProgress ?? -1, 0, accuracy: 0.01)

        // Second call at same position — still progress 0
        let r2 = tracker.update(endPosition: 8000, containerHeight: 700)
        XCTAssertEqual(r2.readingProgress ?? -1, 0, accuracy: 0.01)
    }

    func testProgressAt50Percent() {
        var tracker = ScrollTracker()

        // Initialize: content end at 1700, container 700 → scrollable distance = 1000
        _ = tracker.update(endPosition: 1700, containerHeight: 700)
        // Scroll to 50%: endPosition drops by 500
        let result = tracker.update(endPosition: 1200, containerHeight: 700)
        XCTAssertEqual(result.readingProgress ?? -1, 0.5, accuracy: 0.01)
    }

    func testProgressAt100Percent() {
        var tracker = ScrollTracker()

        // Initialize: scrollable distance = 1000
        _ = tracker.update(endPosition: 1700, containerHeight: 700)
        // Scroll to bottom
        let result = tracker.update(endPosition: 700, containerHeight: 700)
        XCTAssertEqual(result.readingProgress ?? -1, 1.0, accuracy: 0.01)
    }

    func testProgressLocksAt100() {
        var tracker = ScrollTracker()

        _ = tracker.update(endPosition: 1700, containerHeight: 700)

        // Reach 100%
        let r1 = tracker.update(endPosition: 700, containerHeight: 700)
        XCTAssertEqual(r1.readingProgress ?? -1, 1.0, accuracy: 0.01)
        XCTAssertTrue(r1.shouldUpdateProgress)

        // Scroll back slightly — should stay locked at 1.0
        let r2 = tracker.update(endPosition: 705, containerHeight: 700)
        XCTAssertEqual(r2.readingProgress ?? -1, 1.0, accuracy: 0.01)
    }

    func testShouldUpdateProgress() {
        var tracker = ScrollTracker()

        _ = tracker.update(endPosition: 1700, containerHeight: 700)

        // Small scroll — not enough to trigger update (< 3% threshold)
        let r1 = tracker.update(endPosition: 1690, containerHeight: 700)
        XCTAssertFalse(r1.shouldUpdateProgress)

        // Larger scroll — triggers update
        let r2 = tracker.update(endPosition: 1600, containerHeight: 700)
        XCTAssertTrue(r2.shouldUpdateProgress)
    }

    func testShortContentAlwaysShowsToolbar() {
        var tracker = ScrollTracker()
        tracker = ScrollTracker()

        // Content shorter than container
        let result = tracker.update(endPosition: 500, containerHeight: 700)
        // initialContentEndPosition won't be set (500 < 700 * 1.2)
        XCTAssertNil(result.readingProgress)
    }

    // MARK: - Toolbar Visibility

    func testToolbarStartsVisible() {
        let tracker = ScrollTracker()
        XCTAssertTrue(tracker.toolbarVisible)
    }

    func testToolbarHidesOnScrollDown() {
        var tracker = ScrollTracker()

        // Initialize
        _ = tracker.update(endPosition: 8000, containerHeight: 700)
        // Scroll down past "near top" zone — hides toolbar on this call
        let result = tracker.update(endPosition: 7500, containerHeight: 700)

        XCTAssertEqual(result.isToolbarVisible, false)
        XCTAssertFalse(tracker.toolbarVisible)
    }

    func testToolbarShowsAfterScrollUpThreshold() {
        var tracker = ScrollTracker()
        tracker.scrollUpThresholdRatio = 0.12

        // Initialize with container = 700 → threshold = 84
        _ = tracker.update(endPosition: 8000, containerHeight: 700)
        // Scroll down to hide toolbar
        _ = tracker.update(endPosition: 7500, containerHeight: 700)
        _ = tracker.update(endPosition: 7000, containerHeight: 700)
        XCTAssertFalse(tracker.toolbarVisible)

        // Scroll up but below threshold
        let r1 = tracker.update(endPosition: 7050, containerHeight: 700)
        XCTAssertNil(r1.isToolbarVisible, "Should not change — below threshold")
        XCTAssertFalse(tracker.toolbarVisible)

        // Scroll up past threshold (cumulative 50 + 50 = 100 > 84)
        let r2 = tracker.update(endPosition: 7100, containerHeight: 700)
        XCTAssertEqual(r2.isToolbarVisible, true)
        XCTAssertTrue(tracker.toolbarVisible)
    }

    func testToolbarSmallScrollUpDoesNotShow() {
        var tracker = ScrollTracker()
        tracker.scrollUpThresholdRatio = 0.12

        _ = tracker.update(endPosition: 8000, containerHeight: 700)
        _ = tracker.update(endPosition: 7500, containerHeight: 700)
        _ = tracker.update(endPosition: 7000, containerHeight: 700)
        XCTAssertFalse(tracker.toolbarVisible)

        // Small scroll up (10pt < 84pt threshold)
        let result = tracker.update(endPosition: 7010, containerHeight: 700)
        XCTAssertNil(result.isToolbarVisible)
        XCTAssertFalse(tracker.toolbarVisible)
    }

    func testToolbarShowsAtTop() {
        var tracker = ScrollTracker()

        _ = tracker.update(endPosition: 8000, containerHeight: 700)
        // Scroll down to hide
        _ = tracker.update(endPosition: 7500, containerHeight: 700)
        _ = tracker.update(endPosition: 7000, containerHeight: 700)
        XCTAssertFalse(tracker.toolbarVisible)

        // Scroll back to top (progress ≤ 0.01)
        let result = tracker.update(endPosition: 7990, containerHeight: 700)
        XCTAssertEqual(result.isToolbarVisible, true)
    }

    func testAccumulatedScrollUpResetsOnDirectionChange() {
        var tracker = ScrollTracker()
        tracker.scrollUpThresholdRatio = 0.12

        _ = tracker.update(endPosition: 8000, containerHeight: 700)
        _ = tracker.update(endPosition: 7500, containerHeight: 700)
        _ = tracker.update(endPosition: 7000, containerHeight: 700)
        XCTAssertFalse(tracker.toolbarVisible)

        // Scroll up partially
        _ = tracker.update(endPosition: 7050, containerHeight: 700)
        XCTAssertEqual(tracker.accumulatedScrollUp, 50, accuracy: 1)

        // Scroll down — should reset accumulator
        _ = tracker.update(endPosition: 7000, containerHeight: 700)
        XCTAssertEqual(tracker.accumulatedScrollUp, 0, accuracy: 1)
    }

    // MARK: - Container Height Changes

    func testContainerHeightChangeSkipsUpdate() {
        var tracker = ScrollTracker()

        _ = tracker.update(endPosition: 8000, containerHeight: 700)
        _ = tracker.update(endPosition: 7500, containerHeight: 700)

        // Container height changes (toolbar toggle: 700 → 754)
        let result = tracker.update(endPosition: 7450, containerHeight: 754)
        XCTAssertNil(result.readingProgress, "Should skip when container changes")
        XCTAssertNil(result.isToolbarVisible, "Should skip when container changes")
    }

    func testContainerHeightChangeDoesNotInflateInitialPosition() {
        var tracker = ScrollTracker()

        _ = tracker.update(endPosition: 8000, containerHeight: 700)
        let initialBefore = tracker.initialContentEndPosition

        // Container changes — endPosition jumps up
        _ = tracker.update(endPosition: 8100, containerHeight: 754)

        XCTAssertEqual(tracker.initialContentEndPosition, initialBefore,
                       "initialContentEndPosition should not grow from container changes")
    }

    func testResumeNormallyAfterContainerChange() {
        var tracker = ScrollTracker()

        _ = tracker.update(endPosition: 8000, containerHeight: 700)
        _ = tracker.update(endPosition: 7500, containerHeight: 700)

        // Container change — skipped
        _ = tracker.update(endPosition: 7450, containerHeight: 754)

        // Normal scroll continues
        let result = tracker.update(endPosition: 7400, containerHeight: 754)
        XCTAssertNotNil(result.readingProgress, "Should resume tracking after container settles")
    }
}
