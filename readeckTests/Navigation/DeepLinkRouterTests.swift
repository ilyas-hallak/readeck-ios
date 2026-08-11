import Testing
import Foundation
@testable import readeck

@Suite("DeepLinkRouter")
struct DeepLinkRouterTests {

    @Test("Parses readeck://bookmark/{id} and opens the reader")
    func handlesBookmarkDeepLink() {
        let router = DeepLinkRouter()
        let handled = router.handle(url: URL(string: "readeck://bookmark/abc123")!)
        #expect(handled == true)
        #expect(router.openedBookmark == DeepLinkedBookmark(id: "abc123"))
    }

    @Test("Scheme is matched case-insensitively")
    func handlesUppercaseScheme() {
        let router = DeepLinkRouter()
        let handled = router.handle(url: URL(string: "Readeck://Bookmark/xyz")!)
        #expect(handled == true)
        #expect(router.openedBookmark?.id == "xyz")
    }

    @Test("Ignores non-bookmark hosts (e.g. OAuth callbacks)")
    func ignoresOtherHosts() {
        let router = DeepLinkRouter()
        let handled = router.handle(url: URL(string: "readeck://oauth/callback?code=1")!)
        #expect(handled == false)
        #expect(router.openedBookmark == nil)
    }

    @Test("Ignores a missing bookmark id")
    func ignoresMissingId() {
        let router = DeepLinkRouter()
        let handled = router.handle(url: URL(string: "readeck://bookmark")!)
        #expect(handled == false)
        #expect(router.openedBookmark == nil)
    }

    @Test("Ignores foreign schemes")
    func ignoresForeignScheme() {
        let router = DeepLinkRouter()
        let handled = router.handle(url: URL(string: "https://bookmark/abc")!)
        #expect(handled == false)
        #expect(router.openedBookmark == nil)
    }
}
