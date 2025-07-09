import Foundation

protocol UseCaseFactory {
    func makeLoginUseCase() -> LoginUseCase
    func makeGetBookmarksUseCase() -> GetBookmarksUseCase
    func makeGetBookmarkUseCase() -> GetBookmarkUseCase
    func makeGetBookmarkArticleUseCase() -> GetBookmarkArticleUseCase
    func makeSaveSettingsUseCase() -> SaveSettingsUseCase
    func makeLoadSettingsUseCase() -> LoadSettingsUseCase
    func makeUpdateBookmarkUseCase() -> UpdateBookmarkUseCase
    func makeDeleteBookmarkUseCase() -> DeleteBookmarkUseCase
    func makeCreateBookmarkUseCase() -> CreateBookmarkUseCase
    func makeLogoutUseCase() -> LogoutUseCase
    func makeSearchBookmarksUseCase() -> SearchBookmarksUseCase
    func makeSaveServerSettingsUseCase() -> SaveServerSettingsUseCase
    func makeAddLabelsToBookmarkUseCase() -> AddLabelsToBookmarkUseCase
    func makeRemoveLabelsFromBookmarkUseCase() -> RemoveLabelsFromBookmarkUseCase
    func makeGetLabelsUseCase() -> GetLabelsUseCase
    func makeAddTextToSpeechQueueUseCase() -> AddTextToSpeechQueueUseCase
}

class DefaultUseCaseFactory: UseCaseFactory {
    private let tokenProvider = CoreDataTokenProvider()
    private lazy var api: PAPI = API(tokenProvider: tokenProvider)
    private lazy var authRepository: PAuthRepository = AuthRepository(api: api, settingsRepository: settingsRepository)
    private lazy var bookmarksRepository: PBookmarksRepository = BookmarksRepository(api: api)
    private let settingsRepository: PSettingsRepository = SettingsRepository()
    
    static let shared = DefaultUseCaseFactory()
    
    private init() {}
    
    func makeLoginUseCase() -> LoginUseCase {
        LoginUseCase(repository: authRepository)
    }
    
    func makeGetBookmarksUseCase() -> GetBookmarksUseCase {
        GetBookmarksUseCase(repository: bookmarksRepository)
    }
    
    func makeGetBookmarkUseCase() -> GetBookmarkUseCase {
        GetBookmarkUseCase(repository: bookmarksRepository)
    }
    
    func makeGetBookmarkArticleUseCase() -> GetBookmarkArticleUseCase {
        GetBookmarkArticleUseCase(repository: bookmarksRepository)
    }
    
    func makeSaveSettingsUseCase() -> SaveSettingsUseCase {
        SaveSettingsUseCase(settingsRepository: settingsRepository)
    }
    
    func makeLoadSettingsUseCase() -> LoadSettingsUseCase {
        LoadSettingsUseCase(authRepository: authRepository)
    }

    func makeUpdateBookmarkUseCase() -> UpdateBookmarkUseCase {
        return UpdateBookmarkUseCase(repository: bookmarksRepository)
    }
    
    func makeLogoutUseCase() -> LogoutUseCase {
        return LogoutUseCase()
    }
    
    // Nicht mehr nötig - Token wird automatisch geladen
    func refreshConfiguration() async {
        // Optional: Cache löschen falls nötig
    }

    func makeDeleteBookmarkUseCase() -> DeleteBookmarkUseCase {
        return DeleteBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeCreateBookmarkUseCase() -> CreateBookmarkUseCase {
        return CreateBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeSearchBookmarksUseCase() -> SearchBookmarksUseCase {
        return SearchBookmarksUseCase(repository: bookmarksRepository)
    }

    func makeSaveServerSettingsUseCase() -> SaveServerSettingsUseCase {
        return SaveServerSettingsUseCase(repository: SettingsRepository())
    }
    
    func makeAddLabelsToBookmarkUseCase() -> AddLabelsToBookmarkUseCase {
        return AddLabelsToBookmarkUseCase(repository: bookmarksRepository)
    }
    
    func makeRemoveLabelsFromBookmarkUseCase() -> RemoveLabelsFromBookmarkUseCase {
        return RemoveLabelsFromBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeGetLabelsUseCase() -> GetLabelsUseCase {
        let api = API(tokenProvider: CoreDataTokenProvider())
        let labelsRepository = LabelsRepository(api: api)
        return GetLabelsUseCase(labelsRepository: labelsRepository)
    }
    
    func makeAddTextToSpeechQueueUseCase() -> AddTextToSpeechQueueUseCase {
        return AddTextToSpeechQueueUseCase()
    }
}
