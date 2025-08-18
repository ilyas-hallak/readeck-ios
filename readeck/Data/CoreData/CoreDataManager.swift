import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private var isInMemoryStore = false
    private let logger = Logger.data
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        // Try to find the model in the main bundle first, then in extension bundle
        guard let modelURL = Bundle.main.url(forResource: "readeck", withExtension: "momd") ??
                             Bundle(for: CoreDataManager.self).url(forResource: "readeck", withExtension: "momd") else {
            logger.error("Could not find Core Data model file")
            fatalError("Core Data model 'readeck.xcdatamodeld' not found in bundle")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            logger.error("Could not load Core Data model from URL: \(modelURL)")
            fatalError("Failed to load Core Data model")
        }
        
        let container = NSPersistentContainer(name: "readeck", managedObjectModel: managedObjectModel)
        
        // Use App Group container for shared access with extensions
        let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.readeck.app")?.appendingPathComponent("readeck.sqlite")
        
        if let storeURL = storeURL {
            // Migrate existing database from app container to app group if needed
            migrateStoreToAppGroupIfNeeded(targetURL: storeURL)
            
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                self?.logger.error("Core Data failed to load persistent store: \(error)", file: #file, function: #function, line: #line)
                self?.setupInMemoryStore(container: container)
            } else {
                self?.logger.info("Core Data persistent store loaded successfully")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
                logger.debug("Core Data context saved successfully")
            } catch {
                logger.error("Failed to save Core Data context: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupInMemoryStore(container: NSPersistentContainer) {
        logger.warning("Setting up in-memory Core Data store as fallback")
        isInMemoryStore = true
        
        let inMemoryDescription = NSPersistentStoreDescription()
        inMemoryDescription.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [inMemoryDescription]
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                self?.logger.error("Failed to setup in-memory store: \(error.localizedDescription)")
                // Continue with empty container - app will work with reduced functionality
            } else {
                self?.logger.info("In-memory Core Data store setup successfully")
            }
        }
    }
    
    private func migrateStoreToAppGroupIfNeeded(targetURL: URL) {
        let fileManager = FileManager.default
        
        // Check if store already exists in app group
        if fileManager.fileExists(atPath: targetURL.path) {
            logger.info("Database already exists in app group container")
            return
        }
        
        // Try multiple possible old locations for database
        var searchPaths: [URL] = []
        
        // 1. App's documents directory (most common old location)
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            searchPaths.append(documentsURL)
        }
        
        // 2. App's library directory  
        if let libraryURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first {
            searchPaths.append(libraryURL)
        }
        
        // 3. App's support directory
        if let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            searchPaths.append(supportURL)
        }
        
        var foundOldStore = false
        
        for searchPath in searchPaths {
            let oldStoreURL = searchPath.appendingPathComponent("readeck.sqlite")
            
            if fileManager.fileExists(atPath: oldStoreURL.path) {
                logger.info("Found existing database at: \(oldStoreURL.path)")
                foundOldStore = true
                
                if migrateFromPath(oldStoreURL: oldStoreURL, targetURL: targetURL) {
                    break // Successfully migrated, stop searching
                }
            }
        }
        
        if !foundOldStore {
            logger.info("No existing database found in any search location - starting fresh")
        }
    }
    
    private func migrateFromPath(oldStoreURL: URL, targetURL: URL) -> Bool {
        let fileManager = FileManager.default
        let oldStoreWAL = oldStoreURL.appendingPathExtension("wal")
        let oldStoreSHM = oldStoreURL.appendingPathExtension("shm")
        
        logger.info("Migrating existing database from: \(oldStoreURL.path)")
        logger.info("Migrating existing database to: \(targetURL.path)")
        
        do {
            // Create app group directory if it doesn't exist
            let appGroupDirectory = targetURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: appGroupDirectory, withIntermediateDirectories: true)
            
            // Copy main database file
            try fileManager.copyItem(at: oldStoreURL, to: targetURL)
            logger.info("Main database file migrated successfully")
            
            // Copy WAL file if it exists
            if fileManager.fileExists(atPath: oldStoreWAL.path) {
                let targetWAL = targetURL.appendingPathExtension("wal")
                try fileManager.copyItem(at: oldStoreWAL, to: targetWAL)
                logger.info("WAL file migrated successfully")
            }
            
            // Copy SHM file if it exists
            if fileManager.fileExists(atPath: oldStoreSHM.path) {
                let targetSHM = targetURL.appendingPathExtension("shm")
                try fileManager.copyItem(at: oldStoreSHM, to: targetSHM)
                logger.info("SHM file migrated successfully")
            }
            
            // Remove old files after successful migration
            try fileManager.removeItem(at: oldStoreURL)
            if fileManager.fileExists(atPath: oldStoreWAL.path) {
                try fileManager.removeItem(at: oldStoreWAL)
            }
            if fileManager.fileExists(atPath: oldStoreSHM.path) {
                try fileManager.removeItem(at: oldStoreSHM)
            }
            
            logger.info("Database migration completed successfully")
            return true
            
        } catch {
            logger.error("Failed to migrate database from \(oldStoreURL.path): \(error.localizedDescription)")
            return false
        }
    }
    
    
}
