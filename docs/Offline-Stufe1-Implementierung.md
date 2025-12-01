# Offline Stufe 1: Smart Cache für Unread Items - Implementierungsplan

## Übersicht

Implementierung eines intelligenten Cache-Systems für ungelesene Artikel mit konfigurierbarer Anzahl (max. 100 Artikel). Die App lädt automatisch Artikel im Hintergrund herunter und macht sie offline verfügbar.

## Wichtigste Änderungen

### Offline-Modus Verhalten
- ✅ **Keine gecachten Artikel anzeigen per Icon**: Im Online-Modus gibt es KEINE Indikatoren für gecachte Artikel
- ✅ **Offline-Modus automatisch**: Wenn keine Netzwerkverbindung besteht, werden automatisch nur die gecachten Artikel angezeigt
- ✅ **Unaufdringlicher Banner**: Kleiner Banner über der Liste zeigt "Offline-Modus – Zeige gespeicherte Artikel"
- ✅ **Alle Tabs navigierbar**: User kann weiterhin durch alle Tabs navigieren (kein Full-Screen Error)
- ✅ **Intelligenter Sync**: Nur alle 4 Stunden beim App-Start (verhindert unnötige Syncs)
- ✅ **Background Sync**: Läuft mit niedriger Priorität (`.background`), keine Performance-Einbuße

### Technische Details
- 🔹 **Standard API-Call**: Nutzt `getBookmarks(state: .unread, limit: X)` für Sync
- 🔹 **CoreData mit JSON**: Speichert komplettes Bookmark-Objekt + HTML-Content
- 🔹 **Kingfisher für Bilder**: Bilder werden via Kingfisher gecacht (bereits im Projekt konfiguriert)
- 🔹 **FIFO Cleanup**: Automatisches Löschen ältester Artikel bei Überschreitung des Limits
- 🔹 **Default: 20 Artikel**: Reduziert initiale Sync-Last (21 API-Calls ohne Bilder)
- 🔹 **Background Priority**: Sync läuft mit `.background` oder `.utility` QoS (Quality of Service)

---

## Features

### Automatisches Caching
- **Beim App-Start**: Artikel werden automatisch heruntergeladen, wenn mehr als 4 Stunden seit letztem Sync vergangen sind
- **Intelligentes Timing**: Verhindert unnötige Syncs bei häufigem App-Öffnen
- **Background-Task mit niedriger Priorität**: Läuft mit `.background` oder `.utility` Priority
- **Nicht-blockierend**: User kann App normal nutzen während Sync läuft
- **Keine UI-Blockierung**: Sync läuft komplett im Hintergrund ohne Performance-Impact
- **Standard API-Call**: Nutzt den normalen `getBookmarks`-Endpoint mit entsprechenden Parametern

### Konfigurierbare Einstellungen
- Toggle für Offline-Reading (Ein/Aus, Default: true)
- Slider für Anzahl der zu cachenden Artikel (0-100, Default: 20)
- Toggle für Speichern von Bildern (Default: false)
- Manueller Sync-Button
- Anzeige des letzten Sync-Zeitpunkts

**Warum Default 20 Artikel?**
- Reduziert Netzwerk-Last beim initialen Sync
- Schnellerer erster Sync für bessere User Experience
- Bei 20 Artikeln: ~20 API-Calls für HTML + ggf. Bild-Downloads
- User kann bei Bedarf auf bis zu 100 erhöhen

### Offline-Modus Detection
- **Automatische Erkennung**: App erkennt automatisch, wenn keine Netzwerkverbindung besteht
- **Alle Tabs verfügbar**: User kann weiterhin durch alle Tabs navigieren
- **Unaufdringlicher Banner**: Kleiner Banner über den Unread-Artikeln zeigt Offline-Status
- **Gecachte Artikel anzeigen**: Nur gecachte Artikel werden im Offline-Modus angezeigt
- **Bestehende Error-Logik erweitern**: Nutzt vorhandene `isNetworkError` und zeigt gecachte Artikel statt Fehlermeldung

### Automatische Verwaltung
- FIFO-Prinzip: Älteste Artikel werden automatisch gelöscht, wenn neue hinzukommen
- Cache bleibt innerhalb der konfigurierten Grenzen
- Cleanup bei Logout oder Deaktivierung

### UI im Offline-Modus
- **Kein Full-Screen Error**: Stattdessen werden gecachte Artikel angezeigt
- **Offline-Banner**: Kleiner, unaufdringlicher Banner über der Liste
- **Alle Tabs navigierbar**: Keine Einschränkung der Navigation
- **Nur gecachte Inhalte**: Nur offline verfügbare Artikel werden angezeigt

---

## UI/UX Design - Settings

### Neue Settings-Sektion: "Offline-Reading"

```swift
Section {
    // Toggle für Offline-Reading
    Toggle("Offline-Reading", isOn: $offlineSettings.enabled)

    if offlineSettings.enabled {
        // Erklärungstext
        Text("Ungelesene Artikel werden automatisch heruntergeladen und sind offline verfügbar. Änderungen werden synchronisiert, sobald du wieder online bist.")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 4)

        // Anzahl Max Unread Articles
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Max. Artikel offline")
                Spacer()
                Text("\(Int(offlineSettings.maxUnreadArticles))")
                    .foregroundColor(.secondary)
            }
            Slider(
                value: $offlineSettings.maxUnreadArticles,
                in: 0...100,
                step: 10
            )
        }

        // Bilder speichern
        Toggle("Bilder speichern", isOn: $offlineSettings.saveImages)

        // Manual Sync Button
        Button(action: {
            Task {
                await offlineCacheManager.syncOfflineArticles()
            }
        }) {
            HStack {
                Text("Jetzt synchronisieren")
                Spacer()
                if offlineCacheManager.isSyncing {
                    ProgressView()
                }
            }
        }
        .disabled(offlineCacheManager.isSyncing)

        // Last Sync Date
        if let lastSync = offlineSettings.lastSyncDate {
            Text("Zuletzt synchronisiert: \(lastSync, formatter: relativeDateFormatter)")
                .font(.caption)
                .foregroundColor(.secondary)
        }

        // Cache-Größe
        if offlineCacheManager.cachedArticlesCount > 0 {
            HStack {
                Text("Gespeicherte Artikel")
                Spacer()
                Text("\(offlineCacheManager.cachedArticlesCount) Artikel, \(offlineCacheManager.cacheSize)")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
        }
    }
} header: {
    Text("Offline-Reading")
}
```

