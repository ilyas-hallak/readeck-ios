//
//  BookmarkArticleGETOutcome.swift
//  readeck
//

enum BookmarkArticleGETOutcome {
    case success(String)
    case badGateway
    case httpFailure(statusCode: Int)
}
