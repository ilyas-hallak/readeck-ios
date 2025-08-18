import Foundation

protocol UseCaseFactory {
    func makeLoginUseCase() -> PLoginUseCase
    func makeGetBookmarksUseCase() -> PGetBookmarksUseCase
    func makeGetBookmarkUseCase() -> PGetBookmarkUseCase
    func makeGetBookmarkArticleUseCase() -> PGetBookmarkArticleUseCase
    func makeSaveSettingsUseCase() -> PSaveSettingsUseCase
    func makeLoadSettingsUseCase() -> PLoadSettingsUseCase
    func makeUpdateBookmarkUseCase() -> PUpdateBookmarkUseCase
    func makeDeleteBookmarkUseCase() -> PDeleteBookmarkUseCase
    func makeCreateBookmarkUseCase() -> PCreateBookmarkUseCase
    func makeLogoutUseCase() -> PLogoutUseCase
    func makeSearchBookmarksUseCase() -> PSearchBookmarksUseCase
    func makeSaveServerSettingsUseCase() -> PSaveServerSettingsUseCase
    func makeAddLabelsToBookmarkUseCase() -> PAddLabelsToBookmarkUseCase
    func makeRemoveLabelsFromBookmarkUseCase() -> PRemoveLabelsFromBookmarkUseCase
    func makeGetLabelsUseCase() -> PGetLabelsUseCase
    func makeAddTextToSpeechQueueUseCase() -> PAddTextToSpeechQueueUseCase
    func makeOfflineBookmarkSyncUseCase() -> POfflineBookmarkSyncUseCase
}



class DefaultUseCaseFactory: UseCaseFactory {
    private let tokenProvider = KeychainTokenProvider()
    private lazy var api: PAPI = API(tokenProvider: tokenProvider)
    private lazy var authRepository: PAuthRepository = AuthRepository(api: api, settingsRepository: settingsRepository)
    private lazy var bookmarksRepository: PBookmarksRepository = BookmarksRepository(api: api)
    private let settingsRepository: PSettingsRepository = SettingsRepository()
    
    static let shared = DefaultUseCaseFactory()
    
    private init() {}
    
    func makeLoginUseCase() -> PLoginUseCase {
        LoginUseCase(repository: authRepository)
    }
    
    func makeGetBookmarksUseCase() -> PGetBookmarksUseCase {
        GetBookmarksUseCase(repository: bookmarksRepository)
    }
    
    func makeGetBookmarkUseCase() -> PGetBookmarkUseCase {
        GetBookmarkUseCase(repository: bookmarksRepository)
    }
    
    func makeGetBookmarkArticleUseCase() -> PGetBookmarkArticleUseCase {
        GetBookmarkArticleUseCase(repository: bookmarksRepository)
    }
    
    func makeSaveSettingsUseCase() -> PSaveSettingsUseCase {
        SaveSettingsUseCase(settingsRepository: settingsRepository)
    }
    
    func makeLoadSettingsUseCase() -> PLoadSettingsUseCase {
        LoadSettingsUseCase(authRepository: authRepository)
    }

    func makeUpdateBookmarkUseCase() -> PUpdateBookmarkUseCase {
        return UpdateBookmarkUseCase(repository: bookmarksRepository)
    }
    
    func makeLogoutUseCase() -> PLogoutUseCase {
        return LogoutUseCase()
    }

    func makeDeleteBookmarkUseCase() -> PDeleteBookmarkUseCase {
        return DeleteBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeCreateBookmarkUseCase() -> PCreateBookmarkUseCase {
        return CreateBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeSearchBookmarksUseCase() -> PSearchBookmarksUseCase {
        return SearchBookmarksUseCase(repository: bookmarksRepository)
    }

    func makeSaveServerSettingsUseCase() -> PSaveServerSettingsUseCase {
        return SaveServerSettingsUseCase(repository: SettingsRepository())
    }
    
    func makeAddLabelsToBookmarkUseCase() -> PAddLabelsToBookmarkUseCase {
        return AddLabelsToBookmarkUseCase(repository: bookmarksRepository)
    }
    
    func makeRemoveLabelsFromBookmarkUseCase() -> PRemoveLabelsFromBookmarkUseCase {
        return RemoveLabelsFromBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeGetLabelsUseCase() -> PGetLabelsUseCase {
        let api = API(tokenProvider: KeychainTokenProvider())
        let labelsRepository = LabelsRepository(api: api)
        return GetLabelsUseCase(labelsRepository: labelsRepository)
    }
    
    func makeAddTextToSpeechQueueUseCase() -> PAddTextToSpeechQueueUseCase {
        return AddTextToSpeechQueueUseCase()
    }
    
    func makeOfflineBookmarkSyncUseCase() -> POfflineBookmarkSyncUseCase {
        return OfflineBookmarkSyncUseCase()
    }
}
