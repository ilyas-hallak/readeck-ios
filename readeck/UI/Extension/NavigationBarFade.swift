import SwiftUI
import UIKit

extension View {
    /// Fades the navigation bar out without hiding it. Hiding changes the safe area,
    /// which shifts the content, and iOS 26 drops the swipe back without a bar.
    func navigationBarFaded(_ isFaded: Bool) -> some View {
        background(NavigationBarFader(isFaded: isFaded))
    }
}

private struct NavigationBarFader: UIViewRepresentable {
    let isFaded: Bool

    func makeUIView(context: Context) -> NavigationBarFaderView {
        NavigationBarFaderView()
    }

    func updateUIView(_ view: NavigationBarFaderView, context: Context) {
        view.setFaded(isFaded)
    }

    static func dismantleUIView(_ view: NavigationBarFaderView, coordinator: ()) {
        view.restore()
    }
}

final class NavigationBarFaderView: UIView {
    private weak var navigationController: UINavigationController?
    private var isFaded = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else {
            restore()
            return
        }
        attach()
        applyFade(animated: false)
    }

    func setFaded(_ faded: Bool) {
        guard faded != isFaded else { return }
        isFaded = faded
        applyFade(animated: true)
    }

    func restore() {
        guard let bar = navigationController?.navigationBar else { return }
        bar.alpha = 1
        bar.transform = .identity
    }

    private func attach() {
        guard navigationController == nil, let controller = owningNavigationController() else { return }
        navigationController = controller
        controller.interactivePopGestureRecognizer?.addTarget(self, action: #selector(popGestureChanged))
        if #available(iOS 26, *) {
            controller.interactiveContentPopGestureRecognizer?.addTarget(self, action: #selector(popGestureChanged))
        }
    }

    private func applyFade(animated: Bool) {
        guard let bar = navigationController?.navigationBar else { return }
        let alpha: CGFloat = isFaded ? 0 : 1
        // Slides the bar up behind the status bar while it fades. Its bottom edge ends where
        // the status bar ends, so the progress line in the reader can move along with it.
        let transform: CGAffineTransform = isFaded ? CGAffineTransform(translationX: 0, y: -bar.bounds.height) : .identity
        guard animated else {
            bar.alpha = alpha
            bar.transform = transform
            return
        }
        UIView.animate(withDuration: 0.35, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            bar.alpha = alpha
            bar.transform = transform
        }
    }

    // The screen below expects a visible bar, so bring it back along with the swipe.
    @objc private func popGestureChanged(_ recognizer: UIGestureRecognizer) {
        guard recognizer.state == .began, isFaded,
              let bar = navigationController?.navigationBar,
              let coordinator = navigationController?.transitionCoordinator else { return }
        coordinator.animate(alongsideTransition: { _ in
            bar.alpha = 1
            bar.transform = .identity
        }, completion: { [weak self] context in
            if context.isCancelled, self?.isFaded == true {
                self?.applyFade(animated: false)
            }
        })
    }

    private func owningNavigationController() -> UINavigationController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let controller = current as? UIViewController, let navigation = controller.navigationController {
                return navigation
            }
            responder = current.next
        }
        return nil
    }
}
