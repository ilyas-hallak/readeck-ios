import SwiftUI

struct SpeechPlayerView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    @State private var isSheetPresented = false

    var body: some View {
        MiniPlayerView(viewModel: viewModel) {
            isSheetPresented = true
        }
        .sheet(isPresented: $isSheetPresented) {
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
