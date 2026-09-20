//
//  ArticleHTMLSanitizerTests.swift
//  readeckTests
//

import Testing
import Foundation
@testable import readeck

@Suite("ArticleHTMLSanitizer Tests")
struct ArticleHTMLSanitizerTests {

    @Test("Removes Google jsaction attributes that trigger navigation events")
    func removesJsaction() {
        let html = #"<div jsaction="click:abc.def">Text</div>"#
        #expect(ArticleHTMLSanitizer.sanitize(html) == "<div>Text</div>")
    }

    @Test("Removes Google jscontroller attributes")
    func removesJscontroller() {
        let html = #"<div jscontroller="AbCdEf">Text</div>"#
        #expect(ArticleHTMLSanitizer.sanitize(html) == "<div>Text</div>")
    }

    @Test("Removes Google jsname attributes")
    func removesJsname() {
        let html = #"<span jsname="XyZ123">Text</span>"#
        #expect(ArticleHTMLSanitizer.sanitize(html) == "<span>Text</span>")
    }

    @Test("Removes id attributes that bloat the DOM")
    func removesId() {
        let html = #"<p id="para-42">Text</p>"#
        #expect(ArticleHTMLSanitizer.sanitize(html) == "<p>Text</p>")
    }

    @Test("Removes tabindex attributes from non-interactive elements")
    func removesTabindex() {
        let html = #"<div tabindex="0">Text</div>"#
        #expect(ArticleHTMLSanitizer.sanitize(html) == "<div>Text</div>")
    }

    @Test("Removes role=button which causes false click targets")
    func removesRoleButton() {
        let html = #"<figure role="button"><img src="x.png"></figure>"#
        #expect(ArticleHTMLSanitizer.sanitize(html) == "<figure><img src=\"x.png\"></figure>")
    }

    @Test("Fixes invalid <p> tags nested inside <pre><span>")
    func fixesInvalidPreNestedParagraphs() {
        let html = "<pre><span class=\"code\">line one<p>line two</p>line three</span></pre>"
        #expect(ArticleHTMLSanitizer.sanitize(html) == "<pre><span>line one\nline two\nline three</span></pre>")
    }

    @Test("Combines multiple attribute removals and whitespace collapses correctly")
    func combinesMultipleRules() {
        let html = #"<div id="a" jsaction="x" tabindex="0" role="button">Text</div>"#
        #expect(ArticleHTMLSanitizer.sanitize(html) == "<div>Text</div>")
    }

    @Test("Leaves harmless markup untouched")
    func leavesHarmlessMarkupUnchanged() {
        let html = """
        <article>
            <h1>Title</h1>
            <p>Some <strong>bold</strong> text with a <a href="https://example.com">link</a>.</p>
            <img src="https://example.com/image.png" alt="An image">
            <blockquote>A quote</blockquote>
        </article>
        """
        #expect(ArticleHTMLSanitizer.sanitize(html) == html)
    }

    @Test("Keeps ids that the document links to, so footnote jumps still find their target")
    func keepsAnchorTargetIds() {
        let html = ##"""
        <p><a href="#note-1">1</a></p>
        <div id="note-1">The footnote</div>
        """##
        #expect(ArticleHTMLSanitizer.sanitize(html) == html)
    }

    @Test("Keeps a linked id but still drops unlinked ones in the same document")
    func keepsOnlyReferencedIds() {
        let html = ##"<a href="#toc">Top</a><h2 id="toc">Contents</h2><p id="stray">Text</p>"##
        let expected = ##"<a href="#toc">Top</a><h2 id="toc">Contents</h2><p>Text</p>"##
        #expect(ArticleHTMLSanitizer.sanitize(html) == expected)
    }
}
