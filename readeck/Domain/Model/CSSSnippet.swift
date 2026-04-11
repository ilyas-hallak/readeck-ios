//
//  CSSSnippet.swift
//  readeck
//

import Foundation

enum CSSSnippetCategory: String, CaseIterable {
    case typography
    case colors
    case layout
    case visibility

    var titleKey: String {
        switch self {
        case .typography: return "css.help.category.typography"
        case .colors: return "css.help.category.colors"
        case .layout: return "css.help.category.layout"
        case .visibility: return "css.help.category.visibility"
        }
    }

    var iconName: String {
        switch self {
        case .typography: return "textformat.size"
        case .colors: return "paintpalette"
        case .layout: return "rectangle.split.3x1"
        case .visibility: return "eye.slash"
        }
    }
}

struct CSSSnippet: Identifiable {
    let id = UUID()
    let titleKey: String
    let descriptionKey: String
    let code: String
    let category: CSSSnippetCategory
}

extension CSSSnippet {
    static let all: [CSSSnippet] = [
        // MARK: - Typography
        CSSSnippet(
            titleKey: "css.snippet.fontSize.title",
            descriptionKey: "css.snippet.fontSize.description",
            code: "body { font-size: 20px; }",
            category: .typography
        ),
        CSSSnippet(
            titleKey: "css.snippet.lineHeight.title",
            descriptionKey: "css.snippet.lineHeight.description",
            code: "body { line-height: 2.0; }",
            category: .typography
        ),
        CSSSnippet(
            titleKey: "css.snippet.headingsSmaller.title",
            descriptionKey: "css.snippet.headingsSmaller.description",
            code: "h1, h2, h3 { font-size: calc(var(--base-font-size) * 1.1); }",
            category: .typography
        ),
        CSSSnippet(
            titleKey: "css.snippet.boldParagraphs.title",
            descriptionKey: "css.snippet.boldParagraphs.description",
            code: "p { font-weight: 500; }",
            category: .typography
        ),

        // MARK: - Colors
        CSSSnippet(
            titleKey: "css.snippet.sepia.title",
            descriptionKey: "css.snippet.sepia.description",
            code: ":root { --background-color: #f4ecd8; --text-color: #5b4636; }",
            category: .colors
        ),
        CSSSnippet(
            titleKey: "css.snippet.linkColor.title",
            descriptionKey: "css.snippet.linkColor.description",
            code: ":root { --link-color: #e74c3c; }",
            category: .colors
        ),
        CSSSnippet(
            titleKey: "css.snippet.headingColor.title",
            descriptionKey: "css.snippet.headingColor.description",
            code: ":root { --heading-color: #2c3e50; }",
            category: .colors
        ),
        CSSSnippet(
            titleKey: "css.snippet.quoteColor.title",
            descriptionKey: "css.snippet.quoteColor.description",
            code: ":root { --quote-color: #888888; --quote-border: #cccccc; }",
            category: .colors
        ),

        // MARK: - Layout
        CSSSnippet(
            titleKey: "css.snippet.marginsSmall.title",
            descriptionKey: "css.snippet.marginsSmall.description",
            code: "body { padding-left: 8px; padding-right: 8px; }",
            category: .layout
        ),
        CSSSnippet(
            titleKey: "css.snippet.marginsLarge.title",
            descriptionKey: "css.snippet.marginsLarge.description",
            code: "body { padding-left: 32px; padding-right: 32px; }",
            category: .layout
        ),
        CSSSnippet(
            titleKey: "css.snippet.imagesSmaller.title",
            descriptionKey: "css.snippet.imagesSmaller.description",
            code: "img { max-width: 60%; margin: 8px auto; display: block; }",
            category: .layout
        ),
        CSSSnippet(
            titleKey: "css.snippet.paragraphSpacing.title",
            descriptionKey: "css.snippet.paragraphSpacing.description",
            code: "p { margin-bottom: 8px; }",
            category: .layout
        ),

        // MARK: - Visibility
        CSSSnippet(
            titleKey: "css.snippet.hideImages.title",
            descriptionKey: "css.snippet.hideImages.description",
            code: "img { display: none; }",
            category: .visibility
        ),
        CSSSnippet(
            titleKey: "css.snippet.hideHR.title",
            descriptionKey: "css.snippet.hideHR.description",
            code: "hr { display: none; }",
            category: .visibility
        ),
        CSSSnippet(
            titleKey: "css.snippet.linksPlain.title",
            descriptionKey: "css.snippet.linksPlain.description",
            code: "a { text-decoration: none !important; }",
            category: .visibility
        ),
        CSSSnippet(
            titleKey: "css.snippet.blockquotePlain.title",
            descriptionKey: "css.snippet.blockquotePlain.description",
            code: "blockquote { border: none; background: none; padding: 0; font-style: normal; }",
            category: .visibility
        ),
    ]

    static func snippets(for category: CSSSnippetCategory) -> [CSSSnippet] {
        all.filter { $0.category == category }
    }
}