---

## Netzwerk-Flow beim Sync

Der Sync-Prozess läuft in mehreren Schritten ab, um Netzwerk-Last zu minimieren und Fehler besser zu behandeln:

### Schritt 1: Lade Bookmark-Liste
```
GET /api/bookmarks?is_archived=false&is_marked=false&limit=20
```
- Lädt die ersten N ungelesenen Artikel (Default: 20)
- Nutzt den bestehenden `getBookmarks`-Call mit entsprechenden Parametern
- Enthält alle Bookmark-Metadaten (Titel, URL, Datum, etc.)

### Schritt 2: Lade HTML für jeden Artikel
```
Für jeden Bookmark:
  GET /api/bookmarks/{id}/article
```
- **Sequenziell** für jeden Artikel (nicht parallel, um Server nicht zu überlasten)
- Lädt den kompletten HTML-Content des Artikels
- Bei Fehler: Artikel wird übersprungen, Sync läuft weiter

### Schritt 3: Extrahiere Bild-URLs (Optional)
```
Falls saveImages = true:
  - Parse HTML mit Regex nach <img src="...">
  - Extrahiere alle absolute URLs
  - Speichere URLs in CachedArticle.imageURLs
```
- Keine zusätzlichen API-Calls nötig
- URLs werden für Schritt 4 vorbereitet

### Schritt 4: Lade Bilder mit Kingfisher (Optional)
```
Falls saveImages = true:
  - Kingfisher ImagePrefetcher mit allen URLs
  - Lädt Bilder im Hintergrund
  - Fehler bei einzelnen Bildern stoppen Sync nicht
```
- **Parallel** durch Kingfisher (effizient)
- Nutzt bestehende Kingfisher-Cache-Konfiguration
- Automatisches Retry bei temporären Fehlern

### Schritt 5: Speichere in CoreData
```
Für jeden erfolgreichen Download:
  - Speichere Bookmark-JSON + HTML in CachedArticle
  - Speichere Metadaten (cachedDate, size, etc.)
```

### Schritt 6: Cleanup
```
- Lösche älteste Artikel wenn Limit überschritten
- Update lastSyncDate in Settings
```

### Beispiel-Rechnung für 20 Artikel:

**Ohne Bilder:**
- 1x API-Call für Bookmark-Liste
- 20x API-Calls für HTML (sequenziell)
- **Total: 21 API-Calls**
- Dauer: ~5-10 Sekunden (je nach Server-Geschwindigkeit)

**Mit Bildern (Ø 5 Bilder pro Artikel):**
- 1x API-Call für Bookmark-Liste
- 20x API-Calls für HTML (sequenziell)
- ~100x Image-Downloads (parallel durch Kingfisher)
- **Total: 121 Downloads**
- Dauer: ~15-30 Sekunden (je nach Bildgröße und Netzwerk)

### Fehlerbehandlung:
- **API-Fehler bei einzelnem Artikel**: Überspringen, nächsten versuchen
- **Netzwerk komplett weg**: Sync abbrechen, Fehlermeldung zeigen
- **Speicher voll**: Sync stoppen, User informieren
- **Partial Success**: Zeige "X von Y Artikeln synchronisiert"

### Background Task Priority

Um die App-Performance nicht zu beeinträchtigen, läuft der Sync mit niedriger Priorität:

```swift
// Sync mit Background Priority starten
Task.detached(priority: .background) {
    await offlineCacheSyncUseCase.syncOfflineArticles(settings: settings)
}
```

**Quality of Service (QoS) Optionen:**
- **`.background`** (Empfohlen): Niedrigste Priorität, läuft nur wenn System idle ist
- **`.utility`**: Niedrige Priorität, für länger laufende Tasks mit Fortschrittsanzeige
- **`.userInitiated`**: Nur für manuellen Sync-Button (User wartet aktiv)

**Vorteile:**
- ✅ Keine Blockierung der Main-Thread
- ✅ Keine spürbare Performance-Einbuße
- ✅ System kann Task pausieren bei Ressourcen-Knappheit
- ✅ Batterie-schonend durch intelligentes Scheduling

**Implementation Details:**
- Auto-Sync bei App-Start: `.background` Priority
- Manueller Sync-Button: `.utility` Priority (mit Progress-UI)
- Kingfisher Prefetch: Automatisch mit niedriger Priority

---

## Technische Implementierung

### 1. Datenmodelle

#### OfflineSettings Model
**Datei**: `readeck/Domain/Model/OfflineSettings.swift`

```swift
import Foundation

struct OfflineSettings: Codable {
    var enabled: Bool = true
    var maxUnreadArticles: Double = 20 // Double für Slider (Default: 20 Artikel)
    var saveImages: Bool = false
    var lastSyncDate: Date?

    var maxUnreadArticlesInt: Int {
        Int(maxUnreadArticles)
    }

    var shouldSyncOnAppStart: Bool {
        guard enabled else { return false }

        // Sync if never synced before
        guard let lastSync = lastSyncDate else { return true }

        // Sync if more than 4 hours since last sync
        let fourHoursAgo = Date().addingTimeInterval(-4 * 60 * 60)
        return lastSync < fourHoursAgo
    }
}
```

