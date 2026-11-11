import UIKit

extension UIWindow {
    /// The key window of the connected window scene.
    static var current: UIWindow? {
        let scene = UIApplication.shared.connectedScenes.first { $0 is UIWindowScene } as? UIWindowScene
        return scene?.keyWindow
    }
}
