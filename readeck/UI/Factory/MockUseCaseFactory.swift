//
//  MockUseCaseFactory.swift
//  readeck
//
//  Created by Ilyas Hallak on 18.07.25.
//

import Foundation

class MockUseCaseFactory: UseCaseFactory {
    func makeLoginUseCase() -> any PLoginUseCase {
        MockLoginUserCase()
    }
    
    func makeGetBookmarksUseCase() -> any PGetBookmarksUseCase {
        MockGetBookmarksUseCase()
    }
    
    func makeGetBookmarkUseCase() -> any PGetBookmarkUseCase {
        MockGetBookmarkUseCase()
    }
    
    func makeGetBookmarkArticleUseCase() -> any PGetBookmarkArticleUseCase {
        MockGetBookmarkArticleUseCase()
    }
    
    func makeSaveSettingsUseCase() -> any PSaveSettingsUseCase {
        MockSaveSettingsUseCase()
    }
    
    func makeLoadSettingsUseCase() -> any PLoadSettingsUseCase {
        MockLoadSettingsUseCase()
    }
    
    func makeUpdateBookmarkUseCase() -> any PUpdateBookmarkUseCase {
        MockUpdateBookmarkUseCase()
    }
    
    func makeDeleteBookmarkUseCase() -> any PDeleteBookmarkUseCase {
        MockDeleteBookmarkUseCase()
    }
    
    func makeCreateBookmarkUseCase() -> any PCreateBookmarkUseCase {
        MockCreateBookmarkUseCase()
    }
    
    func makeLogoutUseCase() -> any PLogoutUseCase {
        MockLogoutUseCase()
    }
    
    func makeSearchBookmarksUseCase() -> any PSearchBookmarksUseCase {
        MockSearchBookmarksUseCase()
    }
    
    func makeSaveServerSettingsUseCase() -> any PSaveServerSettingsUseCase {
        MockSaveServerSettingsUseCase()
    }
    
    func makeAddLabelsToBookmarkUseCase() -> any PAddLabelsToBookmarkUseCase {
        MockAddLabelsToBookmarkUseCase()
    }
    
    func makeRemoveLabelsFromBookmarkUseCase() -> any PRemoveLabelsFromBookmarkUseCase {
        MockRemoveLabelsFromBookmarkUseCase()
    }
    
    func makeGetLabelsUseCase() -> any PGetLabelsUseCase {
        MockGetLabelsUseCase()
    }
    
    func makeAddTextToSpeechQueueUseCase() -> any PAddTextToSpeechQueueUseCase {
        MockAddTextToSpeechQueueUseCase()
    }
    
}
    

// MARK: Mocked Use Cases

class MockLoginUserCase: PLoginUseCase {
    func execute(endpoint: String, username: String, password: String) async throws -> User {
        return User(id: "123", token: "abc")
    }
}

class MockLogoutUseCase: PLogoutUseCase {
    func execute() async throws {}
}

class MockCreateBookmarkUseCase: PCreateBookmarkUseCase {
    func execute(createRequest: CreateBookmarkRequest) async throws -> String { "mock-bookmark-id" }
    func createFromURL(_ url: String) async throws -> String { "mock-bookmark-id" }
    func createFromURLWithTitle(_ url: String, title: String) async throws -> String { "mock-bookmark-id" }
    func createFromURLWithLabels(_ url: String, labels: [String]) async throws -> String { "mock-bookmark-id" }
    func createFromClipboard() async throws -> String? { "mock-bookmark-id" }
}

class MockGetLabelsUseCase: PGetLabelsUseCase {
    func execute() async throws -> [BookmarkLabel] {
        [BookmarkLabel(name: "Test", count: 1, href: "mock-href")]
    }
}

class MockSearchBookmarksUseCase: PSearchBookmarksUseCase {
    func execute(search: String) async throws -> BookmarksPage {
        BookmarksPage(bookmarks: [], currentPage: 1, totalCount: 0, totalPages: 1, links: nil)
    }
}

class MockReadBookmarkUseCase: PReadBookmarkUseCase {
    func execute(bookmarkDetail: BookmarkDetail) {}
}