#### CachedArticle Entity (CoreData)
**Datei**: `readeck.xcdatamodeld` (CoreData Schema)

**WICHTIG**:
- Wir speichern sowohl den HTML-Content als auch die kompletten Bookmark-Metadaten als JSON, damit wir im Offline-Modus die Liste vollständig anzeigen können.
- **Bilder werden NICHT in CoreData gespeichert**, sondern über **Kingfisher** gecacht (bereits im Projekt vorhanden und konfiguriert).

```swift
entity CachedArticle {
    id: String (indexed, primary key)
    bookmarkId: String (indexed, unique)
    bookmarkJSON: String // Komplettes Bookmark-Objekt als JSON
    htmlContent: String // Artikel-HTML
    cachedDate: Date (indexed)
    lastAccessDate: Date
    size: Int64 // in Bytes (nur HTML, nicht Bilder)
    imageURLs: String? // Komma-separierte Liste der Bild-URLs (für Kingfisher Prefetch)
}
```

**Keine separate CachedImage Entity nötig** - Kingfisher verwaltet den Image-Cache automatisch mit den bestehenden Settings in [CacheSettingsView.swift](../readeck/UI/Settings/CacheSettingsView.swift)!

**Mapping Helpers**:

```swift
extension CachedArticle {
    func toBookmark() throws -> Bookmark {
        guard let json = bookmarkJSON,
              let data = json.data(using: .utf8) else {
            throw NSError(domain: "CachedArticle", code: 1, userInfo: nil)
        }

        return try JSONDecoder().decode(Bookmark.self, from: data)
    }

    static func from(bookmark: Bookmark, html: String, imageURLs: [String] = []) throws -> CachedArticle {
        let cached = CachedArticle()
        cached.id = UUID().uuidString
        cached.bookmarkId = bookmark.id

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(bookmark)
        cached.bookmarkJSON = String(data: jsonData, encoding: .utf8)

        cached.htmlContent = html
        cached.cachedDate = Date()
        cached.lastAccessDate = Date()
        cached.size = Int64(html.utf8.count)

        // Store image URLs for Kingfisher prefetch
        if !imageURLs.isEmpty {
            cached.imageURLs = imageURLs.joined(separator: ",")
        }

        return cached
    }

    func getImageURLs() -> [URL] {
        guard let imageURLs = imageURLs else { return [] }
        return imageURLs.split(separator: ",")
            .compactMap { URL(string: String($0)) }
    }
}
```

---

### 2. Repository Layer

#### PBookmarksRepository erweitern
**Datei**: `readeck/Domain/Protocols/PBookmarksRepository.swift`

```swift
protocol PBookmarksRepository {
    // ... existing methods

    // Offline Cache Methods
    func cacheBookmarkWithMetadata(bookmark: Bookmark, html: String, saveImages: Bool) async throws
    func getCachedArticle(id: String) -> String?
    func hasCachedArticle(id: String) -> Bool
    func getCachedArticlesCount() -> Int
    func getCacheSize() -> String
    func getCachedBookmarks() async throws -> [Bookmark]
    func clearCache() async throws
    func cleanupOldestCachedArticles(keepCount: Int) async throws
}
```

#### BookmarksRepository Implementation
**Datei**: `readeck/Data/Repository/BookmarksRepository.swift`

**WICHTIG**: Für das Caching der Artikel-Metadaten müssen wir das Bookmark-Objekt mit speichern, damit wir im Offline-Modus die komplette Liste anzeigen können.

Erweitern mit:

