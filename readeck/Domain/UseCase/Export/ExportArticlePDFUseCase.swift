//
//  ExportArticlePDFUseCase.swift
//  readeck
//
//  Turns a bookmark and its article HTML into a shareable PDF file.
//
//  The article HTML holds neither the metadata (title, authors, date, source) nor any
//  styling, so the print document is assembled here and handed to the
//  `PPDFRenderingService` port, which keeps WebKit out of the domain.
//

import Foundation

enum ExportArticlePDFError: Error, Equatable {
    /// The bookmark has no article text to export.
    case emptyArticle
    /// The renderer could not produce any PDF data.
    case renderingFailed
    /// The PDF could not be written to disk.
    case writeFailed
}

protocol PExportArticlePDFUseCase {
    /// Renders the article as a PDF and returns the file URL it was written to.
    func execute(bookmark: BookmarkDetail, articleHTML: String, settings: Settings?) async throws -> URL
}

final class ExportArticlePDFUseCase: PExportArticlePDFUseCase {
    private let renderingService: PPDFRenderingService
    private let fileManager: FileManager

    /// Temporary home of the generated files. Cleared before every export so old
    /// documents cannot pile up in the container.
    private static let exportDirectoryName = "PDFExports"

    init(renderingService: PPDFRenderingService, fileManager: FileManager = .default) {
        self.renderingService = renderingService
        self.fileManager = fileManager
    }

    func execute(bookmark: BookmarkDetail, articleHTML: String, settings: Settings?) async throws -> URL {
        let trimmedHTML = articleHTML.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHTML.isEmpty else { throw ExportArticlePDFError.emptyArticle }

        // Remote images would make the offscreen renderer wait on the network. What is
        // already cached is inlined up front; the renderer still gives the rest a short
        // grace period before it goes ahead without them.
        let embeddedHTML = trimmedHTML.contains("src=\"http")
            ? await HTMLImageEmbedder().embedBase64Images(in: trimmedHTML)
            : trimmedHTML

        let document = PrintHTMLDocumentBuilder.build(
            metadata: Self.metadata(for: bookmark),
            articleHTML: embeddedHTML,
            style: PrintDocumentStyle.resolve(settings: settings)
        )

        let data: Data
        do {
            data = try await renderingService.renderPDF(
                html: document,
                pageMargin: PrintHTMLDocumentBuilder.pageMarginPoints
            )
        } catch {
            Logger.general.error("PDF export failed to render: \(error.localizedDescription)")
            throw ExportArticlePDFError.renderingFailed
        }

        return try write(data, fileName: Self.fileName(for: bookmark.title))
    }

    // MARK: - Document

    static func metadata(for bookmark: BookmarkDetail) -> PrintDocumentMetadata {
        PrintDocumentMetadata(
            title: bookmark.title,
            authors: bookmark.authors,
            formattedDate: formattedDate(from: bookmark.created),
            sourceURL: bookmark.url
        )
    }

    /// Formats the server's ISO timestamp for the document header, with and without
    /// fractional seconds. Falls back to an empty string so the header just drops the
    /// row instead of printing a raw timestamp.
    static func formattedDate(from isoString: String) -> String {
        let withFractionalSeconds = ISO8601DateFormatter()
        withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let withoutFractionalSeconds = ISO8601DateFormatter()
        withoutFractionalSeconds.formatOptions = [.withInternetDateTime]

        guard let date = withFractionalSeconds.date(from: isoString)
            ?? withoutFractionalSeconds.date(from: isoString) else {
            return ""
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        displayFormatter.locale = .autoupdatingCurrent
        return displayFormatter.string(from: date)
    }

    // MARK: - File

    /// Builds a file-system safe name from the article title.
    static func fileName(for title: String) -> String {
        var name = title
        // Path separators, the characters Windows and iCloud Drive reject, and anything
        // unprintable would all break the file name or the receiving app.
        let illegal = CharacterSet(charactersIn: "/\\:*?\"<>|\u{0}")
            .union(.controlCharacters)
            .union(.illegalCharacters)
        name = name.components(separatedBy: illegal).joined(separator: " ")
        name = name.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // A leading dot would hide the file; a trailing dot confuses the extension.
        name = name.trimmingCharacters(in: CharacterSet(charactersIn: "."))

        if name.count > 80 {
            name = String(name.prefix(80)).trimmingCharacters(in: .whitespaces)
        }
        if name.isEmpty {
            name = "Article"
        }

        return "\(name).pdf"
    }

    private func write(_ data: Data, fileName: String) throws -> URL {
        let directory = fileManager.temporaryDirectory.appendingPathComponent(Self.exportDirectoryName, isDirectory: true)

        // Drop whatever a previous export left behind before writing the new file.
        try? fileManager.removeItem(at: directory)

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent(fileName)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            Logger.general.error("PDF export failed to write file: \(error.localizedDescription)")
            throw ExportArticlePDFError.writeFailed
        }
    }
}
