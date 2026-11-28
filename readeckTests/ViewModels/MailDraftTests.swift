import Foundation
import Testing
@testable import readeck

struct MailDraftTests {
    @Test("The mailto URL encodes subject and body")
    func mailtoURLEncodesFields() throws {
        let draft = MailDraft(subject: "Rock & Roll?", body: "https://example.com/a?b=1&c=2")

        let url = try #require(draft.mailtoURL)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        #expect(url.scheme == "mailto")
        #expect(items?.first { $0.name == "subject" }?.value == "Rock & Roll?")
        #expect(items?.first { $0.name == "body" }?.value == "https://example.com/a?b=1&c=2")
    }
}
