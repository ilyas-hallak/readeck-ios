import UIKit
import SafariServices

struct URLUtil {
    
    static func open(url: String, urlOpener: UrlOpener = .inAppBrowser) {
        // Could be extended to open in other browsers like Firefox, Brave etc. if somebody has a multi browser setup
        // and wants readeck links to always opened in a specific browser
        switch urlOpener {
        case .defaultBrowser:
            openUrlInDefaultBrowser(url: url)
        default:
            openUrlInInAppBrowser(url: url)
        }
    }
    
    static func openUrlInDefaultBrowser(url: String) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    static func openUrlInInAppBrowser(url: String) {
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
        
    static func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString), let host = url.host else { return nil }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}