```swift
func cacheBookmarkWithMetadata(bookmark: Bookmark, html: String, saveImages: Bool) async throws {
    // 1. Prüfen ob bereits gecacht
    if hasCachedArticle(id: bookmark.id) {
        return
    }

    // 2. Bookmark + HTML speichern in CoreData
    let context = CoreDataManager.shared.context
    try await context.perform {
        let cachedArticle = CachedArticle(context: context)

        // Bookmark-Metadaten als JSON speichern
        let encoder = JSONEncoder()
        let bookmarkData = try encoder.encode(bookmark)
        let bookmarkJSON = String(data: bookmarkData, encoding: .utf8)

        cachedArticle.id = UUID().uuidString
        cachedArticle.bookmarkId = bookmark.id
        cachedArticle.bookmarkJSON = bookmarkJSON
        cachedArticle.htmlContent = html
        cachedArticle.cachedDate = Date()
        cachedArticle.lastAccessDate = Date()
        cachedArticle.size = Int64(html.utf8.count)
        cachedArticle.hasImages = saveImages

        CoreDataManager.shared.save()
    }

    // 3. Bilder mit Kingfisher prefetchen (außerhalb CoreData context)
    if saveImages {
        let imageURLs = extractImageURLsFromHTML(html: html)
        cachedArticle.imageURLs = imageURLs.joined(separator: ",")

        // Prefetch images with Kingfisher
        Task.detached {
            await self.prefetchImagesWithKingfisher(imageURLs: imageURLs)
        }
    }
}

private func extractImageURLsFromHTML(html: String) -> [String] {
    // Extract all <img src="..."> URLs from HTML
    var imageURLs: [String] = []

    // Simple regex pattern for img tags
    let pattern = #"<img[^>]+src=\"([^\"]+)\""#

    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
        let nsString = html as NSString
        let results = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))

        for result in results {
            if result.numberOfRanges >= 2 {
                let urlRange = result.range(at: 1)
                if let url = nsString.substring(with: urlRange) as String? {
                    // Handle relative URLs
                    if url.hasPrefix("http") {
                        imageURLs.append(url)
                    }
                }
            }
        }
    }

    return imageURLs
}

private func prefetchImagesWithKingfisher(imageURLs: [String]) async {
    let urls = imageURLs.compactMap { URL(string: $0) }

    guard !urls.isEmpty else { return }

    // Use Kingfisher's prefetcher mit niedriger Priorität
    let prefetcher = ImagePrefetcher(urls: urls) { skippedResources, failedResources, completedResources in
        print("Prefetch completed: \(completedResources.count)/\(urls.count) images cached")
        if !failedResources.isEmpty {
            print("Failed to cache \(failedResources.count) images")
        }
    }

    // Optional: Setze Download-Priority auf .low für Background-Downloads
    // prefetcher.options = [.downloadPriority(.low)]

    prefetcher.start()
}

func getCachedArticle(id: String) -> String? {
    let fetchRequest: NSFetchRequest<CachedArticle> = CachedArticle.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "bookmarkId == %@", id)
    fetchRequest.fetchLimit = 1

    do {
        let results = try CoreDataManager.shared.context.fetch(fetchRequest)
        if let cached = results.first {
            // Update last access date
            cached.lastAccessDate = Date()
            CoreDataManager.shared.save()
            return cached.htmlContent
        }
    } catch {
        print("Error fetching cached article: \(error)")
    }

    return nil
}

func hasCachedArticle(id: String) -> Bool {
    return getCachedArticle(id: id) != nil
}

func getCachedArticlesCount() -> Int {
    let fetchRequest: NSFetchRequest<CachedArticle> = CachedArticle.fetchRequest()
    return (try? CoreDataManager.shared.context.count(for: fetchRequest)) ?? 0
}

func getCacheSize() -> String {
    let fetchRequest: NSFetchRequest<CachedArticle> = CachedArticle.fetchRequest()

    do {
        let articles = try CoreDataManager.shared.context.fetch(fetchRequest)
        let totalBytes = articles.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    } catch {
        return "0 KB"
    }
}

func getCachedBookmarks() async throws -> [Bookmark] {
    let fetchRequest: NSFetchRequest<CachedArticle> = CachedArticle.fetchRequest()
    // Sort by cached date, newest first
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cachedDate", ascending: false)]

    let context = CoreDataManager.shared.context
    return try await context.perform {
        let cachedArticles = try context.fetch(fetchRequest)
        return cachedArticles.compactMap { cached -> Bookmark? in
            try? cached.toBookmark()
        }
    }
}

func clearCache() async throws {
    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CachedArticle.fetchRequest()
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

    try await CoreDataManager.shared.context.perform {
        try CoreDataManager.shared.context.execute(deleteRequest)
        CoreDataManager.shared.save()
    }

    // Optional: Auch Kingfisher-Cache löschen
    // KingfisherManager.shared.cache.clearDiskCache()
    // KingfisherManager.shared.cache.clearMemoryCache()
}

func cleanupOldestCachedArticles(keepCount: Int) async throws {
    let fetchRequest: NSFetchRequest<CachedArticle> = CachedArticle.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "cachedDate", ascending: true)]

    let context = CoreDataManager.shared.context
    try await context.perform {
        let allArticles = try context.fetch(fetchRequest)

        // Delete oldest articles if we exceed keepCount
        if allArticles.count > keepCount {
            let articlesToDelete = allArticles.prefix(allArticles.count - keepCount)
            articlesToDelete.forEach { context.delete($0) }
            CoreDataManager.shared.save()
        }
    }
}

```

**Wichtig zu Kingfisher**:
- Import erforderlich: `import Kingfisher` in BookmarksRepository.swift
- Kingfisher ist bereits konfiguriert mit Cache-Limits (siehe [CacheSettingsView.swift](../readeck/UI/Settings/CacheSettingsView.swift))
- Der User kann die Cache-Größe bereits in den Settings anpassen (50-1200 MB)
- Kingfisher verwaltet automatisch das Löschen alter Bilder basierend auf Speicherplatz-Limits
- Die `ImagePrefetcher` API lädt alle Bilder im Hintergrund herunter und cached sie

---

### 3. Use Cases

#### OfflineCacheSyncUseCase
**Datei**: `readeck/Domain/UseCase/OfflineCacheSyncUseCase.swift`

