//
//  PPDFRenderingService.swift
//  readeck
//
//  Output port for turning an HTML document into PDF data. Keeps WebKit and UIKit
//  out of the domain layer so the export use case stays testable with a fake.
//  Implemented in the data layer by `WebKitPDFRenderingService`.
//

import Foundation

enum PDFRenderingError: Error, Equatable {
    /// The web view never finished loading the document.
    case loadFailed
    /// WebKit produced no pages, for example for an empty document.
    case emptyDocument
}

protocol PPDFRenderingService {
    /// Renders a complete HTML document into paginated PDF data.
    /// - Parameters:
    ///   - html: A self-contained HTML document. Remote resources are given a short
    ///     grace period and then skipped, so a slow image cannot block the export.
    ///   - pageMargin: Margin in points kept free on every page.
    func renderPDF(html: String, pageMargin: Double) async throws -> Data
}
