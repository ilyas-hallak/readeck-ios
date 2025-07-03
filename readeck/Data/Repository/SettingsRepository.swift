import Foundation
import CoreData

struct Settings {
    var endpoint: String? = nil
    var username: String? = nil
    var password: String? = nil
    var token: String? = nil
    
    var fontFamily: FontFamily? = nil
    var fontSize: FontSize? = nil
    var hasFinishedSetup: Bool = false
    
    var isLoggedIn: Bool {
        token != nil && !token!.isEmpty
    }
    
    mutating func setToken(_ newToken: String) {
        token = newToken
    }
}

protocol PSettingsRepository {
    func saveSettings(_ settings: Settings) async throws
    func loadSettings() async throws -> Settings?
    func clearSettings() async throws
    func saveToken(_ token: String) async throws
    func saveUsername(_ username: String) async throws
    func savePassword(_ password: String) async throws
    func saveHasFinishedSetup(_ hasFinishedSetup: Bool) async throws
    func saveServerSettings(endpoint: String, username: String, password: String, token: String) async throws 
    var hasFinishedSetup: Bool { get }
}

class SettingsRepository: PSettingsRepository {
    private let coreDataManager = CoreDataManager.shared
    private let userDefault = UserDefaults.standard
    
    func saveSettings(_ settings: Settings) async throws {
        let context = coreDataManager.context
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Vorhandene Einstellungen löschen
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    if let existingSettings = try context.fetch(fetchRequest).first {
                        
                        if let endpoint = settings.endpoint, !endpoint.isEmpty {
                            existingSettings.endpoint = endpoint
                        }
                        
                        if let username = settings.username, !username.isEmpty {
                            existingSettings.username = username
                        }
                        
                        if let password = settings.password, !password.isEmpty {
                            existingSettings.password = password
                        }
                        
                        if let token = settings.token, !token.isEmpty {
                            existingSettings.token = token
                        }
                                                
                        if let fontFamily = settings.fontFamily {
                            existingSettings.fontFamily = fontFamily.rawValue
                        }
                        
                        if let fontSize = settings.fontSize {
                            existingSettings.fontSize = fontSize.rawValue
                        }
                        
                        try context.save()
                    }
                    
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
                    
                    if let settingEntity = settingEntities.first {
                        let settings = Settings(
                            endpoint: settingEntity.endpoint ?? "",
                            username: settingEntity.username ?? "",
                            password: settingEntity.password ?? "",
                            token: settingEntity.token,
                            fontFamily: FontFamily(rawValue: settingEntity.fontFamily ?? FontFamily.system.rawValue),
                            fontSize: FontSize(rawValue: settingEntity.fontSize ?? FontSize.medium.rawValue)
                        )
                        continuation.resume(returning: settings)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func clearSettings() async throws {
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
        let context = coreDataManager.context
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    fetchRequest.fetchLimit = 1
                    
                    let settingEntities = try context.fetch(fetchRequest)
                    
                    if let settingEntity = settingEntities.first {
                        settingEntity.token = token
                    } else {
                        let settingEntity = SettingEntity(context: context)
                        settingEntity.token = token
                    }
                    
                    try context.save()
                    
                    // Wenn ein Token gespeichert wird, Setup als abgeschlossen markieren
                    if !token.isEmpty {
                        self.hasFinishedSetup = true
                        // Notification senden, dass sich der Setup-Status geändert hat
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name("SetupStatusChanged"), object: nil)
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveServerSettings(endpoint: String, username: String, password: String, token: String) async throws {
        let context = coreDataManager.context
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    fetchRequest.fetchLimit = 1
                    let settingEntities = try context.fetch(fetchRequest)
                    let settingEntity: SettingEntity
                    if let existing = settingEntities.first {
                        settingEntity = existing
                    } else {
                        settingEntity = SettingEntity(context: context)
                    }
                    settingEntity.endpoint = endpoint
                    settingEntity.username = username
                    settingEntity.password = password
                    settingEntity.token = token
                    try context.save()
                    // Wenn ein Token gespeichert wird, Setup als abgeschlossen markieren
                    if !token.isEmpty {
                        self.hasFinishedSetup = true
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name("SetupStatusChanged"), object: nil)
                        }
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveUsername(_ username: String) async throws {
        let context = coreDataManager.context
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    fetchRequest.fetchLimit = 1
                    
                    let settingEntities = try context.fetch(fetchRequest)
                    
                    if let settingEntity = settingEntities.first {
                        settingEntity.username = username
                    } else {
                        let settingEntity = SettingEntity(context: context)
                        settingEntity.username = username
                    }
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func savePassword(_ password: String) async throws {
        let context = coreDataManager.context
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    fetchRequest.fetchLimit = 1
                    
                    let settingEntities = try context.fetch(fetchRequest)
                    
                    if let settingEntity = settingEntities.first {
                        settingEntity.password = password
                    } else {
                        let settingEntity = SettingEntity(context: context)
                        settingEntity.password = password
                    }
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func saveHasFinishedSetup(_ hasFinishedSetup: Bool) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.hasFinishedSetup = hasFinishedSetup
            // Notification senden, dass sich der Setup-Status geändert hat
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("SetupStatusChanged"), object: nil)
            }
            continuation.resume()
        }
    }
    
    var hasFinishedSetup: Bool {
        get {
            return userDefault.value(forKey: "hasFinishedSetup") as? Bool ?? false
        }
        set {
            userDefault.set(newValue, forKey: "hasFinishedSetup")
        }
    }
}