```swift
import Foundation
import Combine

protocol POfflineCacheSyncUseCase {
    var isSyncing: AnyPublisher<Bool, Never> { get }
    var syncProgress: AnyPublisher<String?, Never> { get }

    func syncOfflineArticles(settings: OfflineSettings) async
    func getCachedArticlesCount() -> Int
    func getCacheSize() -> String
}

// WICHTIG: Der UseCase selbst läuft synchron auf dem aufrufenden Thread.
// Die Background-Priority wird vom Caller gesetzt (z.B. Task.detached(priority: .background))
// Dadurch ist der UseCase flexibel für verschiedene Prioritäten:
// - Auto-Sync: .background
// - Manual-Sync: .utility oder .userInitiated

class OfflineCacheSyncUseCase: POfflineCacheSyncUseCase {
    private let bookmarksRepository: PBookmarksRepository
    private let settingsRepository: PSettingsRepository

    @Published private var _isSyncing = false
    @Published private var _syncProgress: String?

    var isSyncing: AnyPublisher<Bool, Never> {
        $_isSyncing.eraseToAnyPublisher()
    }

    var syncProgress: AnyPublisher<String?, Never> {
        $_syncProgress.eraseToAnyPublisher()
    }

    init(
        bookmarksRepository: PBookmarksRepository,
        settingsRepository: PSettingsRepository
    ) {
        self.bookmarksRepository = bookmarksRepository
        self.settingsRepository = settingsRepository
    }

    func syncOfflineArticles(settings: OfflineSettings) async {
        guard settings.enabled else { return }

        await MainActor.run {
            _isSyncing = true
            _syncProgress = "Lade ungelesene Artikel..."
        }

        do {
            // 1. Fetch unread bookmarks (limit by maxUnreadArticles)
            let bookmarksPage = try await bookmarksRepository.fetchBookmarks(
                state: .unread,
                limit: settings.maxUnreadArticlesInt,
                offset: nil,
                search: nil,
                type: nil,
                tag: nil
            )

            let bookmarks = bookmarksPage.bookmarks

            await MainActor.run {
                _syncProgress = "Laden \(bookmarks.count) Artikel..."
            }

            // 2. Download articles with metadata (sequenziell)
            var successCount = 0
            var skipCount = 0
            var errorCount = 0

            for (index, bookmark) in bookmarks.enumerated() {
                // Skip if already cached
                if bookmarksRepository.hasCachedArticle(id: bookmark.id) {
                    skipCount += 1
                    await MainActor.run {
                        _syncProgress = "Artikel \(index + 1)/\(bookmarks.count) (bereits gecacht)..."
                    }
                    continue
                }

                await MainActor.run {
                    _syncProgress = "Lade Artikel \(index + 1)/\(bookmarks.count)..."
                }

                // Download article HTML
                do {
                    let html = try await bookmarksRepository.fetchBookmarkArticle(id: bookmark.id)

                    // Cache article with bookmark metadata
                    try await bookmarksRepository.cacheBookmarkWithMetadata(
                        bookmark: bookmark,
                        html: html,
                        saveImages: settings.saveImages
                    )

                    successCount += 1

                    // Optional: Show image download progress
                    if settings.saveImages {
                        await MainActor.run {
                            _syncProgress = "Artikel \(index + 1)/\(bookmarks.count) + Bilder..."
                        }
                    }
                } catch {
                    print("Failed to cache article \(bookmark.id): \(error)")
                    errorCount += 1
                    continue
                }
            }

            // 3. Cleanup old articles (keep only maxUnreadArticles)
            try await bookmarksRepository.cleanupOldestCachedArticles(
                keepCount: settings.maxUnreadArticlesInt
            )

            // 4. Update last sync date
            var updatedSettings = settings
            updatedSettings.lastSyncDate = Date()
            try await settingsRepository.saveOfflineSettings(updatedSettings)

            // Show final status
            let statusMessage: String
            if errorCount == 0 && successCount > 0 {
                statusMessage = "✅ \(successCount) Artikel synchronisiert"
            } else if successCount > 0 && errorCount > 0 {
                statusMessage = "⚠️ \(successCount) synchronisiert, \(errorCount) fehlgeschlagen"
            } else if skipCount == bookmarks.count {
                statusMessage = "ℹ️ Alle Artikel bereits gecacht"
            } else {
                statusMessage = "❌ Synchronisierung fehlgeschlagen"
            }

            await MainActor.run {
                _isSyncing = false
                _syncProgress = statusMessage
            }

            // Clear success message after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                _syncProgress = nil
            }

        } catch {
            await MainActor.run {
                _isSyncing = false
                _syncProgress = "❌ Fehler: \(error.localizedDescription)"
            }

            // Clear error message after 5 seconds
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                _syncProgress = nil
            }
        }
    }

    func getCachedArticlesCount() -> Int {
        return bookmarksRepository.getCachedArticlesCount()
    }

    func getCacheSize() -> String {
        return bookmarksRepository.getCacheSize()
    }
}
```

---

### 4. Settings Repository

#### PSettingsRepository erweitern
**Datei**: `readeck/Domain/Protocols/PSettingsRepository.swift` (falls vorhanden, sonst neu erstellen)

```swift
protocol PSettingsRepository {
    func loadOfflineSettings() async throws -> OfflineSettings
    func saveOfflineSettings(_ settings: OfflineSettings) async throws
}
```

#### SettingsRepository Implementation
**Datei**: `readeck/Data/Repository/SettingsRepository.swift`

```swift
import Foundation

class SettingsRepository: PSettingsRepository {
    private let userDefaults = UserDefaults.standard
    private let offlineSettingsKey = "offlineSettings"

    func loadOfflineSettings() async throws -> OfflineSettings {
        guard let data = userDefaults.data(forKey: offlineSettingsKey) else {
            return OfflineSettings() // Default settings
        }

        let decoder = JSONDecoder()
        return try decoder.decode(OfflineSettings.self, from: data)
    }

    func saveOfflineSettings(_ settings: OfflineSettings) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)
        userDefaults.set(data, forKey: offlineSettingsKey)
    }
}
```

---

### 5. ViewModel für Settings

#### OfflineSettingsViewModel
**Datei**: `readeck/UI/Settings/OfflineSettingsViewModel.swift`

```swift
import Foundation
import Combine

@MainActor
class OfflineSettingsViewModel: ObservableObject {
    @Published var offlineSettings: OfflineSettings
    @Published var isSyncing = false
    @Published var syncProgress: String?
    @Published var cachedArticlesCount = 0
    @Published var cacheSize = "0 KB"

    private let settingsRepository: PSettingsRepository
    private let offlineCacheSyncUseCase: POfflineCacheSyncUseCase
    private var cancellables = Set<AnyCancellable>()

    init(
        settingsRepository: PSettingsRepository,
        offlineCacheSyncUseCase: POfflineCacheSyncUseCase
    ) {
        self.settingsRepository = settingsRepository
        self.offlineCacheSyncUseCase = offlineCacheSyncUseCase
        self.offlineSettings = OfflineSettings()

        setupBindings()

        Task {
            await loadSettings()
            updateCacheStats()
        }
    }

    private func setupBindings() {
        offlineCacheSyncUseCase.isSyncing
            .assign(to: &$isSyncing)

        offlineCacheSyncUseCase.syncProgress
            .assign(to: &$syncProgress)

        // Auto-save when settings change
        $offlineSettings
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] settings in
                Task {
                    try? await self?.settingsRepository.saveOfflineSettings(settings)
                }
            }
            .store(in: &cancellables)
    }

    func loadSettings() async {
        do {
            offlineSettings = try await settingsRepository.loadOfflineSettings()
        } catch {
            print("Failed to load offline settings: \(error)")
        }
    }

    func syncNow() async {
        // Manueller Sync mit höherer Priorität (.utility statt .background)
        // User wartet aktiv auf das Ergebnis und sieht Progress-UI
        await offlineCacheSyncUseCase.syncOfflineArticles(settings: offlineSettings)
        updateCacheStats()
    }

    func updateCacheStats() {
        cachedArticlesCount = offlineCacheSyncUseCase.getCachedArticlesCount()
        cacheSize = offlineCacheSyncUseCase.getCacheSize()
    }
}
```

