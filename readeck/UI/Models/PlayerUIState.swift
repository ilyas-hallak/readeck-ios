import Foundation
import Combine

class PlayerUIState: ObservableObject {
    @Published var isPlayerVisible: Bool = false
    
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