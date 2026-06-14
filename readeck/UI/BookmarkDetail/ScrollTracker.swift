import Foundation

/// Tracks scroll position to calculate reading progress and toolbar visibility.
/// Pure logic — no SwiftUI dependency, fully testable.
struct ScrollTracker {

    struct Result {
        let readingProgress: Double?
        let shouldUpdateProgress: Bool
        let isToolbarVisible: Bool?
    }

    // MARK: - Configuration

    var scrollUpThresholdRatio: CGFloat = 0.12
    var scrollDownThresholdRatio: CGFloat = 0.06

    // MARK: - State

    private(set) var initialContentEndPosition: CGFloat = 0
    private(set) var previousEndPosition: CGFloat?
    private(set) var previousContainerHeight: CGFloat = 0
    private(set) var accumulatedScrollUp: CGFloat = 0
    private(set) var accumulatedScrollDown: CGFloat = 0
    private(set) var lastSentProgress: Double = 0
    private(set) var toolbarVisible: Bool = true

    // MARK: - Logic

    mutating func update(endPosition: CGFloat, containerHeight: CGFloat) -> Result {
        // Detect container height change (toolbar show/hide) — skip first call
        let containerChanged = previousContainerHeight > 0 && abs(containerHeight - previousContainerHeight) > 1
        if containerChanged {
            previousContainerHeight = containerHeight
            previousEndPosition = endPosition
            return Result(readingProgress: nil, shouldUpdateProgress: false, isToolbarVisible: nil)
        }
        previousContainerHeight = containerHeight

        // Update initial position if content grows (WebView still loading)
        if endPosition > initialContentEndPosition && endPosition > containerHeight * 1.2 {
            initialContentEndPosition = endPosition
        }

        guard initialContentEndPosition > 0 else {
            return Result(readingProgress: nil, shouldUpdateProgress: false, isToolbarVisible: nil)
        }

        let totalScrollableDistance = initialContentEndPosition - containerHeight

        // Don't collapse toolbar for short articles (less than 1.5x screen height of scrollable content)
        let minScrollDistance = containerHeight * 1.5
        guard totalScrollableDistance > minScrollDistance else {
            toolbarVisible = true
            return Result(readingProgress: 0, shouldUpdateProgress: false, isToolbarVisible: true)
        }

        // Calculate progress
        let scrolled = initialContentEndPosition - endPosition
        let rawProgress = scrolled / totalScrollableDistance
        var progress = min(max(rawProgress, 0), 1)

        if lastSentProgress >= 0.995 {
            progress = max(progress, 1.0)
        }

        let progressThreshold = 0.03
        let reachedEnd = progress >= 1.0 && lastSentProgress < 1.0
        let shouldUpdate = abs(progress - lastSentProgress) >= progressThreshold || reachedEnd

        if shouldUpdate {
            lastSentProgress = progress
        }

        // Toolbar visibility
        let toolbarChange = updateToolbar(endPosition: endPosition, progress: progress, containerHeight: containerHeight)

        return Result(readingProgress: progress, shouldUpdateProgress: shouldUpdate, isToolbarVisible: toolbarChange)
    }

    // MARK: - Private

    private mutating func updateToolbar(endPosition: CGFloat, progress: Double, containerHeight: CGFloat) -> Bool? {
        guard let prev = previousEndPosition else {
            previousEndPosition = endPosition
            return nil
        }
        let delta = endPosition - prev
        previousEndPosition = endPosition

        // Always show toolbar near top — also prevents hide from scroll bounce
        if progress <= 0.05 {
            accumulatedScrollUp = 0
            if !toolbarVisible {
                toolbarVisible = true
                return true
            }
            return nil
        }

        guard containerHeight > 0 else { return nil }

        if delta < -1 {
            // Scrolling down — require a minimum distance before hiding
            accumulatedScrollDown += abs(delta)
            accumulatedScrollUp = 0
            let hideThreshold = containerHeight * scrollDownThresholdRatio
            if accumulatedScrollDown >= hideThreshold && toolbarVisible {
                toolbarVisible = false
                accumulatedScrollDown = 0
                return false
            }
        } else if delta > 1 {
            // Scrolling up
            accumulatedScrollDown = 0
            accumulatedScrollUp += delta
            let threshold = containerHeight * scrollUpThresholdRatio
            if accumulatedScrollUp >= threshold && !toolbarVisible {
                toolbarVisible = true
                accumulatedScrollUp = 0
                return true
            }
        }

        return nil
    }
}
