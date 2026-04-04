import Foundation
import Combine
@testable import readeck

class TestUseCaseFactory: UseCaseFactory {
    // Configurable mocks — tests set these before creating ViewModels
    let mockGetBookmarks = ConfigurableGetBookmarksUseCase()
    let mockUpdateBookmark = ConfigurableUpdateBookmarkUseCase()
    let mockDeleteBookmark = ConfigurableDeleteBookmarkUseCase()
    let mockGetBookmark = ConfigurableGetBookmarkUseCase()
    let mockGetBookmarkArticle = ConfigurableGetBookmarkArticleUseCase()
    let mockLogin = ConfigurableLoginUseCase()
    let mockCheckReachability = ConfigurableCheckServerReachabilityUseCase()
    let mockCreateBookmark = ConfigurableCreateBookmarkUseCase()
    let mockSettingsRepository = MockSettingsRepository()

    // Configurable use cases
    func makeLoginUseCase() -> PLoginUseCase { mockLogin }
    func makeGetBookmarksUseCase() -> PGetBookmarksUseCase { mockGetBookmarks }
    func makeGetBookmarkUseCase() -> PGetBookmarkUseCase { mockGetBookmark }
    func makeGetBookmarkArticleUseCase() -> PGetBookmarkArticleUseCase { mockGetBookmarkArticle }
    func makeUpdateBookmarkUseCase() -> PUpdateBookmarkUseCase { mockUpdateBookmark }
    func makeDeleteBookmarkUseCase() -> PDeleteBookmarkUseCase { mockDeleteBookmark }
    func makeCreateBookmarkUseCase() -> PCreateBookmarkUseCase { mockCreateBookmark }
    func makeCheckServerReachabilityUseCase() -> PCheckServerReachabilityUseCase { mockCheckReachability }
    func makeGetServerInfoUseCase() -> PGetServerInfoUseCase { MockGetServerInfoUseCase() }

    // Non-configurable — use existing mocks from MockUseCaseFactory pattern
    func makeSaveSettingsUseCase() -> PSaveSettingsUseCase { MockSaveSettingsUseCase() }
    func makeLoadSettingsUseCase() -> PLoadSettingsUseCase { MockLoadSettingsUseCase() }
    func makeLogoutUseCase() -> PLogoutUseCase { MockLogoutUseCase() }
    func makeSearchBookmarksUseCase() -> PSearchBookmarksUseCase { MockSearchBookmarksUseCase() }
    func makeSaveServerSettingsUseCase() -> PSaveServerSettingsUseCase { MockSaveServerSettingsUseCase() }
    func makeAddLabelsToBookmarkUseCase() -> PAddLabelsToBookmarkUseCase { MockAddLabelsToBookmarkUseCase() }
    func makeRemoveLabelsFromBookmarkUseCase() -> PRemoveLabelsFromBookmarkUseCase { MockRemoveLabelsFromBookmarkUseCase() }
    func makeGetLabelsUseCase() -> PGetLabelsUseCase { MockGetLabelsUseCase() }
    func makeCreateLabelUseCase() -> PCreateLabelUseCase { MockCreateLabelUseCase() }
    func makeSyncTagsUseCase() -> PSyncTagsUseCase { MockSyncTagsUseCase() }
    func makeAddTextToSpeechQueueUseCase() -> PAddTextToSpeechQueueUseCase { MockAddTextToSpeechQueueUseCase() }
    func makeOfflineBookmarkSyncUseCase() -> POfflineBookmarkSyncUseCase { MockOfflineBookmarkSyncUseCase() }
    func makeLoadCardLayoutUseCase() -> PLoadCardLayoutUseCase { MockLoadCardLayoutUseCase() }
    func makeSaveCardLayoutUseCase() -> PSaveCardLayoutUseCase { MockSaveCardLayoutUseCase() }
    func makeGetBookmarkAnnotationsUseCase() -> PGetBookmarkAnnotationsUseCase { MockGetBookmarkAnnotationsUseCase() }
    func makeDeleteAnnotationUseCase() -> PDeleteAnnotationUseCase { MockDeleteAnnotationUseCase() }
    func makeSettingsRepository() -> PSettingsRepository { mockSettingsRepository }
    func makeOfflineCacheSyncUseCase() -> POfflineCacheSyncUseCase { MockOfflineCacheSyncUseCase() }
    func makeNetworkMonitorUseCase() -> PNetworkMonitorUseCase { MockNetworkMonitorUseCase() }
    func makeGetCachedBookmarksUseCase() -> PGetCachedBookmarksUseCase { MockGetCachedBookmarksUseCase() }
    func makeGetCachedArticleUseCase() -> PGetCachedArticleUseCase { MockGetCachedArticleUseCase() }
    func makeCreateAnnotationUseCase() -> PCreateAnnotationUseCase { MockCreateAnnotationUseCase() }
    func makeGetCacheSizeUseCase() -> PGetCacheSizeUseCase { MockGetCacheSizeUseCase() }
    func makeGetMaxCacheSizeUseCase() -> PGetMaxCacheSizeUseCase { MockGetMaxCacheSizeUseCase() }
    func makeUpdateMaxCacheSizeUseCase() -> PUpdateMaxCacheSizeUseCase { MockUpdateMaxCacheSizeUseCase() }
    func makeClearCacheUseCase() -> PClearCacheUseCase { MockClearCacheUseCase() }
    func makeLoginWithOAuthUseCase() -> PLoginWithOAuthUseCase { MockLoginWithOAuthUseCase() }
    func makeAuthRepository() -> PAuthRepository { MockAuthRepository() }
}
