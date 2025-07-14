import SwiftUI

struct PlayerQueueResumeButton: View {
    @ObservedObject private var queue = SpeechQueue.shared
    @EnvironmentObject var playerUIState: PlayerUIState
    private let playerViewModel = SpeechPlayerViewModel()
    
    var body: some View {
        if queue.hasItems, !playerUIState.isPlayerVisible {
            Button(action: {
                playerViewModel.resume()
                playerUIState.showPlayer()
            }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vorlese-Queue")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(queue.queueItems.count) Artikel in der Queue")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Button(action: {
                        playerViewModel.resume()
                        playerUIState.showPlayer()
                    }) {
                        Text("Weiterhören")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color(.systemBackground))
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color(.systemBackground))
            .padding(.bottom, 8)
            .transition(.opacity)
            .animation(.spring(), value: queue.hasItems)
        }
    }
} 