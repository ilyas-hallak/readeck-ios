//
//  BookmarkSyncRequestBody.swift
//  readeck
//

struct BookmarkSyncRequestBody: Encodable {
    let id: [String]
    let withJson: Bool
    let withHtml: Bool
    let withResources: Bool
    let resourcePrefix: String

    // The API expects snake_case, the encoder runs without a key strategy.
    enum CodingKeys: String, CodingKey {
        case id
        case withJson = "with_json"
        case withHtml = "with_html"
        case withResources = "with_resources"
        case resourcePrefix = "resource_prefix"
    }

    init(bookmarkId: String) {
        id = [bookmarkId]
        withJson = false
        withHtml = true
        withResources = false
        resourcePrefix = "."
    }
}
