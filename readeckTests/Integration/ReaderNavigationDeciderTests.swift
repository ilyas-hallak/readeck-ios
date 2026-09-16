//
//  ReaderNavigationDeciderTests.swift
//  readeckTests
//
//  Drives a real WebPage so we actually exercise the iOS 26 navigation decider,
//  not just the pure policy function.
//

import Testing
import Foundation
import WebKit
@testable import readeck

@MainActor
@Suite("Reader navigation decider", .serialized)
struct ReaderNavigationDeciderTests {

    @Test("The initial article load is not blocked")
    func initialLoadSucceeds() async throws {
        guard #available(iOS 26.0, *) else { return }
        let harness = ReaderNavigationHarness()
        try await harness.loadArticle()

        let title = try await harness.holder.page
            .callJavaScript("return document.getElementById('footnote').textContent")
        #expect(title as? String == "Footnote")
        #expect(harness.openedURLs.isEmpty)
    }

    @Test("Tapping an external link opens it outside and leaves the article standing")
    func externalLinkLeavesArticleInPlace() async throws {
        guard #available(iOS 26.0, *) else { return }
        let harness = ReaderNavigationHarness()
        try await harness.loadArticle()
        try await harness.click("external")

        #expect(harness.openedURLs == [URL(string: "https://example.com/target")!])
        #expect(harness.holder.page.url == ReaderWebPageHolder.baseURL)

        // The article is still rendered, the web view did not navigate away.
        let stillThere = try await harness.holder.page
            .callJavaScript("return document.getElementById('external') !== null")
        #expect(stillThere as? Bool == true)
    }

    @Test("Tapping a mailto link hands it to the system")
    func mailtoLinkIsHandedOut() async throws {
        guard #available(iOS 26.0, *) else { return }
        let harness = ReaderNavigationHarness()
        try await harness.loadArticle()
        try await harness.click("mail")

        #expect(harness.openedURLs == [URL(string: "mailto:info@example.com")!])
        #expect(harness.holder.page.url == ReaderWebPageHolder.baseURL)
    }

    @Test("Tapping an anchor stays inside the article instead of opening the browser")
    func anchorLinkStaysInPage() async throws {
        guard #available(iOS 26.0, *) else { return }
        let harness = ReaderNavigationHarness()
        try await harness.loadArticle()
        try await harness.click("anchor")

        #expect(harness.openedURLs.isEmpty)

        // The navigation really happened inside the document instead of being cancelled.
        let hash = try await harness.holder.page.callJavaScript("return window.location.hash")
        #expect(hash as? String == "#footnote")
    }
}

// MARK: - Harness

@available(iOS 26.0, *)
@MainActor
private final class ReaderNavigationHarness {
    let holder = ReaderWebPageHolder()
    private(set) var openedURLs: [URL] = []

    private let html = """
    <html><body>
        <a id="external" href="https://example.com/target">external</a>
        <a id="mail" href="mailto:info@example.com">mail</a>
        <a id="anchor" href="#footnote">anchor</a>
        <div style="height: 3000px"></div>
        <h2 id="footnote">Footnote</h2>
    </body></html>
    """

    init() {
        holder.decider.openExternally = { [weak self] url in
            self?.openedURLs.append(url)
        }
    }

    func loadArticle() async throws {
        for try await event in holder.page.load(html: html, baseURL: ReaderWebPageHolder.baseURL) {
            if case .finished = event { return }
        }
    }

    func click(_ elementId: String) async throws {
        try await holder.page.callJavaScript("document.getElementById('\(elementId)').click()")
        // Give WebKit a moment to run the navigation through the decider.
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