---

### 6. Settings UI View

#### OfflineSettingsView
**Datei**: `readeck/UI/Settings/OfflineSettingsView.swift`

```swift
import SwiftUI

struct OfflineSettingsView: View {
    @StateObject private var viewModel: OfflineSettingsViewModel

    init(viewModel: OfflineSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Offline-Reading", isOn: $viewModel.offlineSettings.enabled)

                if viewModel.offlineSettings.enabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ungelesene Artikel werden automatisch heruntergeladen und sind offline verfügbar. Änderungen werden synchronisiert, sobald du wieder online bist.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Max. Artikel offline")
                            Spacer()
                            Text("\(viewModel.offlineSettings.maxUnreadArticlesInt)")
                                .foregroundColor(.secondary)
                        }
                        Slider(
                            value: $viewModel.offlineSettings.maxUnreadArticles,
                            in: 0...100,
                            step: 10
                        )
                    }

                    Toggle("Bilder speichern", isOn: $viewModel.offlineSettings.saveImages)

                    Button(action: {
                        Task {
                            await viewModel.syncNow()
                        }
                    }) {
                        HStack {
                            Text("Jetzt synchronisieren")
                            Spacer()
                            if viewModel.isSyncing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isSyncing)

                    if let syncProgress = viewModel.syncProgress {
                        Text(syncProgress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let lastSync = viewModel.offlineSettings.lastSyncDate {
                        Text("Zuletzt synchronisiert: \(lastSync, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if viewModel.cachedArticlesCount > 0 {
                        HStack {
                            Text("Gespeicherte Artikel")
                            Spacer()
                            Text("\(viewModel.cachedArticlesCount) Artikel, \(viewModel.cacheSize)")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                }
            } header: {
                Text("Offline-Reading")
            }
        }
        .navigationTitle("Offline-Reading")
        .onAppear {
            viewModel.updateCacheStats()
        }
    }
}
```

---

### 7. Integration in SettingsContainerView

**Datei**: `readeck/UI/Settings/SettingsContainerView.swift`

In der bestehenden Settings-View einen neuen NavigationLink hinzufügen:

```swift
Section {
    NavigationLink(destination: OfflineSettingsView(
        viewModel: DefaultUseCaseFactory.shared.makeOfflineSettingsViewModel()
    )) {
        Label("Offline-Reading", systemImage: "arrow.down.circle")
    }

    // ... existing settings items
} header: {
    Text("Allgemein")
}
```

---

### 8. Factory Erweiterung

**Datei**: `readeck/UI/Factory/DefaultUseCaseFactory.swift`

Erweitern mit:

```swift
// MARK: - Offline Settings

func makeOfflineSettingsViewModel() -> OfflineSettingsViewModel {
    return OfflineSettingsViewModel(
        settingsRepository: makeSettingsRepository(),
        offlineCacheSyncUseCase: makeOfflineCacheSyncUseCase()
    )
}

private func makeSettingsRepository() -> PSettingsRepository {
    return SettingsRepository()
}

private func makeOfflineCacheSyncUseCase() -> POfflineCacheSyncUseCase {
    return OfflineCacheSyncUseCase(
        bookmarksRepository: BookmarksRepository(api: API()),
        settingsRepository: makeSettingsRepository()
    )
}
```

---

### 9. Automatischer Sync mit 4-Stunden-Check

#### App-Start Sync mit Background Priority
**Datei**: `readeck/UI/AppViewModel.swift`

Erweitern um:

```swift
@MainActor
func onAppStart() async {
    await checkServerReachability()
    syncOfflineArticlesIfNeeded() // Kein await! Läuft im Hintergrund
}

private func syncOfflineArticlesIfNeeded() {
    let settingsRepo = SettingsRepository()

    // Starte Background Task mit niedriger Priorität
    Task.detached(priority: .background) {
        guard let settings = try? await settingsRepo.loadOfflineSettings() else {
            return
        }

        // Check if sync is needed (enabled + more than 4 hours)
        if settings.shouldSyncOnAppStart {
            let syncUseCase = DefaultUseCaseFactory.shared.makeOfflineCacheSyncUseCase()
            await syncUseCase.syncOfflineArticles(settings: settings)
        }
    }
}
```

**Wichtig**: Kein `await` vor `syncOfflineArticlesIfNeeded()`, damit der App-Start nicht blockiert wird!

In `readeckApp.swift`:

```swift
.task {
    await appViewModel.onAppStart()
}
```

---

### 10. Offline-Modus UI-Anpassungen

#### BookmarksViewModel erweitern
**Datei**: `readeck/UI/Bookmarks/BookmarksViewModel.swift`

Erweitern um gecachte Bookmarks zu laden:

