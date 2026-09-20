//
//  ReaderLinkPolicy.swift
//  readeck
//
//  Decides what happens when a navigation is triggered inside the article
//  reader web view. Kept free of WebKit view types so it can be unit tested.
//

import Foundation
import WebKit

/// What the reader should do with a navigation that the web view is about to perform.
enum ReaderLinkDecision: Equatable {
    /// Let the web view perform the navigation, for example the initial article load
    /// or an in-document anchor jump.
    case allowInPage
    /// Cancel the navigation and hand the URL to the browser instead.
    case openExternally(URL)
    /// Cancel the navigation without opening anything.
    case cancel
}

enum ReaderLinkPolicy {
    /// Schemes we are willing to hand to the system. Everything else stays inside
    /// the reader, so a crafted `javascript:` or `file:` link cannot escape it.
    static let externallyOpenableSchemes: Set<String> = [
        "http", "https", "mailto", "tel", "sms", "facetime", "facetime-audio", "maps"
    ]

    /// - Parameters:
    ///   - url: Target of the navigation, as resolved by the web view.
    ///   - navigationType: How the navigation was triggered.
    ///   - documentURL: URL of the document currently shown, used to recognise
    ///     in-document anchors. The reader loads its HTML with the default
    ///     `about:blank` base URL, so anchors resolve to `about:blank#fragment`.
    static func decide(
        for url: URL?,
        navigationType: WKNavigationType,
        documentURL: URL?
    ) -> ReaderLinkDecision {
        // Everything that is not a user tapping a link must pass through untouched:
        // the initial load(html:) of the article, scripted scrolling, annotation
        // overlays and reloads all arrive as .other.
        guard navigationType == .linkActivated else { return .allowInPage }
        guard let url else { return .allowInPage }

        // Footnote and table-of-contents links must scroll inside the article
        // instead of kicking the reader out to the browser.
        if isSameDocumentAnchor(url, documentURL: documentURL) { return .allowInPage }

        guard let scheme = url.scheme?.lowercased(),
              externallyOpenableSchemes.contains(scheme) else {
            return .cancel
        }

        return .openExternally(url)
    }

    /// `SFSafariViewController` only accepts http and https URLs. Schemes like
    /// `mailto:` or `tel:` have to go to the system handler even when the user
    /// prefers the in-app browser.
    static func supportsInAppBrowser(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    // MARK: - Helpers

    private static func isSameDocumentAnchor(_ url: URL, documentURL: URL?) -> Bool {
        // A same-document jump always carries a fragment. `href="#"` produces an
        // empty but present fragment, which is a jump to the top of the page.
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.fragment != nil else {
            return false
        }

        guard let documentURL else {
            // Before the first navigation finishes there is no document URL yet.
            // Only the reader's own about:blank base can produce anchors at that point.
            return url.scheme?.lowercased() == "about"
        }

        return strippingFragment(url) == strippingFragment(documentURL)
    }

    private static func strippingFragment(_ url: URL) -> String? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.fragment = nil
        return components.string
    }
}
