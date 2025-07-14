import UIKit
import SafariServices

class SafariUtil {
    static func openInSafari(url: String) {
        guard let url = URL(string: url) else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            let safariViewController = SFSafariViewController(url: url)
            safariViewController.preferredBarTintColor = UIColor.systemBackground
            safariViewController.preferredControlTintColor = UIColor.tintColor
            
            // Finde den präsentierenden View Controller
            var presentingViewController = rootViewController
            while let presented = presentingViewController.presentedViewController {
                presentingViewController = presented
            }
            
            presentingViewController.present(safariViewController, animated: true)
        }
    }
}

struct URLUtil {
    static func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString), let host = url.host else { return nil }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}
