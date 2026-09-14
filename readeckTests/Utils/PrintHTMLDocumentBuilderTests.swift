//
//  PrintHTMLDocumentBuilderTests.swift
//  readeckTests
//

import Testing
import Foundation
@testable import readeck

@Suite("PrintHTMLDocumentBuilder Tests")
struct PrintHTMLDocumentBuilderTests {

    private let style = PrintDocumentStyle(
        fontFaceCSS: "",
        fontStackCSS: "Georgia, serif",
        lineHeight: 1.6
    )

    private func build(
        metadata: PrintDocumentMetadata = PrintDocumentMetadata(title: "Title"),
        articleHTML: String = "<p>Body</p>"
    ) -> String {
        PrintHTMLDocumentBuilder.build(metadata: metadata, articleHTML: articleHTML, style: style)
    }

    // MARK: - Header

    @Test("header renders title, authors, date and source URL")
    func headerRendersMetadata() {
        let html = build(metadata: PrintDocumentMetadata(
            title: "A Long Read",
            authors: ["Ada Lovelace", "Alan Turing"],
            formattedDate: "3 Jan 2026",
            sourceURL: "https://example.com/a-long-read"
        ))

        #expect(html.contains("<h1 class=\"doc-title\">A Long Read</h1>"))
        #expect(html.contains("Ada Lovelace, Alan Turing"))
        #expect(html.contains("3 Jan 2026"))
        #expect(html.contains("https://example.com/a-long-read"))
        // The separating rule below the header
        #expect(html.contains("border-bottom: 1px solid var(--print-rule)"))
    }

    @Test("header omits rows the bookmark has no value for")
    func headerOmitsEmptyRows() {
        let html = build(metadata: PrintDocumentMetadata(title: "Only a title"))

        #expect(html.contains("<h1 class=\"doc-title\">"))
        #expect(!html.contains("<p class=\"doc-authors\">"))
        #expect(!html.contains("<p class=\"doc-date\">"))
        #expect(!html.contains("<p class=\"doc-source\">"))
    }

    @Test("header drops author entries that are blank")
    func headerSkipsBlankAuthors() {
        let html = build(metadata: PrintDocumentMetadata(title: "T", authors: ["  ", ""]))

        #expect(!html.contains("<p class=\"doc-authors\">"))
    }

    @Test("metadata is HTML escaped")
    func metadataIsEscaped() {
        let html = build(metadata: PrintDocumentMetadata(title: "Tom & <script>alert(1)</script>"))

        #expect(html.contains("Tom &amp; &lt;script&gt;"))
        #expect(!html.contains("<h1 class=\"doc-title\">Tom & <script>"))
    }

    // MARK: - Print colors

    @Test("print colors stay light no matter which reader theme is set")
    func printColorsIgnoreReaderTheme() {
        for theme in ReaderColorTheme.allCases {
            var settings = Settings()
            settings.readerColorTheme = theme
            settings.customBackgroundColor = "#000000"
            settings.customTextColor = "#00FF00"

            let html = PrintHTMLDocumentBuilder.build(
                metadata: PrintDocumentMetadata(title: "T"),
                articleHTML: "<p>Body</p>",
                style: PrintDocumentStyle.resolve(settings: settings)
            )

            #expect(html.contains("--print-text: #1a1a1a;"), "theme \(theme.rawValue)")
            #expect(html.contains("background: #ffffff;"), "theme \(theme.rawValue)")
            #expect(!html.contains("#00FF00"), "theme \(theme.rawValue)")
            #expect(html.contains("<meta name=\"color-scheme\" content=\"light\">"), "theme \(theme.rawValue)")
        }
    }

    // MARK: - Typography

    @Test("typography follows the reader font and line height, not its font size")
    func typographyFollowsSettings() {
        var settings = Settings()
        settings.fontFamily = .monospace
        settings.lineHeight = 1.9
        settings.fontSizeNumeric = 30

        let resolved = PrintDocumentStyle.resolve(settings: settings)
        let html = PrintHTMLDocumentBuilder.build(
            metadata: PrintDocumentMetadata(title: "T"),
            articleHTML: "<p>Body</p>",
            style: resolved
        )

        #expect(resolved.lineHeight == 1.9)
        #expect(html.contains("line-height: 1.9;"))
        #expect(html.contains("--font-family: \(resolved.fontStackCSS);"))
        #expect(html.contains("--base-font-size: \(PrintDocumentStyle.baseFontSizePoints)pt;"))
        #expect(!html.contains("30px"))
    }

    @Test("resolve falls back to the reader defaults when there are no settings")
    func resolveWithoutSettings() {
        let resolved = PrintDocumentStyle.resolve(settings: nil)

        #expect(resolved.lineHeight == 1.4)
        #expect(!resolved.fontStackCSS.isEmpty)
    }

    // MARK: - Annotations

    @Test("annotations get static CSS so the highlights survive without JavaScript")
    func annotationCSSIsStatic() {
        let html = build()

        #expect(html.contains("rd-annotation {"))
        for color in AnnotationColor.allCases {
            #expect(html.contains("rd-annotation[data-annotation-color=\"\(color.rawValue)\"]"))
            #expect(html.contains(color.cssColorWithOpacity(0.35)))
        }
        // WebKit drops backgrounds while laying out for print unless told otherwise
        #expect(html.contains("print-color-adjust: exact;"))
    }

    @Test("annotation markup from the article is preserved")
    func annotationMarkupIsKept() {
        let html = build(articleHTML: "<p><rd-annotation data-annotation-color=\"green\">kept</rd-annotation></p>")

        #expect(html.contains("<rd-annotation data-annotation-color=\"green\">kept</rd-annotation>"))
    }

    // MARK: - Article sanitizing

    @Test("scripts, styles and inline handlers are removed from the article")
    func articleIsSanitized() {
        let html = build(articleHTML: """
        <p onclick="steal()">Text</p>
        <script>alert(1)</script>
        <style>body { color: red }</style>
        <img src="data:image/png;base64,AAA" alt="pic">
        """)

        #expect(html.contains("<p>Text</p>"))
        #expect(!html.contains("alert(1)"))
        #expect(!html.contains("color: red"))
        #expect(!html.contains("onclick"))
        // Images have to stay, they are the point of a PDF export
        #expect(html.contains("<img src=\"data:image/png;base64,AAA\" alt=\"pic\">"))
    }

    @Test("document keeps a page margin on every page")
    func documentDeclaresPageMargin() {
        let html = build()

        #expect(PrintHTMLDocumentBuilder.pageMarginPoints > 0)
        #expect(html.contains("margin: \(Int(PrintHTMLDocumentBuilder.pageMarginPoints))pt;"))
    }
}
