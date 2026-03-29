import SwiftUI

struct PlayerQueueResumeButton: View {
    @ObservedObject private var queue = SpeechQueue.shared
    var onResume: () -> Void

    var body: some View {
        if queue.hasItems {
            Button(action: onResume) {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(queue.queueItems.first?.title ?? "Read-aloud Queue")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text("\(queue.queueItems.count) \(String(localized: "articles in queue"))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("Show Player")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)
            .background(Color(.systemBackground))
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color(.systemBackground))
            .padding(.bottom, 8)
            .transition(.opacity)
            .animation(.spring(), value: queue.hasItems)
        }
    }
}
