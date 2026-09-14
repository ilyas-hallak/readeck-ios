//
//  ExportArticlePDFUseCaseTests.swift
//  readeckTests
//

import Testing
import Foundation
@testable import readeck

@Suite("ExportArticlePDFUseCase Tests")
struct ExportArticlePDFUseCaseTests {

    private func bookmark(
        title: String = "Sample Article",
        authors: [String] = ["Ada Lovelace"],
        url: String = "https://example.com/sample"
    ) -> BookmarkDetail {
        BookmarkDetail(
            id: "abc",
            title: title,
            url: url,
            description: "",
            siteName: "example.com",
            authors: authors,
            created: "2026-01-03T09:30:00Z",
            updated: "",
            wordCount: 100,
            readingTime: 1,
            hasArticle: true,
            loaded: true,
            isMarked: false,
            isArchived: false,
            labels: [],
            thumbnailUrl: "",
            imageUrl: "",
            lang: "en",
            readProgress: 0
        )
    }

    /// Each test gets its own temporary directory, so the exports cannot collide when
    /// the suite runs in parallel.
    private func makeUseCase(_ service: FakePDFRenderingService) -> (ExportArticlePDFUseCase, URL) {
        let fileManager = ScopedTemporaryFileManager()
        return (ExportArticlePDFUseCase(renderingService: service, fileManager: fileManager), fileManager.scopedTemporaryDirectory)
    }

    // MARK: - Rendering

    @Test("execute renders the print document and writes it to a file")
    func executeWritesFile() async throws {
        let service = FakePDFRenderingService()
        let (useCase, root) = makeUseCase(service)
        defer { try? FileManager.default.removeItem(at: root) }

        let url = try await useCase.execute(
            bookmark: bookmark(),
            articleHTML: "<p>Hello</p>",
            settings: nil
        )

        #expect(url.lastPathComponent == "Sample Article.pdf")
        #expect(FileManager.default.fileExists(atPath: url.path))

        let written = try Data(contentsOf: url)
        #expect(written == service.pdfData)

        // The document handed to the renderer carries the metadata and the article
        #expect(service.receivedHTML?.contains("Sample Article") == true)
        #expect(service.receivedHTML?.contains("Ada Lovelace") == true)
        #expect(service.receivedHTML?.contains("https://example.com/sample") == true)
        #expect(service.receivedHTML?.contains("<p>Hello</p>") == true)
        #expect(service.receivedPageMargin == PrintHTMLDocumentBuilder.pageMarginPoints)
    }

    @Test("execute throws for an article without content")
    func executeEmptyArticle() async {
        let service = FakePDFRenderingService()
        let (useCase, root) = makeUseCase(service)
        defer { try? FileManager.default.removeItem(at: root) }

        await #expect(throws: ExportArticlePDFError.emptyArticle) {
            _ = try await useCase.execute(bookmark: bookmark(), articleHTML: "   \n  ", settings: nil)
        }
        #expect(service.renderCount == 0)
    }

    @Test("a failing renderer surfaces as a rendering error")
    func executeRenderingFailure() async {
        let service = FakePDFRenderingService()
        service.result = .failure(PDFRenderingError.loadFailed)
        let (useCase, root) = makeUseCase(service)
        defer { try? FileManager.default.removeItem(at: root) }

        await #expect(throws: ExportArticlePDFError.renderingFailed) {
            _ = try await useCase.execute(bookmark: bookmark(), articleHTML: "<p>Hi</p>", settings: nil)
        }
    }

    @Test("a new export clears what the previous one left behind")
    func exportClearsPreviousFiles() async throws {
        let service = FakePDFRenderingService()
        let (useCase, root) = makeUseCase(service)
        defer { try? FileManager.default.removeItem(at: root) }

        let first = try await useCase.execute(
            bookmark: bookmark(title: "First"),
            articleHTML: "<p>One</p>",
            settings: nil
        )
        let second = try await useCase.execute(
            bookmark: bookmark(title: "Second"),
            articleHTML: "<p>Two</p>",
            settings: nil
        )

        #expect(FileManager.default.fileExists(atPath: second.path))
        #expect(!FileManager.default.fileExists(atPath: first.path))
    }

    // MARK: - File name

    @Test(
        "file names are stripped of everything the file system rejects",
        arguments: [
            ("Simple title", "Simple title.pdf"),
            ("With / slash", "With slash.pdf"),
            ("a:b*c?d\"e<f>g|h", "a b c d e f g h.pdf"),
            ("  padded  ", "padded.pdf"),
            ("multi   spaces", "multi spaces.pdf"),
            ("", "Article.pdf"),
            ("///", "Article.pdf"),
            (".hidden", "hidden.pdf"),
            ("trailing.", "trailing.pdf"),
            ("line\nbreak", "line break.pdf")
        ]
    )
    func fileNameSanitizing(input: String, expected: String) {
        #expect(ExportArticlePDFUseCase.fileName(for: input) == expected)
    }

    @Test("long titles are cut to a reasonable file name length")
    func fileNameLength() {
        let name = ExportArticlePDFUseCase.fileName(for: String(repeating: "a", count: 300))

        #expect(name.hasSuffix(".pdf"))
        #expect(name.count == 84)
    }

    // MARK: - Metadata

    @Test("the server timestamp becomes a readable date")
    func formattedDate() {
        #expect(!ExportArticlePDFUseCase.formattedDate(from: "2026-01-03T09:30:00Z").isEmpty)
        #expect(!ExportArticlePDFUseCase.formattedDate(from: "2026-01-03T09:30:00.123Z").isEmpty)
    }

    @Test("an unparsable date is dropped instead of printed raw")
    func formattedDateFallback() {
        #expect(ExportArticlePDFUseCase.formattedDate(from: "not a date").isEmpty)
        #expect(ExportArticlePDFUseCase.formattedDate(from: "").isEmpty)
    }

    @Test("metadata is taken from the bookmark, not from the article HTML")
    func metadataFromBookmark() {
        let metadata = ExportArticlePDFUseCase.metadata(for: bookmark())

        #expect(metadata.title == "Sample Article")
        #expect(metadata.authors == ["Ada Lovelace"])
        #expect(metadata.sourceURL == "https://example.com/sample")
        #expect(!metadata.formattedDate.isEmpty)
    }
}

// MARK: - Test doubles

private final class FakePDFRenderingService: PPDFRenderingService, @unchecked Sendable {
    let pdfData = Data("%PDF-1.4 fake".utf8)
    var result: Result<Data, Error>?
    private(set) var receivedHTML: String?
    private(set) var receivedPageMargin: Double?
    private(set) var renderCount = 0

    func renderPDF(html: String, pageMargin: Double) async throws -> Data {
        renderCount += 1
        receivedHTML = html
        receivedPageMargin = pageMargin
        return try (result ?? .success(pdfData)).get()
    }
}

/// Hands the use case a temporary directory of its own instead of the shared one.
private final class ScopedTemporaryFileManager: FileManager {
    let scopedTemporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("PDFExportTests-\(UUID().uuidString)", isDirectory: true)

    override var temporaryDirectory: URL { scopedTemporaryDirectory }
}
