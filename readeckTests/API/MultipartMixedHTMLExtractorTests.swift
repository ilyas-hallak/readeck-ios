//
//  MultipartMixedHTMLExtractorTests.swift
//  readeckTests
//

import XCTest
@testable import readeck

final class MultipartMixedHTMLExtractorTests: XCTestCase {

    func testParseBoundaryQuoted() {
        let ct = #"multipart/mixed; boundary="abc-123""#
        XCTAssertEqual(MultipartMixedHTMLExtractor.parseBoundary(from: ct), "abc-123")
    }

    func testParseBoundaryUnquoted() {
        let ct = "multipart/mixed; boundary=xyz9"
        XCTAssertEqual(MultipartMixedHTMLExtractor.parseBoundary(from: ct), "xyz9")
    }

    func testExtractHTMLPart_skipsJsonThenReturnsHtml() throws {
        let boundary = "bnd"
        let raw = [
            "--\(boundary)",
            "Type: json",
            "Bookmark-Id: other",
            "",
            "{}",
            "--\(boundary)",
            "Type: html",
            "Bookmark-Id: targetId",
            "",
            "<p>hello</p>",
            "--\(boundary)--",
            ""
        ].joined(separator: "\r\n")
        let html = try MultipartMixedHTMLExtractor.extractHTML(
            data: Data(raw.utf8),
            contentTypeValue: "multipart/mixed; boundary=\(boundary)",
            bookmarkId: "targetId"
        )
        XCTAssertEqual(html, "<p>hello</p>")
    }
}
