import SwiftUI

struct GlobalPlayerContainerView<Content: View>: View {
    let content: Content
    @StateObject private var viewModel = SpeechPlayerViewModel()
    @EnvironmentObject var appSettings: AppSettings

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if appSettings.enableTTS && viewModel.hasItems {
                VStack(spacing: 0) {
                    SpeechPlayerView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 49)
                }
            }
        }
        .animation(.spring(), value: viewModel.hasItems)
        .task {
            await viewModel.setup()
        }
    }
}

#Preview {
    GlobalPlayerContainerView {
        Text("Main Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
    .environmentObject(AppSettings())
}
