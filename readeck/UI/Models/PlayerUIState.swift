import Foundation
import Combine

final class PlayerUIState: ObservableObject {
    @Published var isPlayerVisible = false

    func showPlayer() {
        isPlayerVisible = true
    }

    func hidePlayer() {
        isPlayerVisible = false
    }

    func togglePlayer() {
        isPlayerVisible.toggle()
    }
}
