import SwiftUI
import UIKit

struct DisableBackSwipeModifier: ViewModifier {
    let disabled: Bool

    func body(content: Content) -> some View {
        content
            .background(DisableBackSwipeRepresentable(disabled: disabled))
    }
}

private struct DisableBackSwipeRepresentable: UIViewControllerRepresentable {
    let disabled: Bool

    func makeUIViewController(context: Context) -> DisableBackSwipeViewController {
        DisableBackSwipeViewController(disabled: disabled)
    }

    func updateUIViewController(_ uiViewController: DisableBackSwipeViewController, context: Context) {
        uiViewController.setBackSwipeDisabled(disabled)
    }
}

private class DisableBackSwipeViewController: UIViewController {
    var disabled: Bool

    init(disabled: Bool) {
        self.disabled = disabled
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setBackSwipeDisabled(disabled)
    }

    func setBackSwipeDisabled(_ disabled: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = !disabled
    }
}

extension View {
    func disableBackSwipe(_ disabled: Bool) -> some View {
        modifier(DisableBackSwipeModifier(disabled: disabled))
    }
}
