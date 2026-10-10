import SwiftUI

/// Draws the reading progress as a ring around the Dynamic Island.
/// Pulses once when the article is read to the end.
struct IslandProgressRing: View {
    let model: ReadingProgressModel
    let isShown: Bool

    @State private var pulseCount = 0
    @State private var hasPulsed = false

    // There is no API for the island frame, so these are measured on an iPhone 17 Pro.
    private static let islandSize = CGSize(width: 125, height: 37)
    private static let islandTop: Double = 14
    private static let gap: Double = 3
    private nonisolated static let lineWidth = 2.5

    /// Devices with a Dynamic Island have a top safe area of at least 59 points.
    static func isAvailable(statusBarHeight: Double) -> Bool {
        statusBarHeight >= 59
    }

    /// Also true in landscape, where the island sits on the side.
    static var isAvailableOnDevice: Bool {
        guard let insets = UIWindow.current?.safeAreaInsets else { return false }
        return isAvailable(statusBarHeight: max(insets.top, insets.left, insets.right))
    }

    private var isComplete: Bool { model.value >= 0.995 }

    var body: some View {
        let shape = IslandRingShape()
        ZStack {
            shape.stroke(.primary.opacity(0.15), lineWidth: Self.lineWidth)
            shape.trim(from: 0, to: model.value)
                .stroke(.tint, style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round))
        }
        .keyframeAnimator(initialValue: Pulse(), trigger: pulseCount) { ring, pulse in
            ring
                .background {
                    // A copy of the ring that spreads out and fades, like a ripple
                    shape.stroke(.tint, lineWidth: Self.lineWidth)
                        .padding(-pulse.spread)
                        .opacity(pulse.waveOpacity)
                }
                .scaleEffect(pulse.scale)
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                SpringKeyframe(1.08, duration: 0.15)
                SpringKeyframe(1, duration: 0.4)
            }
            KeyframeTrack(\.spread) {
                LinearKeyframe(0, duration: 0.05)
                CubicKeyframe(14, duration: 0.7)
            }
            KeyframeTrack(\.waveOpacity) {
                LinearKeyframe(0.9, duration: 0.05)
                CubicKeyframe(0, duration: 0.7)
            }
        }
        .frame(width: Self.islandSize.width + 2 * Self.gap, height: Self.islandSize.height + 2 * Self.gap)
        .padding(.top, Self.islandTop - Self.gap)
        .frame(maxWidth: .infinity, alignment: .top)
        .onChange(of: isComplete && isShown) { _, shouldPulse in
            pulseIfNeeded(shouldPulse)
        }
        .onChange(of: isComplete) { _, complete in
            if !complete { hasPulsed = false }
        }
    }

    private func pulseIfNeeded(_ shouldPulse: Bool) {
        guard shouldPulse, !hasPulsed else { return }
        hasPulsed = true
        pulseCount += 1
    }
}

private struct Pulse {
    var scale: Double = 1
    var spread: Double = 0
    var waveOpacity: Double = 0
}

/// A capsule that starts at the bottom center, so the progress grows from there clockwise.
private struct IslandRingShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.height / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + radius, y: rect.midY),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.midY),
            radius: radius,
            startAngle: .degrees(270),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
