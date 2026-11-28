import Foundation

/// How "Send by Email" is carried out.
enum EmailShareMode: Equatable {
    case server
    case localDraft
}

/// A mail the user finishes in their own mail app.
struct MailDraft: Equatable {
    let subject: String
    let body: String

    /// Fallback for devices without a configured Mail account.
    var mailtoURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}
