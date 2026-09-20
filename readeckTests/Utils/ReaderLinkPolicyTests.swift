//
//  ReaderLinkPolicyTests.swift
//  readeckTests
//

import Testing
import Foundation
import WebKit
@testable import readeck

@Suite("ReaderLinkPolicy Tests")
struct ReaderLinkPolicyTests {

    private let documentURL = URL(string: "about:blank")!

    /// Resolves an href the way the web view does, against the reader's base URL.
    private func resolved(_ href: String) -> URL {
        URL(string: href, relativeTo: documentURL)!.absoluteURL
    }

    private func decide(
        _ href: String,
        navigationType: WKNavigationType = .linkActivated,
        documentURL: URL? = URL(string: "about:blank")!
    ) -> ReaderLinkDecision {
        ReaderLinkPolicy.decide(
            for: resolved(href),
            navigationType: navigationType,
            documentURL: documentURL
        )
    }

    // MARK: - Initial load and scripted navigation

    @Test("The initial article load is never intercepted")
    func initialLoadPassesThrough() {
        #expect(
            ReaderLinkPolicy.decide(
                for: documentURL,
                navigationType: .other,
                documentURL: nil
            ) == .allowInPage
        )
    }

    @Test("Non link-activated navigations pass through", arguments: [
        WKNavigationType.other,
        .reload,
        .backForward,
        .formSubmitted,
        .formResubmitted
    ])
    func nonLinkNavigationsPassThrough(navigationType: WKNavigationType) {
        #expect(decide("https://example.com", navigationType: navigationType) == .allowInPage)
    }

    @Test("A link activation without a URL passes through")
    func linkWithoutURLPassesThrough() {
        #expect(
            ReaderLinkPolicy.decide(
                for: nil,
                navigationType: .linkActivated,
                documentURL: documentURL
            ) == .allowInPage
        )
    }

    // MARK: - External links

    @Test("External web links are opened outside the reader", arguments: [
        "https://example.com/article",
        "http://example.com",
        "https://example.com/page#section"
    ])
    func externalWebLinksOpenExternally(href: String) {
        #expect(decide(href) == .openExternally(URL(string: href)!))
    }

    @Test("System schemes are opened outside the reader", arguments: [
        "mailto:info@example.com",
        "tel:+4915112345678",
        "sms:+4915112345678"
    ])
    func systemSchemesOpenExternally(href: String) {
        #expect(decide(href) == .openExternally(URL(string: href)!))
    }

    @Test("Scheme matching is case insensitive")
    func schemeMatchingIsCaseInsensitive() {
        let url = URL(string: "HTTPS://Example.com")!
        #expect(
            ReaderLinkPolicy.decide(
                for: url,
                navigationType: .linkActivated,
                documentURL: documentURL
            ) == .openExternally(url)
        )
    }

    // MARK: - In-document anchors

    @Test("Anchor links stay inside the article", arguments: [
        "#footnote-1",
        "#",
        "#section%20two"
    ])
    func anchorLinksStayInPage(href: String) {
        #expect(decide(href) == .allowInPage)
    }

    @Test("Anchor links stay in page before the document URL is known")
    func anchorLinksStayInPageWithoutDocumentURL() {
        #expect(decide("#footnote-1", documentURL: nil) == .allowInPage)
    }

    @Test("An anchor on a different document is treated as external")
    func anchorOnForeignDocumentIsExternal() {
        let url = URL(string: "https://example.com/other#footnote-1")!
        #expect(
            ReaderLinkPolicy.decide(
                for: url,
                navigationType: .linkActivated,
                documentURL: URL(string: "https://example.com/article")!
            ) == .openExternally(url)
        )
    }

    @Test("An anchor on the real document URL stays in page")
    func anchorOnRealDocumentURLStaysInPage() {
        #expect(
            ReaderLinkPolicy.decide(
                for: URL(string: "https://example.com/article#footnote-1")!,
                navigationType: .linkActivated,
                documentURL: URL(string: "https://example.com/article")!
            ) == .allowInPage
        )
    }

    // MARK: - Schemes that must not escape the reader

    @Test("Unsupported schemes are cancelled without opening anything", arguments: [
        "javascript:void(0)",
        "file:///etc/passwd",
        "data:text/html,<h1>hi</h1>",
        "about:blank"
    ])
    func unsupportedSchemesAreCancelled(href: String) {
        #expect(decide(href) == .cancel)
    }

    @Test("A URL without a scheme is cancelled")
    func schemelessURLIsCancelled() {
        #expect(
            ReaderLinkPolicy.decide(
                for: URL(string: "//example.com/path")!,
                navigationType: .linkActivated,
                documentURL: documentURL
            ) == .cancel
        )
    }

    // MARK: - In-app browser support

    @Test("Only http and https can be shown in the in-app browser")
    func inAppBrowserSupport() {
        #expect(ReaderLinkPolicy.supportsInAppBrowser(URL(string: "https://example.com")!))
        #expect(ReaderLinkPolicy.supportsInAppBrowser(URL(string: "http://example.com")!))
        #expect(ReaderLinkPolicy.supportsInAppBrowser(URL(string: "HTTPS://example.com")!))
        #expect(!ReaderLinkPolicy.supportsInAppBrowser(URL(string: "mailto:a@example.com")!))
        #expect(!ReaderLinkPolicy.supportsInAppBrowser(URL(string: "tel:+491511")!))
    }
}
