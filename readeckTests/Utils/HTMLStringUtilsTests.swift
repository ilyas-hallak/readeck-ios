import Testing
import Foundation
@testable import readeck

@Suite("HTMLStringUtils Tests")
struct HTMLStringUtilsTests {

    @Test("stripHTML removes tags and returns plain text")
    func stripHTMLRemovesTags() {
        let html = "<p>Hello <strong>world</strong></p>"
        let result = HTMLStringUtils.stripHTML(html)
        #expect(result.contains("Hello"))
        #expect(result.contains("world"))
        #expect(!result.contains("<p>"))
        #expect(!result.contains("<strong>"))
    }

    @Test("stripHTML handles empty string")
    func stripHTMLEmpty() {
        let result = HTMLStringUtils.stripHTML("")
        #expect(result.isEmpty)
    }

    @Test("splitIntoChunks returns single chunk for short text")
    func splitShortText() {
        let chunks = HTMLStringUtils.splitIntoChunks(text: "Short text.")
        #expect(chunks.count == 1)
        #expect(chunks[0] == "Short text.")
    }

    @Test("splitIntoChunks splits at paragraph boundaries")
    func splitAtParagraphs() {
        let paragraph = String(repeating: "word ", count: 2000)
        let text = paragraph + "\n\n" + paragraph
        let chunks = HTMLStringUtils.splitIntoChunks(text: text)
        #expect(chunks.count == 2)
    }

    @Test("splitIntoChunks handles empty text")
    func splitEmptyText() {
        let chunks = HTMLStringUtils.splitIntoChunks(text: "")
        #expect(chunks.isEmpty)
    }

    @Test("stripHTML decodes HTML entities")
    func stripHTMLEntities() {
        let html = "Tom &amp; Jerry &lt;3&gt;"
        let result = HTMLStringUtils.stripHTML(html)
        #expect(result == "Tom & Jerry <3>")
    }

    @Test("splitIntoChunks respects custom max characters")
    func splitCustomMax() {
        let text = "Hello\n\nWorld\n\nFoo"
        let chunks = HTMLStringUtils.splitIntoChunks(text: text, maxCharacters: 8)
        #expect(chunks.count == 3)
    }
}
