import SwiftUI

struct GlobalPlayerContainerView<Content: View>: View {
    let content: Content
    @StateObject private var viewModel = SpeechPlayerViewModel()
    @EnvironmentObject var playerUIState: PlayerUIState

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if viewModel.hasItems && playerUIState.isPlayerVisible {
                VStack(spacing: 0) {
                    SpeechPlayerView(onClose: { playerUIState.hidePlayer() })
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 49)
                }
            }
        }
        .animation(.spring(), value: viewModel.hasItems)
    }
}

#Preview {
    GlobalPlayerContainerView {
        Text("Main Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
    .environmentObject(PlayerUIState())
} 
