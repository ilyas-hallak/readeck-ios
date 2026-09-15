//
//  WebKitPDFRenderingService.swift
//  readeck
//
//  Data-layer implementation of `PPDFRenderingService`. Renders into an offscreen
//  `WKWebView` that is created just for the export, so the result does not depend on
//  which reader (`WebView` or `NativeWebView`) is currently on screen.
//
//  `WKWebView.createPDF(configuration:)` returns the whole document as one endless
//  page and ignores `@page`, which is unusable on paper. The print formatter of the
//  same web view paginates properly instead: it keeps a margin on every page and does
//  not cut through a line of text.
//

import Foundation
import UIKit
import WebKit

@MainActor
final class WebKitPDFRenderingService: NSObject, PPDFRenderingService {

    /// A4 in points, the paper size the exported document is laid out for.
    private static let paperSize = CGSize(width: 595.2, height: 841.8)

    /// How long a remote image may take before the page is rendered without it.
    private let resourceTimeout: TimeInterval
    /// How long the document itself may take to load.
    private let loadTimeout: TimeInterval

    nonisolated init(loadTimeout: TimeInterval = 20, resourceTimeout: TimeInterval = 10) {
        self.loadTimeout = loadTimeout
        self.resourceTimeout = resourceTimeout
    }

    func renderPDF(html: String, pageMargin: Double) async throws -> Data {
        let webView = makeWebView()
        let loader = NavigationLoader()
        webView.navigationDelegate = loader

        defer {
            webView.navigationDelegate = nil
            webView.stopLoading()
        }

        webView.loadHTMLString(html, baseURL: nil)

        guard await loader.waitUntilFinished(timeout: loadTimeout) else {
            throw PDFRenderingError.loadFailed
        }

        await waitForImages(in: webView)

        return try renderPages(of: webView, pageMargin: pageMargin)
    }

    // MARK: - Setup

    private func makeWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        // The document itself carries no scripts, but the image readiness check runs
        // through `evaluateJavaScript`, which needs JavaScript enabled.
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        let webView = WKWebView(
            frame: CGRect(origin: .zero, size: Self.paperSize),
            configuration: configuration
        )
        webView.isOpaque = true
        webView.backgroundColor = .white
        return webView
    }

    // MARK: - Loading

    /// Polls until every `<img>` reports itself as settled. Images that fail or hang
    /// are simply left out: a PDF without one picture beats no PDF at all.
    private func waitForImages(in webView: WKWebView) async {
        let deadline = Date().addingTimeInterval(resourceTimeout)
        let script = "Array.from(document.images).every(img => img.complete)"

        while Date() < deadline {
            let settled = (try? await webView.evaluateJavaScript(script)) as? Bool
            if settled == true { return }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }

        Logger.data.info("PDF export: image timeout reached, rendering without the pending images")
    }

    // MARK: - Pagination

    private func renderPages(of webView: WKWebView, pageMargin: Double) throws -> Data {
        let paperRect = CGRect(origin: .zero, size: Self.paperSize)
        let printableRect = paperRect.insetBy(dx: pageMargin, dy: pageMargin)

        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)
        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pageCount = renderer.numberOfPages
        guard pageCount > 0 else { throw PDFRenderingError.emptyDocument }

        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, paperRect, nil)
        for page in 0..<pageCount {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: page, in: paperRect)
        }
        UIGraphicsEndPDFContext()

        guard data.length > 0 else { throw PDFRenderingError.emptyDocument }

        Logger.data.info("PDF export: rendered \(pageCount) page(s), \(data.length) bytes")
        return data as Data
    }
}

// MARK: - Navigation

/// Bridges the navigation delegate callbacks into a single awaitable result.
@MainActor
private final class NavigationLoader: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Bool, Never>?
    private var result: Bool?

    func waitUntilFinished(timeout: TimeInterval) async -> Bool {
        if let result { return result }

        let timeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.finish(false)
        }
        defer { timeoutTask.cancel() }

        return await withCheckedContinuation { continuation in
            if let result {
                continuation.resume(returning: result)
            } else {
                self.continuation = continuation
            }
        }
    }

    private func finish(_ success: Bool) {
        guard result == nil else { return }
        result = success
        continuation?.resume(returning: success)
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finish(true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Logger.data.error("PDF export: navigation failed - \(error.localizedDescription)")
        finish(false)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Logger.data.error("PDF export: provisional navigation failed - \(error.localizedDescription)")
        finish(false)
    }
}
