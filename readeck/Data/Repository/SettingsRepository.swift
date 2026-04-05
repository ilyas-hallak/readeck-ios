import Foundation
import CoreData
import Kingfisher

final class SettingsRepository: PSettingsRepository {
    private let coreDataManager = CoreDataManager.shared
    private let userDefault = UserDefaults.standard
    private let keychainHelper = KeychainHelper.shared
    private let tokenProvider: TokenProvider

    init(tokenProvider: TokenProvider = KeychainTokenProvider()) {
        self.tokenProvider = tokenProvider
    }

    var hasFinishedSetup: Bool {
        get {
            userDefault.value(forKey: "hasFinishedSetup") as? Bool ?? false
        }
        set {
            userDefault.set(newValue, forKey: "hasFinishedSetup")
        }
    }

    func saveSettings(_ settings: Settings) async throws {
        // Save credentials using TokenProvider to ensure cache is updated
        if let endpoint = settings.endpoint, !endpoint.isEmpty {
            await tokenProvider.setEndpoint(endpoint)
        }
        if let token = settings.token, !token.isEmpty {
            await tokenProvider.setToken(token)
        }

        // Save username and password directly (not in TokenProvider)
        if let username = settings.username, !username.isEmpty {
            keychainHelper.saveUsername(username)
        }
        if let password = settings.password, !password.isEmpty {
            keychainHelper.savePassword(password)
        }

        // Save UI preferences to Core Data
        let context = coreDataManager.context

        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    let existingSettings = try context.fetch(fetchRequest).first ?? SettingEntity(context: context)

                    if let fontFamily = settings.fontFamily {
                        existingSettings.fontFamily = fontFamily.rawValue
                    }

                    if let fontSize = settings.fontSize {
                        existingSettings.fontSize = fontSize.rawValue
                    }

                    if let enableTTS = settings.enableTTS {
                        existingSettings.enableTTS = enableTTS
                    }

                    existingSettings.disableReaderBackSwipe = settings.disableReaderBackSwipe

                    if let theme = settings.theme {
                        existingSettings.theme = theme.rawValue
                    }

                    if let urlOpener = settings.urlOpener {
                        existingSettings.urlOpener = urlOpener.rawValue
                    }

                    if let cardLayoutStyle = settings.cardLayoutStyle {
                        existingSettings.cardLayoutStyle = cardLayoutStyle.rawValue
                    }

                    if let tagSortOrder = settings.tagSortOrder {
                        existingSettings.tagSortOrder = tagSortOrder.rawValue
                    }

                    if let bookmarkSortField = settings.bookmarkSortField {
                        existingSettings.bookmarkSortField = bookmarkSortField.rawValue
                    }

                    if let bookmarkSortDirection = settings.bookmarkSortDirection {
                        existingSettings.bookmarkSortDirection = bookmarkSortDirection.rawValue
                    }

                    if let swipeActionConfig = settings.swipeActionConfig {
                        let encoder = JSONEncoder()
                        if let jsonData = try? encoder.encode(swipeActionConfig),
                           let configText = String(data: jsonData, encoding: .utf8) {
                            existingSettings.swipeActionConfig = configText
                        }
                    }
                    if let fontSizeNumeric = settings.fontSizeNumeric {
                        existingSettings.fontSizeNumeric = fontSizeNumeric
                    }
                    if let horizontalMargin = settings.horizontalMargin {
                        existingSettings.horizontalMargin = horizontalMargin
                    }
                    if let lineHeight = settings.lineHeight {
                        existingSettings.lineHeight = lineHeight
                    }
                    if let hideProgressBar = settings.hideProgressBar {
                        existingSettings.hideProgressBar = hideProgressBar
                    }
                    if let hideWordCount = settings.hideWordCount {
                        existingSettings.hideWordCount = hideWordCount
                    }
                    if let hideHeroImage = settings.hideHeroImage {
                        existingSettings.hideHeroImage = hideHeroImage
                    }
                    if let customCSS = settings.customCSS {
                        existingSettings.customCSS = customCSS
                    }
                    if let readerColorTheme = settings.readerColorTheme {
                        existingSettings.readerColorTheme = readerColorTheme.rawValue
                    }
                    if let customBackgroundColor = settings.customBackgroundColor {
                        existingSettings.customBackgroundColor = customBackgroundColor
                    }
                    if let customTextColor = settings.customTextColor {
                        existingSettings.customTextColor = customTextColor
                    }

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        return
    }

