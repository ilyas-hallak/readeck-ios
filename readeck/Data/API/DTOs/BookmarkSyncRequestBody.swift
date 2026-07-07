//
//  BookmarkSyncRequestBody.swift
//  readeck
//

struct BookmarkSyncRequestBody: Encodable {
    let id: [String]
    let with_json: Bool
    let with_html: Bool
    let with_resources: Bool
    let resource_prefix: String

    init(bookmarkId: String) {
        id = [bookmarkId]
        with_json = false
        with_html = true
        with_resources = false
        resource_prefix = "."
    }
}
