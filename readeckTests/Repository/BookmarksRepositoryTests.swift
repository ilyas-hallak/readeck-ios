//
//  BookmarksRepositoryTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation
@testable import readeck

@Suite("BookmarksRepository Tests")
struct BookmarksRepositoryTests {

    // MARK: - fetchBookmarks / DTO → Domain

    @Test("fetchBookmarks maps the page and all bookmark fields to the domain model")
    func fetchBookmarksMapsToDomain() async throws {
        let api = StubAPI()
        api.getBookmarksHandler = { _, _, _, _, _, _, _ in
            DtoFixture.page(
                bookmarks: [DtoFixture.bookmark(id: "a", title: "First", labels: ["swift"], isMarked: true)],
                currentPage: 2,
                totalCount: 42,
                totalPages: 5
            )
        }
        let repository = BookmarksRepository(api: api)

        let page = try await repository.fetchBookmarks()

        #expect(page.currentPage == 2)
        #expect(page.totalCount == 42)
        #expect(page.totalPages == 5)
        #expect(page.bookmarks.count == 1)

        let bookmark = try #require(page.bookmarks.first)
        #expect(bookmark.id == "a")
        #expect(bookmark.title == "First")
        #expect(bookmark.url == "https://example.com/a")
        #expect(bookmark.labels == ["swift"])
        #expect(bookmark.isMarked == true)
        #expect(bookmark.isArchived == false)
        #expect(bookmark.readingTime == 5)
        #expect(bookmark.wordCount == 1000)
        // Verschachteltes Resource-Mapping
        #expect(bookmark.resources.article?.src == "https://example.com/a/article")
        #expect(bookmark.resources.thumbnail?.src == "https://example.com/a/thumb.jpg")
        #expect(bookmark.resources.image?.width == 800)
        #expect(bookmark.resources.icon == nil)
    }

    @Test("fetchBookmarks forwards its filter arguments to the API unchanged")
    func fetchBookmarksForwardsArguments() async throws {
        let api = StubAPI()
        var received: (state: BookmarkState?, limit: Int?, offset: Int?, search: String?, tag: String?, sort: String?)?
        api.getBookmarksHandler = { state, limit, offset, search, _, tag, sort in
            received = (state, limit, offset, search, tag, sort)
            return DtoFixture.page(bookmarks: [])
        }
        let repository = BookmarksRepository(api: api)

        _ = try await repository.fetchBookmarks(
            state: .unread, limit: 10, offset: 20, search: "swift", type: nil, tag: "ios", sort: "-created"
        )

        #expect(received?.state == .unread)
        #expect(received?.limit == 10)
        #expect(received?.offset == 20)
        #expect(received?.search == "swift")
        #expect(received?.tag == "ios")
        #expect(received?.sort == "-created")
    }

    @Test("fetchBookmarks propagates API errors")
    func fetchBookmarksPropagatesError() async throws {
        let api = StubAPI()
        api.getBookmarksHandler = { _, _, _, _, _, _, _ in throw APIError.serverError(500) }
        let repository = BookmarksRepository(api: api)

        await #expect(throws: APIError.serverError(500)) {
            _ = try await repository.fetchBookmarks()
        }
    }

    // MARK: - fetchBookmark

    @Test("fetchBookmark maps the detail, flattening resource URLs")
    func fetchBookmarkMapsDetail() async throws {
        let api = StubAPI()
        api.getBookmarkHandler = { id in DtoFixture.bookmark(id: id, title: "Detail", labels: ["a", "b"]) }
        let repository = BookmarksRepository(api: api)

        let detail = try await repository.fetchBookmark(id: "bm42")

        #expect(detail.id == "bm42")
        #expect(detail.title == "Detail")
        #expect(detail.labels == ["a", "b"])
        #expect(detail.thumbnailUrl == "https://example.com/bm42/thumb.jpg")
        #expect(detail.imageUrl == "https://example.com/bm42/image.jpg")
        #expect(detail.lang == "en")
        #expect(detail.hasArticle == true)
    }

    // MARK: - createBookmark

    @Test("createBookmark returns the message on an accepted status", arguments: [0, 202])
    func createBookmarkSuccess(status: Int) async throws {
        let api = StubAPI()
        api.createBookmarkHandler = { _ in CreateBookmarkResponseDto(message: "new-id", status: status) }
        let repository = BookmarksRepository(api: api)

        let id = try await repository.createBookmark(
            createRequest: CreateBookmarkRequest(url: "https://example.com", title: "T", labels: ["x"])
        )

        #expect(id == "new-id")
        #expect(api.createBookmarkCalls.count == 1)
        #expect(api.createBookmarkCalls[0].url == "https://example.com")
        #expect(api.createBookmarkCalls[0].labels == ["x"])
    }

    @Test("createBookmark throws a serverError on an unexpected status")
    func createBookmarkRejectsUnexpectedStatus() async throws {
        let api = StubAPI()
        api.createBookmarkHandler = { _ in CreateBookmarkResponseDto(message: "nope", status: 500) }
        let repository = BookmarksRepository(api: api)

        await #expect(throws: CreateBookmarkError.self) {
            _ = try await repository.createBookmark(
                createRequest: CreateBookmarkRequest(url: "https://example.com", title: nil, labels: nil)
            )
        }
    }

    // MARK: - update / delete

    @Test("updateBookmark passes the id and maps the request to its DTO")
    func updateBookmarkMapsRequest() async throws {
        let api = StubAPI()
        api.updateBookmarkHandler = { _, _ in }
        let repository = BookmarksRepository(api: api)

        try await repository.updateBookmark(
            id: "bm1",
            updateRequest: BookmarkUpdateRequest(isArchived: true, isMarked: false, readProgress: 80)
        )

        #expect(api.updateBookmarkCalls.count == 1)
        #expect(api.updateBookmarkCalls[0].0 == "bm1")
        #expect(api.updateBookmarkCalls[0].1.isArchived == true)
        #expect(api.updateBookmarkCalls[0].1.isMarked == false)
        #expect(api.updateBookmarkCalls[0].1.readProgress == 80)
    }

    @Test("deleteBookmark forwards the id")
    func deleteBookmarkForwardsId() async throws {
        let api = StubAPI()
        api.deleteBookmarkHandler = { _ in }
        let repository = BookmarksRepository(api: api)

        try await repository.deleteBookmark(id: "bm9")

        #expect(api.deleteBookmarkCalls == ["bm9"])
    }

    // MARK: - searchBookmarks

    @Test("searchBookmarks maps results to the domain model")
    func searchBookmarksMapsResults() async throws {
        let api = StubAPI()
        api.searchBookmarksHandler = { term in
            DtoFixture.page(bookmarks: [DtoFixture.bookmark(id: "s1", title: "Found \(term)")])
        }
        let repository = BookmarksRepository(api: api)

        let page = try await repository.searchBookmarks(search: "swift")

        #expect(page.bookmarks.count == 1)
        #expect(page.bookmarks.first?.title == "Found swift")
    }
}
