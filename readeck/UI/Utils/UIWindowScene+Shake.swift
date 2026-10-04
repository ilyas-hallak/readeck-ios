import UIKit

// Shake handling lives on the scene, the next responder after the window, because NetFox
// already overrides motionEnded on UIWindow and two such overrides leave the winner undefined.
extension UIWindowScene {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else {
            super.motionEnded(motion, with: event)
            return
        }
        if let undoManager = keyWindow?.undoManager, undoManager.canUndo {
            presentUndoAlert(for: undoManager)
        } else {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
            super.motionEnded(motion, with: event)
        }
    }

    // UIKit only offers shake to undo for the first responder's undo manager. In the reader that
    // is the web view with its own, empty one, so the alert is shown here for the window's manager.
    private func presentUndoAlert(for undoManager: UndoManager) {
        guard var presenter = keyWindow?.rootViewController else { return }
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        guard !(presenter is UIAlertController) else { return }

        let alert = UIAlertController(title: undoManager.undoMenuItemTitle, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Undo".localized, style: .default) { _ in
            undoManager.undo()
        })
        presenter.present(alert, animated: true)
    }
}
