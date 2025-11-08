import Foundation
import CoreData

protocol PSettingsRepository {
    func saveSettings(_ settings: Settings) async throws
    func loadSettings() async throws -> Settings?
    func clearSettings() async throws
    func saveToken(_ token: String) async throws
    func saveUsername(_ username: String) async throws
    func savePassword(_ password: String) async throws
    func saveHasFinishedSetup(_ hasFinishedSetup: Bool) async throws
    func saveServerSettings(endpoint: String, username: String, password: String, token: String) async throws
    func saveCardLayoutStyle(_ cardLayoutStyle: CardLayoutStyle) async throws
    func loadCardLayoutStyle() async throws -> CardLayoutStyle
    func saveTagSortOrder(_ tagSortOrder: TagSortOrder) async throws
    func loadTagSortOrder() async throws -> TagSortOrder
    var hasFinishedSetup: Bool { get }
}

class SettingsRepository: PSettingsRepository {
    private let coreDataManager = CoreDataManager.shared
    private let userDefault = UserDefaults.standard
    private let keychainHelper = KeychainHelper.shared
    
    var hasFinishedSetup: Bool {
        get {
            return userDefault.value(forKey: "hasFinishedSetup") as? Bool ?? false
        }
        set {
            userDefault.set(newValue, forKey: "hasFinishedSetup")
        }
    }
    
    func saveSettings(_ settings: Settings) async throws {
        // Save credentials to keychain
        if let endpoint = settings.endpoint, !endpoint.isEmpty {
            keychainHelper.saveEndpoint(endpoint)
        }
        if let username = settings.username, !username.isEmpty {
            keychainHelper.saveUsername(username)
        }
        if let password = settings.password, !password.isEmpty {
            keychainHelper.savePassword(password)
        }
        if let token = settings.token, !token.isEmpty {
            keychainHelper.saveToken(token)
        }
        
        // Save UI preferences to Core Data
        let context = coreDataManager.context
        
        return try await withCheckedThrowingContinuation { continuation in
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

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
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
                    
                    // Load UI preferences from Core Data
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
                        urlOpener: UrlOpener(rawValue: settingEntity?.urlOpener ?? UrlOpener.inAppBrowser.rawValue)
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
        
        return try await withCheckedThrowingContinuation { continuation in
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
    }
    
    func saveToken(_ token: String) async throws {
        // Save to keychain only
        keychainHelper.saveToken(token)
        
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
        keychainHelper.saveEndpoint(endpoint)
        keychainHelper.saveUsername(username)
        keychainHelper.savePassword(password)
        keychainHelper.saveToken(token)
        
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
        return try await withCheckedThrowingContinuation { continuation in
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
        
        return try await withCheckedThrowingContinuation { continuation in
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

        return try await withCheckedThrowingContinuation { continuation in
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
}
