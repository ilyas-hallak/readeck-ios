import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    var onTap: () -> Void
    var onClose: (() -> Void)? = nil

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
                    Text(viewModel.currentItem?.title ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if viewModel.queueCount > 1 {
                        Text("\(viewModel.queueCount) \(String(localized: "articles in queue"))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
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

                // Close
                if let onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}