    func loadSettings() async throws -> Settings? {
        let context = coreDataManager.context

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    fetchRequest.fetchLimit = 1

                    let settingEntities = try context.fetch(fetchRequest)
                    let settingEntity = settingEntities.first

                    // Load credentials from keychain only
                    let endpoint = self.keychainHelper.loadEndpoint()
                    let username = self.keychainHelper.loadUsername()
                    let password = self.keychainHelper.loadPassword()
                    let token = self.keychainHelper.loadToken()

                    // Load swipe action config from JSON
                    var swipeActionConfig: SwipeActionConfig?
                    if let jsonString = settingEntity?.swipeActionConfig,
                       let jsonData = jsonString.data(using: .utf8) {
                        swipeActionConfig = try? JSONDecoder().decode(SwipeActionConfig.self, from: jsonData)
                    }

                    // Load UI preferences from Core Data
                    // fontSizeNumeric: 0 means not set (use FontSize enum fallback)
                    let storedFontSizeNumeric = settingEntity?.fontSizeNumeric ?? 0
                    let fontSizeNumeric: Double? = storedFontSizeNumeric > 0 ? storedFontSizeNumeric : nil

                    // horizontalMargin/lineHeight: 0 means not set (use defaults)
                    let storedHorizontalMargin = settingEntity?.horizontalMargin ?? 0
                    let horizontalMargin: Double? = storedHorizontalMargin > 0 ? storedHorizontalMargin : nil

                    let storedLineHeight = settingEntity?.lineHeight ?? 0
                    let lineHeight: Double? = storedLineHeight > 0 ? storedLineHeight : nil

                    let settings = Settings(
                        endpoint: endpoint,
                        username: username,
                        password: password,
                        token: token,
                        fontFamily: FontFamily(rawValue: settingEntity?.fontFamily ?? FontFamily.system.rawValue),
                        fontSize: FontSize(rawValue: settingEntity?.fontSize ?? FontSize.medium.rawValue),
                        enableTTS: settingEntity?.enableTTS,
                        theme: Theme(rawValue: settingEntity?.theme ?? Theme.system.rawValue),
                        cardLayoutStyle: CardLayoutStyle(rawValue: settingEntity?.cardLayoutStyle ?? CardLayoutStyle.magazine.rawValue),
                        tagSortOrder: TagSortOrder(rawValue: settingEntity?.tagSortOrder ?? TagSortOrder.byCount.rawValue),
                        bookmarkSortField: BookmarkSortField(rawValue: settingEntity?.bookmarkSortField ?? BookmarkSortField.created.rawValue),
                        bookmarkSortDirection: BookmarkSortDirection(rawValue: settingEntity?.bookmarkSortDirection ?? BookmarkSortDirection.descending.rawValue),
                        disableReaderBackSwipe: settingEntity?.disableReaderBackSwipe ?? false,
                        urlOpener: UrlOpener(rawValue: settingEntity?.urlOpener ?? UrlOpener.inAppBrowser.rawValue),
                        swipeActionConfig: swipeActionConfig,
                        fontSizeNumeric: fontSizeNumeric,
                        horizontalMargin: horizontalMargin,
                        lineHeight: lineHeight,
                        hideProgressBar: settingEntity?.hideProgressBar,
                        hideWordCount: settingEntity?.hideWordCount,
                        hideHeroImage: settingEntity?.hideHeroImage,
                        customCSS: settingEntity?.customCSS,
                        readerColorTheme: ReaderColorTheme(rawValue: settingEntity?.readerColorTheme ?? ReaderColorTheme.system.rawValue),
                        customBackgroundColor: settingEntity?.customBackgroundColor,
                        customTextColor: settingEntity?.customTextColor
                    )
                    continuation.resume(returning: settings)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func clearSettings() async throws {
        // Clear credentials from keychain
        keychainHelper.clearCredentials()

        // Also clear from Core Data
        let context = coreDataManager.context

        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    let settingEntities = try context.fetch(fetchRequest)

                    for settingEntity in settingEntities {
                        context.delete(settingEntity)
                    }

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        return
    }

    func saveToken(_ token: String) async throws {
        // Use TokenProvider to ensure cache is updated
        await tokenProvider.setToken(token)

        // Wenn ein Token gespeichert wird, Setup als abgeschlossen markieren
        if !token.isEmpty {
            self.hasFinishedSetup = true
            // Notification senden, dass sich der Setup-Status geändert hat
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .setupStatusChanged, object: nil)
            }
        }
    }

    func saveServerSettings(endpoint: String, username: String, password: String, token: String) async throws {
        // Use TokenProvider to ensure cache is updated
        await tokenProvider.setEndpoint(endpoint)
        await tokenProvider.setToken(token)

        // Also save username and password directly (not in TokenProvider)
        keychainHelper.saveUsername(username)
        keychainHelper.savePassword(password)

        if !token.isEmpty {
            self.hasFinishedSetup = true
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .setupStatusChanged, object: nil)
            }
        }
    }

    func saveUsername(_ username: String) async throws {
        keychainHelper.saveUsername(username)
    }

    func savePassword(_ password: String) async throws {
        keychainHelper.savePassword(password)
    }

    func saveHasFinishedSetup(_ hasFinishedSetup: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.hasFinishedSetup = hasFinishedSetup
            // Notification senden, dass sich der Setup-Status geändert hat
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .setupStatusChanged, object: nil)
            }
            continuation.resume()
        }
    }

    func saveCardLayoutStyle(_ cardLayoutStyle: CardLayoutStyle) async throws {
        let context = coreDataManager.context

        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    let existingSettings = try context.fetch(fetchRequest).first ?? SettingEntity(context: context)

                    existingSettings.cardLayoutStyle = cardLayoutStyle.rawValue

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        return
    }

    func loadCardLayoutStyle() async throws -> CardLayoutStyle {
        let context = coreDataManager.context

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    fetchRequest.fetchLimit = 1

                    let settingEntities = try context.fetch(fetchRequest)
                    let settingEntity = settingEntities.first

                    let cardLayoutStyle = CardLayoutStyle(rawValue: settingEntity?.cardLayoutStyle ?? CardLayoutStyle.magazine.rawValue) ?? .magazine
                    continuation.resume(returning: cardLayoutStyle)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func saveTagSortOrder(_ tagSortOrder: TagSortOrder) async throws {
        let context = coreDataManager.context

        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    let existingSettings = try context.fetch(fetchRequest).first ?? SettingEntity(context: context)

                    existingSettings.tagSortOrder = tagSortOrder.rawValue

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        return
    }

    func loadTagSortOrder() async throws -> TagSortOrder {
        let context = coreDataManager.context

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    fetchRequest.fetchLimit = 1

                    let settingEntities = try context.fetch(fetchRequest)
                    let settingEntity = settingEntities.first

                    let tagSortOrder = TagSortOrder(rawValue: settingEntity?.tagSortOrder ?? TagSortOrder.byCount.rawValue) ?? .byCount
                    continuation.resume(returning: tagSortOrder)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Offline Settings

    private let logger = Logger.data

    func loadOfflineSettings() async throws -> OfflineSettings {
        let context = coreDataManager.context

        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    fetchRequest.fetchLimit = 1

                    let settingEntities = try context.fetch(fetchRequest)
                    let settingEntity = settingEntities.first

                    let settings = OfflineSettings(
                        enabled: settingEntity?.offlineEnabled ?? false,
                        maxUnreadArticles: settingEntity?.offlineMaxUnreadArticles ?? 20,
                        saveImages: settingEntity?.offlineSaveImages ?? true,
                        lastSyncDate: settingEntity?.offlineLastSyncDate
                    )

                    self.logger.debug("Loaded offline settings: enabled=\(settings.enabled), max=\(settings.maxUnreadArticlesInt)")
                    continuation.resume(returning: settings)
                } catch {
                    self.logger.error("Failed to load offline settings: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func saveOfflineSettings(_ settings: OfflineSettings) async throws {
        let context = coreDataManager.context

        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    let existingSettings = try context.fetch(fetchRequest).first ?? SettingEntity(context: context)

                    existingSettings.offlineEnabled = settings.enabled
                    existingSettings.offlineMaxUnreadArticles = settings.maxUnreadArticles
                    existingSettings.offlineSaveImages = settings.saveImages
                    existingSettings.offlineLastSyncDate = settings.lastSyncDate

                    try context.save()
                    self.logger.info("Saved offline settings: enabled=\(settings.enabled), max=\(settings.maxUnreadArticlesInt)")
                    continuation.resume()
                } catch {
                    self.logger.error("Failed to save offline settings: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
        return
    }

    // MARK: - Cache Settings

    private let maxCacheSizeKey = "KingfisherMaxCacheSize"

    func getCacheSize() async throws -> UInt {
        try await withCheckedThrowingContinuation { continuation in
            KingfisherManager.shared.cache.calculateDiskStorageSize { result in
                switch result {
                case .success(let size):
                    continuation.resume(returning: size)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func getMaxCacheSize() async throws -> UInt {
        if let savedSize = userDefault.object(forKey: maxCacheSizeKey) as? UInt {
            return savedSize
        }
        // Default: 200 MB
        let defaultBytes = UInt(200 * 1024 * 1024)
        userDefault.set(defaultBytes, forKey: maxCacheSizeKey)
        return defaultBytes
    }

    func updateMaxCacheSize(_ sizeInBytes: UInt) async throws {
        KingfisherManager.shared.cache.diskStorage.config.sizeLimit = sizeInBytes
        userDefault.set(sizeInBytes, forKey: maxCacheSizeKey)
        logger.info("Updated max cache size to \(sizeInBytes) bytes")
    }

    func clearCache() async throws {
        try await withCheckedThrowingContinuation { continuation in
            KingfisherManager.shared.cache.clearDiskCache {
                KingfisherManager.shared.cache.clearMemoryCache()
                self.logger.info("Cache cleared successfully")
                continuation.resume()
            }
        }
    }
}
