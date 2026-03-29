import SwiftUI

struct SpeechPlayerView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    var onTap: () -> Void

    var body: some View {
        MiniPlayerView(viewModel: viewModel, onTap: onTap)
    }
}
