//
//  BookmarkArticleGETOutcome.swift
//  readeck
//

enum BookmarkArticleGETOutcome {
    case success(String)
    /// Gateway/upstream error where the origin is likely reachable but the proxy failed to
    /// relay a large or slow article response. Recoverable via the streaming sync fallback.
    case gatewayError(statusCode: Int)
    case httpFailure(statusCode: Int)
}
