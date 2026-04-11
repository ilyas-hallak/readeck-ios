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
    func makeSummarizeArticleUseCase() -> PSummarizeArticleUseCase
}

final class DefaultUseCaseFactory: UseCaseFactory {
    private let tokenProvider = KeychainTokenProvider()
    private lazy var api: PAPI = API(tokenProvider: tokenProvider)
    private lazy var profileApiClient: PProfileApiClient = ProfileApiClient(tokenProvider: tokenProvider)
    private lazy var getUserProfileUseCase: PGetUserProfileUseCase = GetUserProfileUseCase(profileApiClient: profileApiClient)
    private lazy var authRepository: PAuthRepository = AuthRepository(api: api, settingsRepository: settingsRepository, getUserProfileUseCase: getUserProfileUseCase)
    private lazy var bookmarksRepository: PBookmarksRepository = BookmarksRepository(api: api)
    private lazy var settingsRepository: PSettingsRepository = SettingsRepository(tokenProvider: tokenProvider)
    private lazy var infoApiClient: PInfoApiClient = InfoApiClient(tokenProvider: tokenProvider)
    private lazy var serverInfoRepository: PServerInfoRepository = ServerInfoRepository(apiClient: infoApiClient)
    private lazy var annotationsRepository: PAnnotationsRepository = AnnotationsRepository(api: api)
    private lazy var labelsRepository: PLabelsRepository = LabelsRepository(api: api)
    private let offlineCacheRepository: POfflineCacheRepository = OfflineCacheRepository()
    private let networkMonitorRepository: PNetworkMonitorRepository = NetworkMonitorRepository()
    private lazy var summarizationRepository: PSummarizationRepository = SummarizationRepository()

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
        UpdateBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeLogoutUseCase() -> PLogoutUseCase {
        LogoutUseCase(settingsRepository: settingsRepository)
    }

    func makeDeleteBookmarkUseCase() -> PDeleteBookmarkUseCase {
        DeleteBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeCreateBookmarkUseCase() -> PCreateBookmarkUseCase {
        CreateBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeSearchBookmarksUseCase() -> PSearchBookmarksUseCase {
        SearchBookmarksUseCase(repository: bookmarksRepository)
    }

    func makeSaveServerSettingsUseCase() -> PSaveServerSettingsUseCase {
        SaveServerSettingsUseCase(repository: settingsRepository)
    }

    func makeAddLabelsToBookmarkUseCase() -> PAddLabelsToBookmarkUseCase {
        AddLabelsToBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeRemoveLabelsFromBookmarkUseCase() -> PRemoveLabelsFromBookmarkUseCase {
        RemoveLabelsFromBookmarkUseCase(repository: bookmarksRepository)
    }

    func makeGetLabelsUseCase() -> PGetLabelsUseCase {
        GetLabelsUseCase(labelsRepository: labelsRepository)
    }

    func makeCreateLabelUseCase() -> PCreateLabelUseCase {
        CreateLabelUseCase(labelsRepository: labelsRepository)
    }

    func makeSyncTagsUseCase() -> PSyncTagsUseCase {
        SyncTagsUseCase(labelsRepository: labelsRepository)
    }

    func makeAddTextToSpeechQueueUseCase() -> PAddTextToSpeechQueueUseCase {
        AddTextToSpeechQueueUseCase()
    }

    func makeOfflineBookmarkSyncUseCase() -> POfflineBookmarkSyncUseCase {
        OfflineBookmarkSyncUseCase()
    }

    func makeLoadCardLayoutUseCase() -> PLoadCardLayoutUseCase {
        LoadCardLayoutUseCase(settingsRepository: settingsRepository)
    }

    func makeSaveCardLayoutUseCase() -> PSaveCardLayoutUseCase {
        SaveCardLayoutUseCase(settingsRepository: settingsRepository)
    }

    func makeCheckServerReachabilityUseCase() -> PCheckServerReachabilityUseCase {
        CheckServerReachabilityUseCase(repository: serverInfoRepository)
    }

    func makeGetServerInfoUseCase() -> PGetServerInfoUseCase {
        GetServerInfoUseCase(repository: serverInfoRepository)
    }

    func makeGetBookmarkAnnotationsUseCase() -> PGetBookmarkAnnotationsUseCase {
        GetBookmarkAnnotationsUseCase(repository: annotationsRepository)
    }

    func makeDeleteAnnotationUseCase() -> PDeleteAnnotationUseCase {
        DeleteAnnotationUseCase(repository: annotationsRepository)
    }

    func makeSettingsRepository() -> PSettingsRepository {
        settingsRepository
    }

    func makeOfflineCacheSyncUseCase() -> POfflineCacheSyncUseCase {
        OfflineCacheSyncUseCase(
            offlineCacheRepository: offlineCacheRepository,
            bookmarksRepository: bookmarksRepository,
            settingsRepository: settingsRepository
        )
    }

    func makeNetworkMonitorUseCase() -> PNetworkMonitorUseCase {
        NetworkMonitorUseCase(repository: networkMonitorRepository)
    }

    func makeGetCachedBookmarksUseCase() -> PGetCachedBookmarksUseCase {
        GetCachedBookmarksUseCase(offlineCacheRepository: offlineCacheRepository)
    }

    func makeGetCachedArticleUseCase() -> PGetCachedArticleUseCase {
        GetCachedArticleUseCase(offlineCacheRepository: offlineCacheRepository)
    }

    func makeCreateAnnotationUseCase() -> PCreateAnnotationUseCase {
        CreateAnnotationUseCase(repository: annotationsRepository)
    }

    func makeGetCacheSizeUseCase() -> PGetCacheSizeUseCase {
        GetCacheSizeUseCase(settingsRepository: settingsRepository)
    }

    func makeGetMaxCacheSizeUseCase() -> PGetMaxCacheSizeUseCase {
        GetMaxCacheSizeUseCase(settingsRepository: settingsRepository)
    }

    func makeUpdateMaxCacheSizeUseCase() -> PUpdateMaxCacheSizeUseCase {
        UpdateMaxCacheSizeUseCase(settingsRepository: settingsRepository)
    }

    func makeClearCacheUseCase() -> PClearCacheUseCase {
        ClearCacheUseCase(settingsRepository: settingsRepository)
    }

    private lazy var oauthRepository: POAuthRepository = OAuthRepository(api: api)
    private lazy var oauthManager = OAuthManager(repository: oauthRepository)

    @MainActor func makeLoginWithOAuthUseCase() -> PLoginWithOAuthUseCase {
        let coordinator = OAuthFlowCoordinator(manager: oauthManager)
        return LoginWithOAuthUseCase(oauthCoordinator: coordinator)
    }

    func makeAuthRepository() -> PAuthRepository {
        authRepository
    }

    func makeSummarizeArticleUseCase() -> PSummarizeArticleUseCase {
        SummarizeArticleUseCase(repository: summarizationRepository)
    }
}
