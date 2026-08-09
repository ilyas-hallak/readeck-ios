//
//  BookmarkListCursorTests.swift
//  readeckTests
//

import Foundation
import Testing
@testable import readeck

@Suite("Bookmark List Cursor")
struct BookmarkListCursorTests {

    @Test("Returns the following bookmark when one exists")
    func nextExists_ReturnsNext() {
        let ids = ["a", "b", "c"]
        #expect(nextSelection(after: "a", in: ids) == .next("b"))
        #expect(nextSelection(after: "b", in: ids) == .next("c"))
    }

    @Test("Clears selection when the archived bookmark was the last one")
    func lastBookmark_ReturnsClear() {
        #expect(nextSelection(after: "c", in: ["a", "b", "c"]) == .clear)
    }

    @Test("No-op when the id is not in the list")
    func idNotInList_ReturnsNoop() {
        #expect(nextSelection(after: "x", in: ["a", "b", "c"]) == .noop)
    }

    @Test("No-op for an empty list")
    func emptyList_ReturnsNoop() {
        #expect(nextSelection(after: "a", in: []) == .noop)
    }

    @Test("Clears selection for a single-element list")
    func singleElement_ReturnsClear() {
        #expect(nextSelection(after: "a", in: ["a"]) == .clear)
    }
}
