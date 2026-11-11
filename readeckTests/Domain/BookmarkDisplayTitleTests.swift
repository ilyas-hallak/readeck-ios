import Testing
@testable import readeck

@Suite("BookmarkDisplayTitle Tests")
struct BookmarkDisplayTitleTests {

    @Test("Uses the title when there is one")
    func usesTitle() {
        let title = BookmarkDisplayTitle.make(title: "Go 1.22", siteName: "go.dev", url: "https://go.dev/blog")
        #expect(title == "Go 1.22")
    }

    @Test("Falls back to the site name without www")
    func fallsBackToSiteName() {
        let title = BookmarkDisplayTitle.make(title: " ", siteName: "www.maz-online.de", url: "https://www.maz-online.de/a")
        #expect(title == "maz-online.de")
    }

    @Test("Falls back to the URL host without www when there is no site name")
    func fallsBackToHost() {
        let title = BookmarkDisplayTitle.make(title: "", siteName: "", url: "https://www.maz-online.de/lokales/a.html")
        #expect(title == "maz-online.de")
    }

    @Test("Falls back to the raw URL when it has no host")
    func fallsBackToURL() {
        let title = BookmarkDisplayTitle.make(title: "", siteName: "", url: "not a url")
        #expect(title == "not a url")
    }
}
