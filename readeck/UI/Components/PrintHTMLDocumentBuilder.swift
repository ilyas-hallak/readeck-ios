//
//  PrintHTMLDocumentBuilder.swift
//  readeck
//
//  Builds the self-contained HTML document that the PDF export renders. It is
//  deliberately separate from the reader templates in `WebView`/`NativeWebView`:
//  a PDF ends up on white paper, so it keeps the user's typography but drops the
//  reader color theme, the screen margins and every piece of interactive script.
//

import Foundation

/// The article header that is rendered into the document, since the reader shows
/// this metadata natively and it is not part of the article HTML.
struct PrintDocumentMetadata: Equatable {
    let title: String
    let authors: [String]
    /// Already formatted for display; empty when the bookmark has no usable date.
    let formattedDate: String
    let sourceURL: String

    init(title: String, authors: [String] = [], formattedDate: String = "", sourceURL: String = "") {
        self.title = title
        self.authors = authors
        self.formattedDate = formattedDate
        self.sourceURL = sourceURL
    }
}

/// The parts of the reader settings that carry over to paper. Colors are missing on
/// purpose, the print document is always dark text on white.
struct PrintDocumentStyle: Equatable {
    let fontFaceCSS: String
    let fontStackCSS: String
    let lineHeight: Double

    /// Body size in points. Fixed instead of taken from the reader, whose size is
    /// tuned for a phone screen and reads far too large on a printed page.
    static let baseFontSizePoints = 11

    static func resolve(settings: Settings?) -> Self {
        let fontCSS = ReaderFontCSSBuilder.build(fontFamily: settings?.fontFamily ?? .serif)
        return Self(
            fontFaceCSS: fontCSS.fontFaceCSS,
            fontStackCSS: fontCSS.fontStackCSS,
            lineHeight: settings?.lineHeight ?? 1.4
        )
    }
}

enum PrintHTMLDocumentBuilder {

    /// Point size of the paper margin. The renderer insets the printable rect by the
    /// same amount, so every page keeps the margin, not just the first and last one.
    static let pageMarginPoints: Double = 48

    static func build(
        metadata: PrintDocumentMetadata,
        articleHTML: String,
        style: PrintDocumentStyle
    ) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="color-scheme" content="light">
            <title>\(escape(metadata.title))</title>
            <style>
        \(styleSheet(style: style))
            </style>
        </head>
        <body>
        \(header(metadata: metadata))
            <main class="article">
        \(sanitize(articleHTML))
            </main>
        </body>
        </html>
        """
    }

    // MARK: - Header

    private static func header(metadata: PrintDocumentMetadata) -> String {
        var rows: [String] = []

        if !metadata.title.isEmpty {
            rows.append("        <h1 class=\"doc-title\">\(escape(metadata.title))</h1>")
        }

        let authors = metadata.authors.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if !authors.isEmpty {
            rows.append("        <p class=\"doc-authors\">\(escape(authors.joined(separator: ", ")))</p>")
        }

        if !metadata.formattedDate.isEmpty {
            rows.append("        <p class=\"doc-date\">\(escape(metadata.formattedDate))</p>")
        }

        if !metadata.sourceURL.isEmpty {
            rows.append("        <p class=\"doc-source\">\(escape(metadata.sourceURL))</p>")
        }

        guard !rows.isEmpty else { return "" }

        return """
            <header class="doc-header">
        \(rows.joined(separator: "\n"))
            </header>
        """
    }

    // MARK: - Stylesheet

    private static func styleSheet(style: PrintDocumentStyle) -> String {
        let fontSize = PrintDocumentStyle.baseFontSizePoints

        return """
        \(style.fontFaceCSS)

        :root {
            --print-text: #1a1a1a;
            --print-muted: #595959;
            --print-rule: #c8c8c8;
            --print-surface: #f2f2f2;
            --base-font-size: \(fontSize)pt;
            --font-family: \(style.fontStackCSS);
        }

        /* Keep the highlight and code backgrounds when WebKit lays the page out for
           print, which otherwise drops every background color. */
        * {
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }

        @page {
            margin: \(Int(pageMarginPoints))pt;
        }

        html, body {
            background: #ffffff;
        }

        body {
            margin: 0;
            padding: 0;
            color: var(--print-text);
            font-family: var(--font-family);
            font-size: var(--base-font-size);
            line-height: \(style.lineHeight);
            -webkit-text-size-adjust: none;
        }

