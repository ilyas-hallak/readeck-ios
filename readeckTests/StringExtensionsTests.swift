import Testing
@testable import readeck

@Suite("String Extensions Tests")
struct StringExtensionsTests {

    // MARK: - stripHTML Tests

    @Test("Strip HTML simple tags")
    func stripHTML_SimpleTags() {
        let html = "<p>Dies ist ein <strong>wichtiger</strong> Artikel.</p>"
        let expected = "Dies ist ein wichtiger Artikel.\n"

        #expect(html.stripHTML == expected)
    }

    @Test("Strip HTML complex nested tags")
    func stripHTML_ComplexNestedTags() {
        let html = "<div><h1>Titel</h1><p>Text mit <em>kursiv</em> und <strong>fett</strong>.</p></div>"
        let expected = "Titel\nText mit kursiv und fett.\n"

        #expect(html.stripHTML == expected)
    }

    @Test("Strip HTML with attributes")
    func stripHTML_WithAttributes() {
        let html = "<p class=\"important\" id=\"main\">Text mit Attributen</p>"
        let expected = "Text mit Attributen\n"

        #expect(html.stripHTML == expected)
    }

    @Test("Strip HTML empty tags")
    func stripHTML_EmptyTags() {
        let html = "<p></p><div>Inhalt</div><span></span>"
        let expected = "\nInhalt\n"

        #expect(html.stripHTML == expected)
    }

    @Test("Strip HTML self-closing tags")
    func stripHTML_SelfClosingTags() {
        let html = "<p>Text mit <br>Zeilenumbruch und <img src=\"test.jpg\"> Bild.</p>"
        let expected = "Text mit \u{2028}Zeilenumbruch und Bild.\n"

        #expect(html.stripHTML == expected)
    }

    @Test("Strip HTML no tags")
    func stripHTML_NoTags() {
        let plainText = "Dies ist normaler Text ohne HTML."

        #expect(plainText.stripHTML == plainText)
    }

    @Test("Strip HTML empty string")
    func stripHTML_EmptyString() {
        let emptyString = ""

        #expect(emptyString.stripHTML == emptyString)
    }

    @Test("Strip HTML only tags")
    func stripHTML_OnlyTags() {
        let onlyTags = "<p><div><span></span></div></p>"
        let expected = "\n\n\n"

        #expect(onlyTags.stripHTML == expected)
    }

    // MARK: - Edge Cases

    @Test("Strip HTML malformed HTML")
    func stripHTML_MalformedHTML() {
        let malformed = "<p>Unvollständiger <strong>Tag"
        let expected = "Unvollständiger Tag\n"

        #expect(malformed.stripHTML == expected)
    }

    @Test("Strip HTML Unicode characters")
    func stripHTML_UnicodeCharacters() {
        let html = "<p>Text mit Umlauten: äöüß und Emojis: 🚀📱</p>"
        let expected = "Text mit Umlauten: äöüß und Emojis: 🚀📱\n"

        #expect(html.stripHTML == expected)
    }

    @Test("Strip HTML newlines")
    func stripHTML_Newlines() {
        let html = "<p>Erste Zeile<br>Zweite Zeile</p>"
        let expected = "Erste Zeile\u{2028}Zweite Zeile\n"

        #expect(html.stripHTML == expected)
    }

    @Test("Strip HTML list items")
    func stripHTML_ListItems() {
        let html = "<ul><li>Erster Punkt</li><li>Zweiter Punkt</li><li>Dritter Punkt</li></ul>"
        let expected = "Erster Punkt\nZweiter Punkt\nDritter Punkt\n"

        #expect(html.stripHTML == expected)
    }
}
