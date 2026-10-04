import SwiftUI

/// The reading progress in the top chrome of the reader, in the style the user picked.
@available(iOS 26.0, *)
struct ReadingProgressOverlay: View {
    let style: ReadingProgressStyle
    let model: ReadingProgressModel
    let isToolbarVisible: Bool
    /// True for a moment after scrolling stopped, the styles that pop up use it.
    let isScrollPaused: Bool
    let topBarInset: Double
    let statusBarHeight: Double

    var body: some View {
        ZStack(alignment: .top) {
            indicator
        }
        .animation(.easeInOut(duration: 0.3), value: isScrollPaused)
    }

    // Devices without a Dynamic Island fall back to the line
    private var resolvedStyle: ReadingProgressStyle {
        guard style.requiresDynamicIsland,
              !IslandProgressRing.isAvailable(statusBarHeight: statusBarHeight) else { return style }
        return .line
    }

    private var isPopUpShown: Bool {
        !isToolbarVisible && isScrollPaused
    }

    @ViewBuilder
    private var indicator: some View {
        switch resolvedStyle {
        case .line:
            ReadingProgressBar(model: model)
                .offset(y: isToolbarVisible ? topBarInset : statusBarHeight)
        case .islandRing, .islandRingOnStop:
            let isShown = resolvedStyle == .islandRing ? !isToolbarVisible : isPopUpShown
            IslandProgressRing(model: model, isShown: isShown)
                .opacity(isShown ? 1 : 0)
        case .percentTopTrailing:
            ProgressPill(model: model)
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(y: statusBarHeight + 8)
                .opacity(isPopUpShown ? 1 : 0)
                .scaleEffect(isPopUpShown ? 1 : 0.8, anchor: .trailing)
        case .percentAtScrollIndicator:
            ProgressPillAtScrollIndicator(model: model, top: statusBarHeight + 8)
                .opacity(isPopUpShown ? 1 : 0)
                .offset(x: isPopUpShown ? 0 : 20)
        }
    }
}

/// The reading progress in percent.
@available(iOS 26.0, *)
struct ProgressPill: View {
    let model: ReadingProgressModel

    var body: some View {
        Text(model.value, format: .percent.precision(.fractionLength(0)))
            .font(.footnote.weight(.semibold).monospacedDigit())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .glassEffect(.regular, in: .capsule)
    }
}

/// Places the pill next to the scroll indicator, which moves with the progress.
@available(iOS 26.0, *)
struct ProgressPillAtScrollIndicator: View {
    let model: ReadingProgressModel
    let top: Double

    var body: some View {
        GeometryReader { proxy in
            let travel = max(proxy.size.height - top - 60, 0)
            ProgressPill(model: model)
                .padding(.trailing, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .offset(y: top + travel * model.value)
        }
    }
}
