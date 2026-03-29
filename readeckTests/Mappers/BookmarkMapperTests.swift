import Testing
@testable import readeck

@Suite("BookmarkMapper Tests")
struct BookmarkMapperTests {

    // MARK: - Full Mapping

    @Test("BookmarkDto.toDomain() maps all fields correctly")
    func fullMapping() {
        let dto = BookmarkDto(
            id: "bm-123",
            title: "Swift Testing Guide",
            url: "https://example.com/article",
            href: "/api/bookmarks/bm-123",
            description: "A comprehensive guide to Swift Testing.",
            authors: ["Alice", "Bob"],
            created: "2025-06-15T10:30:00Z",
            published: "2025-06-14T08:00:00Z",
            updated: "2025-06-16T12:00:00Z",
            siteName: "Example Blog",
            site: "example.com",
            readingTime: 12,
            wordCount: 3500,
            hasArticle: true,
            isArchived: false,
            isDeleted: false,
            isMarked: true,
            labels: ["swift", "testing"],
            lang: "en",
            loaded: true,
            readProgress: 45,
            documentType: "article",
            state: 1,
            textDirection: "ltr",
            type: "bookmark",
            resources: BookmarkResourcesDto(
                article: ResourceDto(src: "/api/bookmarks/bm-123/article"),
                icon: ImageResourceDto(src: "/api/bookmarks/bm-123/icon", height: 32, width: 32),
                image: ImageResourceDto(src: "/api/bookmarks/bm-123/image", height: 600, width: 800),
                log: ResourceDto(src: "/api/bookmarks/bm-123/log"),
                props: ResourceDto(src: "/api/bookmarks/bm-123/props"),
                thumbnail: ImageResourceDto(src: "/api/bookmarks/bm-123/thumb", height: 150, width: 200)
            )
        )

        let bookmark = dto.toDomain()

        #expect(bookmark.id == "bm-123")
        #expect(bookmark.title == "Swift Testing Guide")
        #expect(bookmark.url == "https://example.com/article")
        #expect(bookmark.href == "/api/bookmarks/bm-123")
        #expect(bookmark.description == "A comprehensive guide to Swift Testing.")
        #expect(bookmark.authors == ["Alice", "Bob"])
        #expect(bookmark.created == "2025-06-15T10:30:00Z")
        #expect(bookmark.published == "2025-06-14T08:00:00Z")
        #expect(bookmark.updated == "2025-06-16T12:00:00Z")
        #expect(bookmark.siteName == "Example Blog")
        #expect(bookmark.site == "example.com")
        #expect(bookmark.readingTime == 12)
        #expect(bookmark.wordCount == 3500)
        #expect(bookmark.hasArticle == true)
        #expect(bookmark.isArchived == false)
        #expect(bookmark.isDeleted == false)
        #expect(bookmark.isMarked == true)
        #expect(bookmark.labels == ["swift", "testing"])
        #expect(bookmark.lang == "en")
        #expect(bookmark.loaded == true)
        #expect(bookmark.readProgress == 45)
        #expect(bookmark.documentType == "article")
        #expect(bookmark.state == 1)
        #expect(bookmark.textDirection == "ltr")
        #expect(bookmark.type == "bookmark")

        // Resources
        #expect(bookmark.resources.article?.src == "/api/bookmarks/bm-123/article")
        #expect(bookmark.resources.icon?.src == "/api/bookmarks/bm-123/icon")
        #expect(bookmark.resources.icon?.height == 32)
        #expect(bookmark.resources.icon?.width == 32)
        #expect(bookmark.resources.image?.src == "/api/bookmarks/bm-123/image")
        #expect(bookmark.resources.image?.height == 600)
        #expect(bookmark.resources.image?.width == 800)
        #expect(bookmark.resources.log?.src == "/api/bookmarks/bm-123/log")
        #expect(bookmark.resources.props?.src == "/api/bookmarks/bm-123/props")
        #expect(bookmark.resources.thumbnail?.src == "/api/bookmarks/bm-123/thumb")
        #expect(bookmark.resources.thumbnail?.height == 150)
        #expect(bookmark.resources.thumbnail?.width == 200)
    }

    // MARK: - Nil Optional Fields

