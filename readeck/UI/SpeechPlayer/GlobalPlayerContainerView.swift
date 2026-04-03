import SwiftUI

struct GlobalPlayerContainerView<Content: View>: View {
    let content: Content
    @ObservedObject var viewModel: SpeechPlayerViewModel
    @EnvironmentObject private var appSettings: AppSettings
    @State private var isPlayerSheetPresented = false
    @Binding var isPlayerDismissed: Bool

    init(viewModel: SpeechPlayerViewModel, isPlayerDismissed: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.viewModel = viewModel
        self._isPlayerDismissed = isPlayerDismissed
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if appSettings.enableTTS && viewModel.hasItems && !isPlayerDismissed {
                VStack(spacing: 0) {
                    MiniPlayerView(viewModel: viewModel, onTap: {
                        isPlayerSheetPresented = true
                    }, onClose: {
                        isPlayerDismissed = true
                    })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 49)
                }
            }
        }
        .animation(.spring(), value: viewModel.hasItems)
        .sheet(isPresented: $isPlayerSheetPresented) {
            PlayerSheetView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
    }
}

#Preview {
    GlobalPlayerContainerView(viewModel: SpeechPlayerViewModel(), isPlayerDismissed: .constant(false)) {
        Text("Main Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
    .environmentObject(AppSettings())
}
