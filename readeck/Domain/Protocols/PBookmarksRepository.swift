//
//  PBookmarksRepository.swift
//  readeck
//
//  Created by Ilyas Hallak on 14.07.25.
//

protocol PBookmarksRepository {
    func fetchBookmarks(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?) async throws -> BookmarksPage
    func fetchBookmark(id: String) async throws -> BookmarkDetail
    func fetchBookmarkArticle(id: String) async throws -> String
    func createBookmark(createRequest: CreateBookmarkRequest) async throws -> String
    func updateBookmark(id: String, updateRequest: BookmarkUpdateRequest) async throws
    func deleteBookmark(id: String) async throws
    func searchBookmarks(search: String) async throws -> BookmarksPage
}
