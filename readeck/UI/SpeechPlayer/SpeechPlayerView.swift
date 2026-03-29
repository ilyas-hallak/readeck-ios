import SwiftUI

struct SpeechPlayerView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel

    var body: some View {
        MiniPlayerView(viewModel: viewModel) {
            viewModel.isPlayerSheetPresented = true
        }
        .sheet(isPresented: $viewModel.isPlayerSheetPresented) {
            PlayerSheetView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
    }
}

#Preview {
    SpeechPlayerView(viewModel: SpeechPlayerViewModel())
}