```swift
@MainActor
func loadBookmarks(state: BookmarkState = .unread, type: [BookmarkType] = [.article], tag: String? = nil) async {
    guard !isUpdating else { return }
    isUpdating = true
    defer { isUpdating = false }

    isLoading = true
    errorMessage = nil
    currentState = state
    currentType = type
    currentTag = tag

    offset = 0
    hasMoreData = true

    do {
        let newBookmarks = try await getBooksmarksUseCase.execute(
            state: state,
            limit: limit,
            offset: offset,
            search: searchQuery,
            type: type,
            tag: tag
        )
        bookmarks = newBookmarks
        hasMoreData = newBookmarks.currentPage != newBookmarks.totalPages
        isNetworkError = false
    } catch {
        // Check if it's a network error
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost:
                isNetworkError = true
                errorMessage = "No internet connection"

                // NEUE LOGIK: Versuche gecachte Bookmarks zu laden
                await loadCachedBookmarks()
            default:
                isNetworkError = false
                errorMessage = "Error loading bookmarks"
            }
        } else {
            isNetworkError = false
            errorMessage = "Error loading bookmarks"
        }
    }

    isLoading = false
    isInitialLoading = false
}

private func loadCachedBookmarks() async {
    // Load cached bookmarks from repository
    let bookmarksRepository = BookmarksRepository(api: API())

    do {
        let cachedBookmarks = try await bookmarksRepository.getCachedBookmarks()

        if !cachedBookmarks.isEmpty {
            // Show cached bookmarks
            bookmarks = BookmarksPage(
                bookmarks: cachedBookmarks,
                currentPage: 1,
                totalCount: cachedBookmarks.count,
                totalPages: 1,
                links: nil
            )
            hasMoreData = false

            // Keep error message to show offline banner
            // But don't show full-screen error
        }
    } catch {
        print("Failed to load cached bookmarks: \(error)")
    }
}
```

#### BookmarksView erweitern - Offline-Banner
**Datei**: `readeck/UI/Bookmarks/BookmarksView.swift`

Anpassen der UI, um im Offline-Modus einen Banner zu zeigen statt Full-Screen-Error:

```swift
var body: some View {
    ZStack {
        VStack(spacing: 0) {
            // Offline-Banner - nur bei Network-Error und wenn Bookmarks vorhanden
            if viewModel.isNetworkError && !(viewModel.bookmarks?.bookmarks.isEmpty ?? true) {
                offlineBanner
            }

            // Content
            if viewModel.isInitialLoading && (viewModel.bookmarks?.bookmarks.isEmpty != false) {
                skeletonLoadingView
            } else if shouldShowCenteredState {
                centeredStateView
            } else {
                bookmarksList
            }
        }

        // FAB Button - only show for "Unread" and when not in error/loading state
        if (state == .unread || state == .all) && !shouldShowCenteredState && !viewModel.isInitialLoading {
            fabButton
        }
    }
    // ... rest of modifiers
}

// Offline-Banner über der Liste
private var offlineBanner: some View {
    HStack(spacing: 8) {
        Image(systemName: "wifi.slash")
            .font(.caption)
            .foregroundColor(.secondary)

        Text("Offline-Modus – Zeige gespeicherte Artikel")
            .font(.caption)
            .foregroundColor(.secondary)

        Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(Color(.systemGray6))
}

// Anpassen der Error-Logic
private var shouldShowCenteredState: Bool {
    let isEmpty = viewModel.bookmarks?.bookmarks.isEmpty == true
    let hasError = viewModel.errorMessage != nil

    // Zeige Full-Screen Error nur wenn leer UND Error (nicht bei gecachten Bookmarks)
    return isEmpty && hasError
}
```

---

### 11. Offline-Artikel Laden

**Datei**: `readeck/UI/BookmarkDetail/BookmarkDetailViewModel.swift`

```swift
func loadArticle() async {
    isLoading = true

    do {
        // 1. Versuche zuerst aus Cache zu laden
        if let cachedHTML = bookmarksRepository.getCachedArticle(id: bookmarkId) {
            await MainActor.run {
                self.articleHTML = cachedHTML
                self.isLoading = false
            }
            return
        }

        // 2. Falls nicht gecacht, vom Server laden
        let html = try await getBookmarkArticleUseCase.execute(id: bookmarkId)

        await MainActor.run {
            self.articleHTML = html
            self.isLoading = false
        }

        // 3. Optional: Im Hintergrund cachen
        Task.detached(priority: .background) {
            let settings = try? await SettingsRepository().loadOfflineSettings()
            if settings?.enabled == true {
                try? await self.bookmarksRepository.cacheBookmarkArticle(
                    id: self.bookmarkId,
                    html: html,
                    saveImages: settings?.saveImages ?? false
                )
            }
        }

    } catch {
        await MainActor.run {
            self.error = error
            self.isLoading = false
        }
    }
}
```

---

## Dateien die erstellt/geändert werden müssen

### Neu zu erstellen:
1. ✅ `readeck/Domain/Model/OfflineSettings.swift`
2. ✅ `readeck/Domain/UseCase/OfflineCacheSyncUseCase.swift`
3. ✅ `readeck/Domain/Protocols/PSettingsRepository.swift` (falls nicht vorhanden)
4. ✅ `readeck/Data/Repository/SettingsRepository.swift`
5. ✅ `readeck/UI/Settings/OfflineSettingsViewModel.swift`
6. ✅ `readeck/UI/Settings/OfflineSettingsView.swift`
7. ✅ CoreData Entity: `CachedArticle` (mit imageURLs für Kingfisher)

### Zu erweitern:
1. ✅ `readeck/Domain/Protocols/PBookmarksRepository.swift` - Neue Methoden für Offline-Cache
2. ✅ `readeck/Data/Repository/BookmarksRepository.swift` - Implementation mit **Kingfisher ImagePrefetcher**
3. ✅ `readeck/UI/Settings/SettingsContainerView.swift` - NavigationLink zu Offline-Settings
4. ✅ `readeck/UI/Factory/DefaultUseCaseFactory.swift` - Factory-Methoden für neue ViewModels/UseCases
5. ✅ `readeck/UI/AppViewModel.swift` - Auto-Sync bei App-Start (4-Stunden-Check)
6. ✅ `readeck/UI/Bookmarks/BookmarksViewModel.swift` - Laden gecachter Bookmarks bei Network-Error
7. ✅ `readeck/UI/Bookmarks/BookmarksView.swift` - Offline-Banner statt Full-Screen Error
8. ✅ `readeck/UI/BookmarkDetail/BookmarkDetailViewModel.swift` - Offline-First Artikel-Laden
9. ✅ `readeck.xcdatamodeld` - CoreData Schema