    @Test("BookmarkDto.toDomain() handles nil optional fields")
    func nilOptionalFields() {
        let dto = BookmarkDto(
            id: "bm-456",
            title: "Minimal Bookmark",
            url: "https://example.com/minimal",
            href: "/api/bookmarks/bm-456",
            description: "",
            authors: [],
            created: "2025-07-01T00:00:00Z",
            published: nil,
            updated: "2025-07-01T00:00:00Z",
            siteName: "",
            site: "example.com",
            readingTime: nil,
            wordCount: nil,
            hasArticle: false,
            isArchived: false,
            isDeleted: false,
            isMarked: false,
            labels: [],
            lang: nil,
            loaded: false,
            readProgress: 0,
            documentType: "article",
            state: 0,
            textDirection: "ltr",
            type: "bookmark",
            resources: BookmarkResourcesDto(
                article: nil,
                icon: nil,
                image: nil,
                log: nil,
                props: nil,
                thumbnail: nil
            )
        )

        let bookmark = dto.toDomain()

        #expect(bookmark.published == nil)
        #expect(bookmark.readingTime == nil)
        #expect(bookmark.wordCount == nil)
        #expect(bookmark.lang == nil)
        #expect(bookmark.authors.isEmpty)
        #expect(bookmark.labels.isEmpty)
        #expect(bookmark.resources.article == nil)
        #expect(bookmark.resources.icon == nil)
        #expect(bookmark.resources.image == nil)
        #expect(bookmark.resources.log == nil)
        #expect(bookmark.resources.props == nil)
        #expect(bookmark.resources.thumbnail == nil)
    }

    // MARK: - Page Mapping

    @Test("BookmarksPageDto.toDomain() maps pagination fields")
    func pageMapping() {
        let bookmarkDto = BookmarkDto(
            id: "bm-1",
            title: "Page Item",
            url: "https://example.com/page",
            href: "/api/bookmarks/bm-1",
            description: "",
            authors: [],
            created: "2025-07-01T00:00:00Z",
            published: nil,
            updated: "2025-07-01T00:00:00Z",
            siteName: "",
            site: "example.com",
            readingTime: nil,
            wordCount: nil,
            hasArticle: false,
            isArchived: false,
            isDeleted: false,
            isMarked: false,
            labels: [],
            lang: nil,
            loaded: false,
            readProgress: 0,
            documentType: "article",
            state: 0,
            textDirection: "ltr",
            type: "bookmark",
            resources: BookmarkResourcesDto(
                article: nil, icon: nil, image: nil,
                log: nil, props: nil, thumbnail: nil
            )
        )

        let pageDto = BookmarksPageDto(
            bookmarks: [bookmarkDto],
            currentPage: 2,
            totalCount: 50,
            totalPages: 5,
            links: ["/api/bookmarks?page=3"]
        )

        let page = pageDto.toDomain()

        #expect(page.currentPage == 2)
        #expect(page.totalCount == 50)
        #expect(page.totalPages == 5)
        #expect(page.bookmarks.count == 1)
        #expect(page.bookmarks.first?.id == "bm-1")
        #expect(page.links == ["/api/bookmarks?page=3"])
    }

    // MARK: - Label Mapping

    @Test("BookmarkLabelDto.toDomain() maps name, count, and href")
    func labelMapping() {
        let labelDto = BookmarkLabelDto(name: "swift", count: 42, href: "/api/labels/swift")

        let label = labelDto.toDomain()

        #expect(label.name == "swift")
        #expect(label.count == 42)
        #expect(label.href == "/api/labels/swift")
    }

    // MARK: - Date Preservation

    @Test("Date strings pass through mapping unchanged")
    func datePreservation() {
        let createdDate = "2025-12-25T23:59:59Z"
        let publishedDate = "2025-12-24T00:00:00Z"
        let updatedDate = "2025-12-26T12:30:00Z"

        let dto = BookmarkDto(
            id: "bm-date",
            title: "Date Test",
            url: "https://example.com/dates",
            href: "/api/bookmarks/bm-date",
            description: "",
            authors: [],
            created: createdDate,
            published: publishedDate,
            updated: updatedDate,
            siteName: "",
            site: "example.com",
            readingTime: nil,
            wordCount: nil,
            hasArticle: false,
            isArchived: false,
            isDeleted: false,
            isMarked: false,
            labels: [],
            lang: nil,
            loaded: false,
            readProgress: 0,
            documentType: "article",
            state: 0,
            textDirection: "ltr",
            type: "bookmark",
            resources: BookmarkResourcesDto(
                article: nil, icon: nil, image: nil,
                log: nil, props: nil, thumbnail: nil
            )
        )

        let bookmark = dto.toDomain()

        #expect(bookmark.created == createdDate)
        #expect(bookmark.published == publishedDate)
        #expect(bookmark.updated == updatedDate)
    }
}