class MockGetBookmarksUseCase: PGetBookmarksUseCase {
    func execute(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?) async throws -> BookmarksPage {
        BookmarksPage(bookmarks: [
            Bookmark.mock
        ], currentPage: 1, totalCount: 0, totalPages: 1, links: nil)
    }
}

class MockUpdateBookmarkUseCase: PUpdateBookmarkUseCase {
    func execute(bookmarkId: String, updateRequest: BookmarkUpdateRequest) async throws {}
    func toggleArchive(bookmarkId: String, isArchived: Bool) async throws {}
    func toggleFavorite(bookmarkId: String, isMarked: Bool) async throws {}
    func markAsDeleted(bookmarkId: String) async throws {}
    func updateReadProgress(bookmarkId: String, progress: Int, anchor: String?) async throws {}
    func updateTitle(bookmarkId: String, title: String) async throws {}
    func updateLabels(bookmarkId: String, labels: [String]) async throws {}
    func addLabels(bookmarkId: String, labels: [String]) async throws {}
    func removeLabels(bookmarkId: String, labels: [String]) async throws {}
}

class MockSaveSettingsUseCase: PSaveSettingsUseCase {
    func execute(endpoint: String, username: String, password: String) async throws {}
    func execute(endpoint: String, username: String, password: String, hasFinishedSetup: Bool) async throws {}
    func execute(token: String) async throws {}
    func execute(selectedFontFamily: FontFamily, selectedFontSize: FontSize) async throws {}
    func execute(enableTTS: Bool) async throws {}
    func execute(theme: Theme) async throws {}
}

class MockGetBookmarkUseCase: PGetBookmarkUseCase {
    func execute(id: String) async throws -> BookmarkDetail {
        BookmarkDetail(id: "123", title: "Test", url: "https://www.google.com", description: "Test", siteName: "Test", authors: ["Test"], created: "2021-01-01", updated: "2021-01-01", wordCount: 100, readingTime: 100, hasArticle: true, isMarked: false, isArchived: false, labels: ["Test"], thumbnailUrl: "https://picsum.photos/30/30", imageUrl: "https://picsum.photos/400/400", lang: "en", readProgress: 0)
    }
}

class MockLoadSettingsUseCase: PLoadSettingsUseCase {
    func execute() async throws -> Settings? {
        Settings(endpoint: "mock-endpoint", username: "mock-user", password: "mock-pw", token: "mock-token", fontFamily: .system, fontSize: .medium, hasFinishedSetup: true)
    }
}

class MockDeleteBookmarkUseCase: PDeleteBookmarkUseCase {
    func execute(bookmarkId: String) async throws {}
}

class MockGetBookmarkArticleUseCase: PGetBookmarkArticleUseCase {
    func execute(id: String) async throws -> String { 
        let path = Bundle.main.path(forResource: "article", ofType: "html")
        return try String(contentsOfFile: path!)
    }
}

class MockAddLabelsToBookmarkUseCase: PAddLabelsToBookmarkUseCase {
    func execute(bookmarkId: String, labels: [String]) async throws {}
    func execute(bookmarkId: String, label: String) async throws {}
}

class MockRemoveLabelsFromBookmarkUseCase: PRemoveLabelsFromBookmarkUseCase {
    func execute(bookmarkId: String, labels: [String]) async throws {}
    func execute(bookmarkId: String, label: String) async throws {}
}

class MockSaveServerSettingsUseCase: PSaveServerSettingsUseCase {
    func execute(endpoint: String, username: String, password: String, token: String) async throws {}
}

class MockAddTextToSpeechQueueUseCase: PAddTextToSpeechQueueUseCase {
    func execute(bookmarkDetail: BookmarkDetail) {}
}

extension Bookmark {
    static let mock: Bookmark = .init(
        id: "123", title: "title", url: "https://example.com", href: "https://example.com", description: "description", authors: ["Tom"], created: "", published: "", updated: "", siteName: "example.com", site: "https://example.com", readingTime: 2, wordCount: 20, hasArticle: true, isArchived: false, isDeleted: false, isMarked: true, labels: ["Test"], lang: "EN", loaded: false, readProgress: 0, documentType: "", state: 0, textDirection: "ltr", type: "", resources: .init(article: nil, icon: nil, image: nil, log: nil, props: nil, thumbnail: nil)
    )
}