### Keine Änderung nötig (bereits vorhanden):
- ✅ **Kingfisher** - Bereits im Projekt integriert und konfiguriert
- ✅ **CacheSettingsView** - User kann bereits Image-Cache-Größe anpassen (50-1200 MB)

---

## Testing Checklist

### Unit Tests
- [ ] OfflineCacheSyncUseCase: Sync-Logic
- [ ] SettingsRepository: Save/Load Settings
- [ ] BookmarksRepository: Cache CRUD Operations
- [ ] Cleanup-Logic: FIFO Prinzip
- [ ] Image URL Extraction aus HTML
- [ ] Kingfisher Prefetch Integration

### Integration Tests
- [ ] App-Start → Auto-Sync (nur bei >4 Stunden)
- [ ] Settings ändern → Auto-Save
- [ ] Offline-Artikel laden → Cache-Fallback
- [ ] Network-Error → Gecachte Bookmarks anzeigen
- [ ] Bilder werden mit Kingfisher gecacht

### UI Tests
- [ ] Settings Toggle aktivieren/deaktivieren
- [ ] Slider-Werte ändern
- [ ] Manual Sync Button
- [ ] Offline-Banner wird angezeigt bei Network-Error
- [ ] Cache-Statistiken anzeigen
- [ ] Alle Tabs bleiben navigierbar im Offline-Modus

### Edge Cases
- [ ] Netzwerk-Loss während Sync
- [ ] App-Kill während Download
- [ ] Speicher voll
- [ ] Cache löschen bei Logout
- [ ] Deaktivieren von Offline-Reading löscht Cache
- [ ] 4-Stunden-Check verhindert unnötige Syncs
- [ ] Kingfisher Cache-Limit wird respektiert

---

## Nächste Schritte

### Phase 1: Core-Funktionalität (1-2 Tage)
1. CoreData Schema erstellen (CachedArticle Entity mit imageURLs)
2. OfflineSettings Model + Repository implementieren (Default: 20 Artikel)
3. BookmarksRepository um Cache-Methoden erweitern:
   - `cacheBookmarkWithMetadata()` mit HTML-Parsing
   - Kingfisher ImagePrefetcher Integration
   - `getCachedBookmarks()` für Offline-Modus

### Phase 2: Sync-Logic (1-2 Tage)
4. OfflineCacheSyncUseCase implementieren:
   - Sequenzieller Download (21 API-Calls für 20 Artikel)
   - Progress-Tracking mit Success/Error/Skip Counts
   - Fehlerbehandlung für einzelne Artikel
5. 4-Stunden-Check in `shouldSyncOnAppStart`
6. FIFO Cleanup-Logic

### Phase 3: UI Integration (1 Tag)
7. OfflineSettingsView erstellen:
   - Slider mit Default 20, Max 100
   - Manual Sync Button mit Progress
   - Last Sync Date + Cache Stats
8. Integration in SettingsContainerView
9. Factory erweitern für alle neuen Dependencies

### Phase 4: Offline-Modus (1 Tag)
10. BookmarksViewModel erweitern:
    - `loadCachedBookmarks()` bei Network-Error
    - Offline-Banner statt Full-Screen Error
11. BookmarkDetailViewModel: Cache-First Loading
12. Auto-Sync bei App-Start

### Phase 5: Testing & Polish (1-2 Tage)
13. Unit Tests für Sync-Logic & Cache-Operations
14. Integration Tests für Offline-Flow
15. UI Tests für Settings & Offline-Banner
16. Performance Testing mit 100 Artikeln
17. Bug-Fixing & Edge Cases

**Geschätzte Gesamtdauer: 5-8 Tage**

---

## Zusammenfassung: Kingfisher Integration

### Warum Kingfisher?
- ✅ **Bereits im Projekt**: Kingfisher ist bereits integriert und konfiguriert
- ✅ **User-konfigurierbar**: Cache-Größe ist in Settings anpassbar (50-1200 MB)
- ✅ **Automatisches Management**: LRU-Cache mit automatischer Größenverwaltung
- ✅ **Performant**: Optimiert für iOS mit Memory & Disk Caching

### Wie funktioniert es?
1. **HTML Parsen**: Image-URLs werden aus dem HTML extrahiert via Regex
2. **URLs speichern**: In CoreData als komma-separierte Liste (für spätere Verwendung)
3. **Kingfisher Prefetch**: `ImagePrefetcher` lädt alle Bilder im Hintergrund
4. **Automatisches Caching**: Kingfisher speichert Bilder auf Disk
5. **WebView lädt Bilder**: Beim Öffnen des Artikels lädt WebView Bilder aus Kingfisher-Cache

### Cache-Management
- **Existierende Settings nutzen**: `CacheSettingsView` erlaubt User Cache-Größe zu setzen
- **Automatic Cleanup**: Kingfisher löscht automatisch alte Bilder bei Speicherplatz-Knappheit
- **Separate von Artikel-Cache**: Bilder und HTML werden getrennt verwaltet
- **Optional cleanup**: Bei `clearCache()` kann Kingfisher-Cache mit geleert werden

### Vorteile gegenüber CoreData für Bilder
- 🚀 **Bessere Performance**: Optimiert für Bilder
- 💾 **Weniger Speicher**: Kompression & Deduplizierung
- 🔄 **Weniger Code**: Keine eigene Image-Download-Logic nötig
- ⚙️ **Konfigurierbar**: User kann Limits selbst setzen

---

*Erstellt: 2025-11-01*
*Aktualisiert: 2025-11-01 (Kingfisher Integration)*
*Basierend auf: Offline-Konzept.md - Stufe 1*
