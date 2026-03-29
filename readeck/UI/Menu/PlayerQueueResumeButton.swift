import SwiftUI

struct PlayerQueueResumeButton: View {
    @ObservedObject private var queue = SpeechQueue.shared

    var body: some View {
        if queue.hasItems {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Read-aloud Queue")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(queue.queueItems.count) articles in the queue")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(Color(.systemBackground))
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color(.systemBackground))
            .padding(.bottom, 8)
        }
    }
}