        body, p, li, td, th, blockquote, h1, h2, h3, h4, h5, h6, span, div, a {
            font-family: var(--font-family);
        }

        /* Header */

        .doc-header {
            margin: 0 0 20pt;
            padding-bottom: 12pt;
            border-bottom: 1px solid var(--print-rule);
        }

        .doc-title {
            margin: 0 0 8pt;
            font-size: calc(var(--base-font-size) * 1.8);
            line-height: 1.2;
            font-weight: 600;
        }

        .doc-authors,
        .doc-date,
        .doc-source {
            margin: 0 0 3pt;
            font-size: calc(var(--base-font-size) * 0.85);
            color: var(--print-muted);
        }

        .doc-source {
            word-break: break-all;
        }

        /* Article */

        .article h1, .article h2, .article h3,
        .article h4, .article h5, .article h6 {
            margin: 18pt 0 8pt;
            line-height: 1.25;
            font-weight: 600;
            break-after: avoid;
            page-break-after: avoid;
        }

        .article h1 { font-size: calc(var(--base-font-size) * 1.5); }
        .article h2 { font-size: calc(var(--base-font-size) * 1.3); }
        .article h3 { font-size: calc(var(--base-font-size) * 1.15); }
        .article h4, .article h5, .article h6 { font-size: var(--base-font-size); }

        p {
            margin: 0 0 10pt;
            orphans: 2;
            widows: 2;
        }

        a {
            color: var(--print-text);
            text-decoration: underline;
        }

        img, figure, svg, video {
            max-width: 100%;
            height: auto;
            break-inside: avoid;
            page-break-inside: avoid;
        }

        figure {
            margin: 12pt 0;
        }

        figcaption {
            margin-top: 4pt;
            font-size: calc(var(--base-font-size) * 0.8);
            color: var(--print-muted);
        }

        blockquote {
            margin: 12pt 0;
            padding: 0 0 0 12pt;
            border-left: 2px solid var(--print-rule);
            color: var(--print-muted);
            font-style: italic;
        }

        code, pre, kbd, samp {
            font-family: 'SF Mono', Menlo, Monaco, Consolas, monospace;
        }

        code {
            padding: 1pt 3pt;
            background: var(--print-surface);
            font-size: calc(var(--base-font-size) * 0.9);
        }

        pre {
            padding: 8pt;
            background: var(--print-surface);
            border: 1px solid var(--print-rule);
            font-size: calc(var(--base-font-size) * 0.85);
            white-space: pre-wrap;
            word-wrap: break-word;
            break-inside: avoid;
            page-break-inside: avoid;
        }

        pre code {
            padding: 0;
            background: none;
        }

        hr {
            margin: 16pt 0;
            border: none;
            border-top: 1px solid var(--print-rule);
        }

        table {
            width: 100%;
            margin: 12pt 0;
            border-collapse: collapse;
            font-size: calc(var(--base-font-size) * 0.9);
        }

        th, td {
            padding: 4pt 6pt;
            border: 1px solid var(--print-rule);
            text-align: left;
        }

        th {
            background: var(--print-surface);
        }

        ul, ol {
            margin: 0 0 10pt;
            padding-left: 18pt;
        }

        li {
            margin-bottom: 3pt;
        }

        /* Annotations. The reader tints these from JavaScript; on paper they have to
           survive as plain CSS or the highlights are lost. */
        rd-annotation {
            display: inline;
            padding: 1pt 0;
            -webkit-box-decoration-break: clone;
            box-decoration-break: clone;
            background-color: \(AnnotationColor.yellow.cssColorWithOpacity(0.35));
        }

        \(AnnotationColor.allCases.map(annotationRule).joined(separator: "\n"))
        """
    }

    private static func annotationRule(for color: AnnotationColor) -> String {
        "rd-annotation[data-annotation-color=\"\(color.rawValue)\"] { background-color: \(color.cssColorWithOpacity(0.35)); }"
    }

    // MARK: - Helpers

    /// Drops the parts of the article HTML that make no sense on paper. The reader
    /// content is server-sanitized already, so this only has to remove behaviour.
    private static func sanitize(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+on[a-zA-Z]+="[^"]*""#, with: "", options: .regularExpression)
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
