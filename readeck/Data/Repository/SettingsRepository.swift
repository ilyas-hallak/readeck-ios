import Foundation
import CoreData

struct Settings {
    let endpoint: String
    let username: String
    let password: String
    var token: String?
    
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
}

class SettingsRepository: PSettingsRepository {
    private let coreDataManager = CoreDataManager.shared
    
    func saveSettings(_ settings: Settings) async throws {
        let context = coreDataManager.context
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Vorhandene Einstellungen löschen
                    let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
                    let existingSettings = try context.fetch(fetchRequest)
                    for setting in existingSettings {
                        context.delete(setting)
                    }
                    
                    // Neue Einstellungen erstellen
                    let settingEntity = SettingEntity(context: context)
                    settingEntity.endpoint = settings.endpoint
                    settingEntity.username = settings.username
                    settingEntity.password = settings.password
                    settingEntity.token = settings.token
                    
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
                    
                    if let settingEntity = settingEntities.first {
                        let settings = Settings(
                            endpoint: settingEntity.endpoint ?? "",
                            username: settingEntity.username ?? "",
                            password: settingEntity.password ?? "",
                            token: settingEntity.token
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
                        // Fallback: Neue Einstellung erstellen (sollte normalerweise nicht passieren)
                        let settingEntity = SettingEntity(context: context)
                        settingEntity.token = token
                    }
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
