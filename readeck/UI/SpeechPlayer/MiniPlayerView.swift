import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at top
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * viewModel.articleProgress, height: 2)
            }
            .frame(height: 2)

            HStack(spacing: 12) {
                // Article title
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.queueItems.first?.title ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if viewModel.queueCount > 1 {
                        Text("\(viewModel.queueCount) articles in queue")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .onTapGesture { onTap() }

                Spacer()

                // Play/Pause
                Button(action: {
                    if viewModel.isSpeaking {
                        viewModel.pause()
                    } else {
                        viewModel.resume()
                    }
                }) {
                    Image(systemName: viewModel.isSpeaking ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}
