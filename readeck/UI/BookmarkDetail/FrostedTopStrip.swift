import SwiftUI

/// Frosted background behind the top bar, which fades out towards the content.
/// Stands in for the system scroll edge effect where the content ignores the top safe area.
struct FrostedTopStrip: View {
    let height: Double

    var body: some View {
        Rectangle()
            .fill(.regularMaterial)
            .mask {
                LinearGradient(
                    stops: [.init(color: .black, location: 0.6), .init(color: .clear, location: 1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(height: height + 12)
    }
}
