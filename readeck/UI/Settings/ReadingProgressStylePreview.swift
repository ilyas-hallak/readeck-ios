import SwiftUI

/// A mock of the top of a phone running the reader, which scrolls through an article in a
/// loop and shows the progress the way the given style does. Without a style it shows none.
@available(iOS 26.0, *)
struct ReadingProgressStylePreview: View {
    let style: ReadingProgressStyle?

    @State private var model = ReadingProgressModel()
    @State private var isToolbarVisible = true
    @State private var isScrollPaused = false

    // Drawn at the size of an iPhone 17 Pro and scaled down, so the real indicators fit as they are
    private static let screen = CGSize(width: 402, height: 300)
    private static let statusBarHeight: Double = 62
    private static let topBarInset: Double = 116
    private static let scale = 0.5

    var body: some View {
        ZStack(alignment: .top) {
            articleLines
            FrostedTopStrip(height: isToolbarVisible ? Self.topBarInset : Self.statusBarHeight)
            navigationBar
            if let style {
                ReadingProgressOverlay(
                    style: style,
                    model: model,
                    isToolbarVisible: isToolbarVisible,
                    isScrollPaused: isScrollPaused,
                    topBarInset: Self.topBarInset,
                    statusBarHeight: Self.statusBarHeight
                )
            }
            statusBar
        }
        .frame(width: Self.screen.width, height: Self.screen.height, alignment: .top)
        .background(Color(.systemBackground))
        .clipShape(.rect(topLeadingRadius: 56, topTrailingRadius: 56))
        .overlay {
            UnevenRoundedRectangle(topLeadingRadius: 56, topTrailingRadius: 56)
                .stroke(.primary.opacity(0.2), lineWidth: 6)
        }
        // The phone is cut off at the bottom, the fade makes that look intended
        .mask {
            LinearGradient(
                stops: [.init(color: .black, location: 0.75), .init(color: .clear, location: 1)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .scaleEffect(Self.scale, anchor: .topLeading)
        .frame(width: Self.screen.width * Self.scale, height: Self.screen.height * Self.scale, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task { await play() }
    }

    private var statusBar: some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(.black)
                .frame(width: 125, height: 37)
                .padding(.top, 14)
            HStack {
                Text("9:41")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Image(systemName: "battery.100")
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 44)
            .padding(.top, 22)
        }
    }

    private var navigationBar: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .semibold))
            Spacer()
            Image(systemName: "ellipsis")
                .font(.system(size: 22, weight: .semibold))
        }
        .foregroundStyle(.tint)
        .padding(.horizontal, 24)
        .frame(height: Self.topBarInset - Self.statusBarHeight)
        .frame(maxWidth: .infinity)
        .offset(y: Self.statusBarHeight)
        .offset(y: isToolbarVisible ? 0 : -(Self.topBarInset - Self.statusBarHeight))
        .opacity(isToolbarVisible ? 1 : 0)
    }

    private var articleLines: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 6)
                .frame(width: 260, height: 26)
                .foregroundStyle(.primary.opacity(0.5))
                .padding(.bottom, 8)
            ForEach(0..<40, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: index % 6 == 5 ? 180 : 354, height: 10)
                    .foregroundStyle(.primary.opacity(0.15))
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Self.topBarInset + 20)
        .offset(y: -model.value * 420)
        // Keeps the stack at screen height, the pill at the scroll indicator measures it
        .frame(height: Self.screen.height, alignment: .top)
    }

    // Scrolls in three steps with a pause in between, then starts over
    private func play() async {
        let steps = 3
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            for step in 1...steps {
                isScrollPaused = false
                withAnimation(.easeInOut(duration: 0.35)) { isToolbarVisible = false }
                withAnimation(.easeInOut(duration: 1.2)) { model.value = Double(step) / Double(steps) }
                try? await Task.sleep(for: .seconds(1.2))
                isScrollPaused = true
                try? await Task.sleep(for: .seconds(1.8))
            }
            isScrollPaused = false
            withAnimation(.easeInOut(duration: 0.35)) { isToolbarVisible = true }
            withAnimation(.easeInOut(duration: 0.8)) { model.value = 0 }
            try? await Task.sleep(for: .seconds(0.8))
        }
    }
}
