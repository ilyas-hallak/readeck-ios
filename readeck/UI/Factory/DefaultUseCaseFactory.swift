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
    func makeCreateLabelUseCase() -> PCreateLabelUseCase
    func makeSyncTagsUseCase() -> PSyncTagsUseCase
    func makeAddTextToSpeechQueueUseCase() -> PAddTextToSpeechQueueUseCase
    func makeOfflineBookmarkSyncUseCase() -> POfflineBookmarkSyncUseCase
    func makeLoadCardLayoutUseCase() -> PLoadCardLayoutUseCase
    func makeSaveCardLayoutUseCase() -> PSaveCardLayoutUseCase
    func makeCheckServerReachabilityUseCase() -> PCheckServerReachabilityUseCase
    func makeGetServerInfoUseCase() -> PGetServerInfoUseCase
    func makeGetBookmarkAnnotationsUseCase() -> PGetBookmarkAnnotationsUseCase
    func makeDeleteAnnotationUseCase() -> PDeleteAnnotationUseCase
    func makeSettingsRepository() -> PSettingsRepository
    func makeOfflineCacheSyncUseCase() -> POfflineCacheSyncUseCase
    func makeNetworkMonitorUseCase() -> PNetworkMonitorUseCase
    func makeGetCachedBookmarksUseCase() -> PGetCachedBookmarksUseCase
    func makeGetCachedArticleUseCase() -> PGetCachedArticleUseCase
    func makeCreateAnnotationUseCase() -> PCreateAnnotationUseCase
    func makeGetCacheSizeUseCase() -> PGetCacheSizeUseCase
    func makeGetMaxCacheSizeUseCase() -> PGetMaxCacheSizeUseCase
    func makeUpdateMaxCacheSizeUseCase() -> PUpdateMaxCacheSizeUseCase
    func makeClearCacheUseCase() -> PClearCacheUseCase
    func makeLoginWithOAuthUseCase() -> PLoginWithOAuthUseCase
    func makeAuthRepository() -> PAuthRepository
}



class DefaultUseCaseFactory: UseCaseFactory {
    private let tokenProvider = KeychainTokenProvider()
    private lazy var api: PAPI = API(tokenProvider: tokenProvider)
    private lazy var profileApiClient: PProfileApiClient = ProfileApiClient(tokenProvider: tokenProvider)
    private lazy var getUserProfileUseCase: PGetUserProfileUseCase = GetUserProfileUseCase(profileApiClient: profileApiClient)
    private lazy var authRepository: PAuthRepository = AuthRepository(api: api, settingsRepository: settingsRepository, getUserProfileUseCase: getUserProfileUseCase)
    private lazy var bookmarksRepository: PBookmarksRepository = BookmarksRepository(api: api)
    private let settingsRepository: PSettingsRepository = SettingsRepository()
    private lazy var infoApiClient: PInfoApiClient = InfoApiClient(tokenProvider: tokenProvider)
    private lazy var serverInfoRepository: PServerInfoRepository = ServerInfoRepository(apiClient: infoApiClient)
    private lazy var annotationsRepository: PAnnotationsRepository = AnnotationsRepository(api: api)
    private let offlineCacheRepository: POfflineCacheRepository = OfflineCacheRepository()
    private let networkMonitorRepository: PNetworkMonitorRepository = NetworkMonitorRepository()

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

    func makeCreateLabelUseCase() -> PCreateLabelUseCase {
        let api = API(tokenProvider: KeychainTokenProvider())
        let labelsRepository = LabelsRepository(api: api)
        return CreateLabelUseCase(labelsRepository: labelsRepository)
    }

    func makeSyncTagsUseCase() -> PSyncTagsUseCase {
        let api = API(tokenProvider: KeychainTokenProvider())
        let labelsRepository = LabelsRepository(api: api)
        return SyncTagsUseCase(labelsRepository: labelsRepository)
    }

    func makeAddTextToSpeechQueueUseCase() -> PAddTextToSpeechQueueUseCase {
        return AddTextToSpeechQueueUseCase()
    }
    
    func makeOfflineBookmarkSyncUseCase() -> POfflineBookmarkSyncUseCase {
        return OfflineBookmarkSyncUseCase()
    }
    
    func makeLoadCardLayoutUseCase() -> PLoadCardLayoutUseCase {
        return LoadCardLayoutUseCase(settingsRepository: settingsRepository)
    }
    
    func makeSaveCardLayoutUseCase() -> PSaveCardLayoutUseCase {
        return SaveCardLayoutUseCase(settingsRepository: settingsRepository)
    }

    func makeCheckServerReachabilityUseCase() -> PCheckServerReachabilityUseCase {
        return CheckServerReachabilityUseCase(repository: serverInfoRepository)
    }

    func makeGetServerInfoUseCase() -> PGetServerInfoUseCase {
        return GetServerInfoUseCase(repository: serverInfoRepository)
    }

    func makeGetBookmarkAnnotationsUseCase() -> PGetBookmarkAnnotationsUseCase {
        return GetBookmarkAnnotationsUseCase(repository: annotationsRepository)
    }

    func makeDeleteAnnotationUseCase() -> PDeleteAnnotationUseCase {
        return DeleteAnnotationUseCase(repository: annotationsRepository)
    }

    func makeSettingsRepository() -> PSettingsRepository {
        return settingsRepository
    }

    func makeOfflineCacheSyncUseCase() -> POfflineCacheSyncUseCase {
        return OfflineCacheSyncUseCase(
            offlineCacheRepository: offlineCacheRepository,
            bookmarksRepository: bookmarksRepository,
            settingsRepository: settingsRepository
        )
    }

    func makeNetworkMonitorUseCase() -> PNetworkMonitorUseCase {
        return NetworkMonitorUseCase(repository: networkMonitorRepository)
    }

    func makeGetCachedBookmarksUseCase() -> PGetCachedBookmarksUseCase {
        return GetCachedBookmarksUseCase(offlineCacheRepository: offlineCacheRepository)
    }

    func makeGetCachedArticleUseCase() -> PGetCachedArticleUseCase {
        return GetCachedArticleUseCase(offlineCacheRepository: offlineCacheRepository)
    }

    func makeCreateAnnotationUseCase() -> PCreateAnnotationUseCase {
        return CreateAnnotationUseCase(repository: annotationsRepository)
    }

    func makeGetCacheSizeUseCase() -> PGetCacheSizeUseCase {
        return GetCacheSizeUseCase(settingsRepository: settingsRepository)
    }

    func makeGetMaxCacheSizeUseCase() -> PGetMaxCacheSizeUseCase {
        return GetMaxCacheSizeUseCase(settingsRepository: settingsRepository)
    }

    func makeUpdateMaxCacheSizeUseCase() -> PUpdateMaxCacheSizeUseCase {
        return UpdateMaxCacheSizeUseCase(settingsRepository: settingsRepository)
    }

    func makeClearCacheUseCase() -> PClearCacheUseCase {
        return ClearCacheUseCase(settingsRepository: settingsRepository)
    }

    private lazy var oauthRepository: POAuthRepository = OAuthRepository(api: api)
    private lazy var oauthManager: OAuthManager = OAuthManager(repository: oauthRepository)

    @MainActor func makeLoginWithOAuthUseCase() -> PLoginWithOAuthUseCase {
        let coordinator = OAuthFlowCoordinator(manager: oauthManager)
        return LoginWithOAuthUseCase(oauthCoordinator: coordinator)
    }

    func makeAuthRepository() -> PAuthRepository {
        return authRepository
    }
}
