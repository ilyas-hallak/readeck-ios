import SwiftUI

struct SpeechPlayerView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    var onTap: () -> Void
    var onClose: (() -> Void)? = nil

    var body: some View {
        MiniPlayerView(viewModel: viewModel, onTap: onTap, onClose: onClose)
    }
}
