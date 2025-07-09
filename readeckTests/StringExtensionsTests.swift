import XCTest
@testable import readeck

final class StringExtensionsTests: XCTestCase {
    
    // MARK: - stripHTML Tests
    
    func testStripHTML_SimpleTags() {
        let html = "<p>Dies ist ein <strong>wichtiger</strong> Artikel.</p>"
        let expected = "Dies ist ein wichtiger Artikel.\n"
        
        XCTAssertEqual(html.stripHTML, expected)
    }
    
    func testStripHTML_ComplexNestedTags() {
        let html = "<div><h1>Titel</h1><p>Text mit <em>kursiv</em> und <strong>fett</strong>.</p></div>"
        let expected = "Titel\nText mit kursiv und fett."
        
        XCTAssertEqual(html.stripHTML, expected)
    }
    
    func testStripHTML_WithAttributes() {
        let html = "<p class=\"important\" id=\"main\">Text mit Attributen</p>"
        let expected = "Text mit Attributen\n"
        
        XCTAssertEqual(html.stripHTML, expected)
    }
    
    func testStripHTML_EmptyTags() {
        let html = "<p></p><div>Inhalt</div><span></span>"
        let expected = "\nInhalt\n"
        
        XCTAssertEqual(html.stripHTML, expected)
    }
    
    func testStripHTML_SelfClosingTags() {
        let html = "<p>Text mit <br>Zeilenumbruch und <img src=\"test.jpg\"> Bild.</p>"
        let expected = "Text mit \nZeilenumbruch und  Bild.\n"
        
        XCTAssertEqual(html.stripHTML, expected)
    }
    
    func testStripHTML_NoTags() {
        let plainText = "Dies ist normaler Text ohne HTML."
        
        XCTAssertEqual(plainText.stripHTML, plainText)
    }
    
    func testStripHTML_EmptyString() {
        let emptyString = ""
        
        XCTAssertEqual(emptyString.stripHTML, emptyString)
    }
    
    func testStripHTML_OnlyTags() {
        let onlyTags = "<p><div><span></span></div></p>"
        let expected = "\n"
        
        XCTAssertEqual(onlyTags.stripHTML, expected)
    }
    
    // MARK: - stripHTMLSimple Tests
    
    func testStripHTMLSimple_BasicTags() {
        let html = "<p>Text mit <strong>fett</strong>.</p>"
        let expected = "Text mit fett."
        
        XCTAssertEqual(html.stripHTMLSimple, expected)
    }
    
    func testStripHTMLSimple_HTMLEntities() {
        let html = "<p>Text mit &nbsp;Leerzeichen, &amp; Zeichen und &quot;Anführungszeichen&quot;.</p>"
        let expected = "Text mit  Leerzeichen, & Zeichen und \"Anführungszeichen\"."
        
        XCTAssertEqual(html.stripHTMLSimple, expected)
    }
    
    func testStripHTMLSimple_MoreEntities() {
        let html = "<p>&lt;Tag&gt; und &#39;Apostroph&#39;</p>"
        let expected = "<Tag> und 'Apostroph'"
        
        XCTAssertEqual(html.stripHTMLSimple, expected)
    }
    
    func testStripHTMLSimple_ComplexHTML() {
        let html = "<div class=\"container\"><h1>Überschrift</h1><p>Absatz mit <em>kursiv</em> und <strong>fett</strong>.</p><ul><li>Liste 1</li><li>Liste 2</li></ul></div>"
        let expected = "Überschrift\nAbsatz mit kursiv und fett.\nListe 1\nListe 2"
        
        XCTAssertEqual(html.stripHTMLSimple, expected)
    }
    
    func testStripHTMLSimple_NoTags() {
        let plainText = "Normaler Text ohne HTML."
        
        XCTAssertEqual(plainText.stripHTMLSimple, plainText)
    }
    
    func testStripHTMLSimple_EmptyString() {
        let emptyString = ""
        
        XCTAssertEqual(emptyString.stripHTMLSimple, emptyString)
    }
    
    func testStripHTMLSimple_WhitespaceHandling() {
        let html = "   <p>   Text mit   Whitespace   </p>   "
        let expected = "Text mit   Whitespace"
        
        XCTAssertEqual(html.stripHTMLSimple, expected)
    }
    
    // MARK: - Performance Tests
    
    func testStripHTML_Performance() {
        let largeHTML = String(repeating: "<p>Dies ist ein Test mit <strong>vielen</strong> <em>HTML</em> Tags.</p>", count: 1000)
        
        measure {
            _ = largeHTML.stripHTML
        }
    }
    
    func testStripHTMLSimple_Performance() {
        let largeHTML = String(repeating: "<p>Dies ist ein Test mit <strong>vielen</strong> <em>HTML</em> Tags.</p>", count: 1000)
        
        measure {
            _ = largeHTML.stripHTMLSimple
        }
    }
    
    // MARK: - Edge Cases
    
    func testStripHTML_MalformedHTML() {
        let malformed = "<p>Unvollständiger <strong>Tag"
        let expected = "Unvollständiger Tag"
        
        XCTAssertEqual(malformed.stripHTML, expected)
    }
    
    func testStripHTML_UnicodeCharacters() {
        let html = "<p>Text mit Umlauten: äöüß und Emojis: 🚀📱</p>"
        let expected = "Text mit Umlauten: äöüß und Emojis: 🚀📱"
        
        XCTAssertEqual(html.stripHTML, expected)
    }
    
    func testStripHTML_Newlines() {
        let html = "<p>Erste Zeile<br>Zweite Zeile</p>"
        let expected = "Erste Zeile\nZweite Zeile"
        
        XCTAssertEqual(html.stripHTML, expected)
    }
    
    func testStripHTML_ListItems() {
        let html = "<ul><li>Erster Punkt</li><li>Zweiter Punkt</li><li>Dritter Punkt</li></ul>"
        let expected = "Erster Punkt\nZweiter Punkt\nDritter Punkt"
        
        XCTAssertEqual(html.stripHTML, expected)
    }
} 
