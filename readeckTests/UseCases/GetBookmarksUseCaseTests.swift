import Testing
import Foundation
@testable import readeck

@Suite("GetBookmarksUseCase state filter")
struct GetBookmarksUseCaseTests {

    // MARK: - Fakes

    private final class StubBookmarksRepository: PBookmarksRepository {
        var bookmarks: [Bookmark] = []

        // swiftlint:disable:next discouraged_optional_collection
        func fetchBookmarks(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?, sort: String?) async throws -> BookmarksPage {
            BookmarksPage(bookmarks: bookmarks, currentPage: 1, totalCount: bookmarks.count, totalPages: 1, links: nil)
        }

        func fetchBookmark(id: String) async throws -> BookmarkDetail { fatalError("unused") }
        func fetchBookmarkArticle(id: String) async throws -> String { fatalError("unused") }
        func createBookmark(createRequest: CreateBookmarkRequest) async throws -> String { fatalError("unused") }
        func updateBookmark(id: String, updateRequest: BookmarkUpdateRequest) async throws {}
        func deleteBookmark(id: String) async throws {}
        func searchBookmarks(search: String) async throws -> BookmarksPage { fatalError("unused") }
    }

    private func bookmark(id: String, isArchived: Bool = false, isMarked: Bool = false) -> Bookmark {
        Bookmark(
            id: id,
            title: "Title \(id)",
            url: "https://example.com/\(id)",
            href: "https://api.example.com/bookmarks/\(id)",
            description: "",
            authors: [],
            created: "",
            published: nil,
            updated: "",
            siteName: "example.com",
            site: "https://example.com",
            readingTime: 5,
            wordCount: 100,
            hasArticle: true,
            isArchived: isArchived,
            isDeleted: false,
            isMarked: isMarked,
            labels: [],
            lang: "en",
            loaded: true,
            readProgress: 0,
            documentType: "article",
            state: 0,
            textDirection: "ltr",
            type: "article",
            resources: BookmarkResources(article: nil, icon: nil, image: nil, log: nil, props: nil, thumbnail: nil)
        )
    }

    private func makeSUT() -> (GetBookmarksUseCase, StubBookmarksRepository) {
        let repository = StubBookmarksRepository()
        repository.bookmarks = [
            bookmark(id: "plain"),
            bookmark(id: "favorite", isMarked: true),
            bookmark(id: "archived", isArchived: true),
            bookmark(id: "archivedFavorite", isArchived: true, isMarked: true)
        ]
        return (GetBookmarksUseCase(repository: repository), repository)
    }

    @Test("Unread keeps favorites, because a favorite can still be unread")
    func unreadKeepsFavorites() async throws {
        let (sut, _) = makeSUT()

        let page = try await sut.execute(state: .unread)

        #expect(page.bookmarks.map(\.id) == ["plain", "favorite"])
    }

    @Test("Unread still drops everything archived")
    func unreadDropsArchived() async throws {
        let (sut, _) = makeSUT()

        let page = try await sut.execute(state: .unread)

        #expect(page.bookmarks.allSatisfy { !$0.isArchived })
    }

    @Test("Favorite returns every marked bookmark, archived or not")
    func favoriteReturnsMarked() async throws {
        let (sut, _) = makeSUT()

        let page = try await sut.execute(state: .favorite)

        #expect(page.bookmarks.map(\.id) == ["favorite", "archivedFavorite"])
    }

    @Test("Archived returns every archived bookmark")
    func archivedReturnsArchived() async throws {
        let (sut, _) = makeSUT()

        let page = try await sut.execute(state: .archived)

        #expect(page.bookmarks.map(\.id) == ["archived", "archivedFavorite"])
    }

    @Test("All applies no filter")
    func allKeepsEverything() async throws {
        let (sut, _) = makeSUT()

        let page = try await sut.execute(state: .all)

        #expect(page.bookmarks.count == 4)
    }
}
