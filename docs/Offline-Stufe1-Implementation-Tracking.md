# Offline Stufe 1 - Implementierungs-Tracking

**Branch**: `offline-sync`
**Start**: 2025-11-01
**Geschätzte Dauer**: 5-8 Tage

---

## Phase 1: Foundation & Models (Tag 1)

### 1.1 Logging-Kategorie erweitern
**Datei**: `readeck/Utils/Logger.swift`

- [x] `LogCategory.sync` zur enum hinzufügen
- [x] `Logger.sync` zur Extension hinzufügen
- [x] Testen: Logging funktioniert

**Code-Änderungen**:
```swift
enum LogCategory: String, CaseIterable, Codable {
    // ... existing
    case sync = "Sync"
}

extension Logger {
    // ... existing
    static let sync = Logger(category: .sync)
}
```

---

### 1.2 Domain Model: OfflineSettings
**Neue Datei**: `readeck/Domain/Model/OfflineSettings.swift`

- [x] Struct OfflineSettings erstellen
- [x] Properties hinzufügen:
  - [x] `enabled: Bool = true`
  - [x] `maxUnreadArticles: Double = 20`
  - [x] `saveImages: Bool = false`
  - [x] `lastSyncDate: Date?`
- [x] Computed Property `maxUnreadArticlesInt` implementieren
- [x] Computed Property `shouldSyncOnAppStart` implementieren (4-Stunden-Check)
- [x] Codable Conformance
- [x] Testen: shouldSyncOnAppStart Logic

**Checklist**:
- [x] File erstellt
- [x] Alle Properties vorhanden
- [x] 4-Stunden-Check funktioniert
- [x] Kompiliert ohne Fehler

---

### 1.3 CoreData Entity: BookmarkEntity erweitert
**Datei**: `readeck.xcdatamodeld`

- [x] BookmarkEntity mit Cache-Feldern erweitern
- [x] Attributes definieren:
  - [x] `htmlContent` (String)
  - [x] `cachedDate` (Date, indexed)
  - [x] `lastAccessDate` (Date)
  - [x] `cacheSize` (Integer 64)
  - [x] `imageURLs` (String, optional)
- [x] Lightweight Migration
- [x] Testen: App startet ohne Crash, keine Migration-Fehler

**Checklist**:
- [x] Cache-Felder hinzugefügt
- [x] Alle Attributes vorhanden
- [x] Indexes gesetzt
- [x] Migration funktioniert
- [x] App startet erfolgreich

---

## Phase 2: Data Layer (Tag 1-2)

### 2.1 Settings Repository Protocol
**Neue Datei**: `readeck/Domain/Protocols/PSettingsRepository.swift`

- [x] Protocol `PSettingsRepository` erweitern
- [x] Methode `loadOfflineSettings()` definieren
- [x] Methode `saveOfflineSettings(_ settings: OfflineSettings)` definieren

**Checklist**:
- [x] Protocol erweitert
- [x] Methoden deklariert
- [x] Kompiliert ohne Fehler

---

### 2.2 Settings Repository Implementation
**Datei**: `readeck/Data/Repository/SettingsRepository.swift`

- [x] Class `SettingsRepository` erweitert
- [x] `PSettingsRepository` implementiert
- [x] `loadOfflineSettings()` implementiert:
  - [x] UserDefaults laden
  - [x] JSON dekodieren
  - [x] Default-Settings zurückgeben bei Fehler
  - [x] Logger.data für Erfolgsmeldung
- [x] `saveOfflineSettings()` implementiert:
  - [x] JSON enkodieren
  - [x] UserDefaults speichern
  - [x] Logger.data für Erfolgsmeldung
- [x] Kompiliert ohne Fehler

**Checklist**:
- [x] File erweitert (Zeilen 274-296)
- [x] loadOfflineSettings() implementiert
- [x] saveOfflineSettings() implementiert
- [x] Logging integriert
- [x] Kompiliert erfolgreich

---

### 2.3 OfflineCacheRepository Protocol (ARCHITEKTUR-ÄNDERUNG)
**Neue Datei**: `readeck/Domain/Protocols/POfflineCacheRepository.swift`

**HINWEIS:** Anstatt `PBookmarksRepository` zu erweitern, wurde ein separates `POfflineCacheRepository` erstellt für **Clean Architecture** und Separation of Concerns.

- [x] Protocol `POfflineCacheRepository` erstellen
- [x] Neue Methoden zum Protocol hinzufügen:
  - [x] `cacheBookmarkWithMetadata(bookmark:html:saveImages:) async throws`
  - [x] `getCachedArticle(id:) -> String?`
  - [x] `hasCachedArticle(id:) -> Bool`
  - [x] `getCachedBookmarks() async throws -> [Bookmark]`
  - [x] `getCachedArticlesCount() -> Int`
  - [x] `getCacheSize() -> String`
  - [x] `clearCache() async throws`
  - [x] `cleanupOldestCachedArticles(keepCount:) async throws`

**Checklist**:
- [x] Protocol erstellt (Zeilen 1-24)
- [x] Alle Methoden deklariert
- [x] Async/throws korrekt gesetzt
- [x] Kompiliert ohne Fehler

---

### 2.4 OfflineCacheRepository Implementation (ARCHITEKTUR-ÄNDERUNG)
**Neue Datei**: `readeck/Data/Repository/OfflineCacheRepository.swift`

- [x] `import Kingfisher` hinzugefügt
- [x] `cacheBookmarkWithMetadata()` implementiert:
  - [x] Prüfen ob bereits gecacht
  - [x] Bookmark in CoreData speichern via BookmarkEntity
  - [x] CoreData BookmarkEntity erweitern
  - [x] Speichern in CoreData
  - [x] Logger.sync.info
  - [x] Bei saveImages: extractImageURLsFromHTML() aufrufen
  - [x] Bei saveImages: prefetchImagesWithKingfisher() aufrufen
- [x] `extractImageURLsFromHTML()` implementiert:
  - [x] Regex für `<img src="...">` Tags
  - [x] URLs extrahieren
  - [x] Nur absolute URLs (http/https)
  - [x] Logger.sync.debug
- [x] `prefetchImagesWithKingfisher()` implementiert:
  - [x] URLs zu URL-Array konvertieren
  - [x] ImagePrefetcher erstellt
  - [x] Callback mit Logging
  - [x] prefetcher.start()
  - [x] Logger.sync.info
- [x] `getCachedArticle()` implementiert:
  - [x] NSFetchRequest mit predicate
  - [x] lastAccessDate updaten
  - [x] htmlContent zurückgeben
- [x] `hasCachedArticle()` implementiert
- [x] `getCachedBookmarks()` implementiert:
  - [x] Fetch alle BookmarkEntity mit htmlContent
  - [x] Sort by cachedDate descending
  - [x] toDomain() mapper nutzen
  - [x] Array zurückgeben
- [x] `getCachedArticlesCount()` implementiert
- [x] `getCacheSize()` implementiert:
  - [x] Alle sizes summieren
  - [x] ByteCountFormatter nutzen
- [x] `clearCache()` implementiert:
  - [x] Cache-Felder auf nil setzen
  - [x] Logger.sync.info
- [x] `cleanupOldestCachedArticles()` implementiert:
  - [x] Sort by cachedDate ascending
  - [x] Älteste löschen wenn > keepCount
  - [x] Logger.sync.info

**Checklist**:
- [x] File erstellt (272 Zeilen)
- [x] Kingfisher import
- [x] Alle Methoden implementiert
- [x] Logging überall integriert
- [x] Kompiliert ohne Fehler

---

## Phase 3: Use Case & Business Logic (Tag 2)

### 3.1 OfflineCacheSyncUseCase Protocol
**Neue Datei**: `readeck/Domain/UseCase/OfflineCacheSyncUseCase.swift`

- [x] Protocol `POfflineCacheSyncUseCase` erstellen
- [x] Published Properties definieren:
  - [x] `var isSyncing: AnyPublisher<Bool, Never>`
  - [x] `var syncProgress: AnyPublisher<String?, Never>`
- [x] Methoden deklarieren:
  - [x] `func syncOfflineArticles(settings:) async`
  - [x] `func getCachedArticlesCount() -> Int`
  - [x] `func getCacheSize() -> String`

**Checklist**:
- [x] File erstellt
- [x] Protocol definiert (Zeilen 11-20)
- [x] Methoden deklariert
- [x] Kompiliert ohne Fehler

---

### 3.2 OfflineCacheSyncUseCase Implementation
**Datei**: `readeck/Domain/UseCase/OfflineCacheSyncUseCase.swift` (im selben File)

- [x] Class `OfflineCacheSyncUseCase` erstellen
- [x] Dependencies:
  - [x] `offlineCacheRepository: POfflineCacheRepository`
  - [x] `bookmarksRepository: PBookmarksRepository`
  - [x] `settingsRepository: PSettingsRepository`
- [x] CurrentValueSubject für State (statt @Published):
  - [x] `_isSyncingSubject = CurrentValueSubject<Bool, Never>(false)`
  - [x] `_syncProgressSubject = CurrentValueSubject<String?, Never>(nil)`
- [x] Publishers als computed properties
- [x] `syncOfflineArticles()` implementieren:
  - [x] Guard enabled check
  - [x] Logger.sync.info("Starting sync")
  - [x] Set isSyncing = true
  - [x] Fetch bookmarks (state: .unread, limit: settings.maxUnreadArticlesInt)
  - [x] Logger.sync.info("Fetched X bookmarks")
  - [x] Loop durch Bookmarks:
    - [x] Skip wenn bereits gecacht (Logger.sync.debug)
    - [x] syncProgress updaten: "Artikel X/Y..."
    - [x] fetchBookmarkArticle() aufrufen
    - [x] cacheBookmarkWithMetadata() aufrufen
    - [x] successCount++
    - [x] Bei saveImages: syncProgress "...+ Bilder"
    - [x] Catch: errorCount++, Logger.sync.error
  - [x] cleanupOldestCachedArticles() aufrufen
  - [x] lastSyncDate updaten
  - [x] Logger.sync.info("✅ Synced X, skipped Y, failed Z")
  - [x] Set isSyncing = false
  - [x] syncProgress = Status-Message
  - [x] Sleep 3s, dann syncProgress = nil
- [x] `getCachedArticlesCount()` implementieren
- [x] `getCacheSize()` implementieren
- [x] Error-Handling:
  - [x] Catch block für Haupt-Try
  - [x] Logger.sync.error
  - [x] syncProgress = Error-Message

**Checklist**:
- [x] Class erstellt (159 Zeilen)
- [x] Dependencies injiziert (3 repositories)
- [x] syncOfflineArticles() komplett mit @MainActor
- [x] Success/Skip/Error Tracking
- [x] Logging an allen wichtigen Stellen
- [x] Progress-Updates mit Emojis
- [x] Error-Handling
- [x] getCachedArticlesCount() fertig
- [x] getCacheSize() fertig
- [x] Kompiliert ohne Fehler

---

## Phase 4: Settings UI (Tag 3)

### 4.1 OfflineSettingsViewModel
**Neue Datei**: `readeck/UI/Settings/OfflineSettingsViewModel.swift`

- [x] Class mit @Observable (ohne @MainActor auf Klassenebene)
- [x] Properties:
  - [x] `offlineSettings: OfflineSettings`
  - [x] `isSyncing = false`
  - [x] `syncProgress: String?`
  - [x] `cachedArticlesCount = 0`
  - [x] `cacheSize = "0 KB"`
- [x] Dependencies:
  - [x] `settingsRepository: PSettingsRepository`
  - [x] `offlineCacheSyncUseCase: POfflineCacheSyncUseCase`
- [x] Init mit Factory
- [x] `setupBindings()` implementiert:
  - [x] isSyncing Publisher binden
  - [x] syncProgress Publisher binden
- [x] `loadSettings()` implementiert mit @MainActor
- [x] `saveSettings()` implementiert mit @MainActor
- [x] `syncNow()` implementiert mit @MainActor:
  - [x] await offlineCacheSyncUseCase.syncOfflineArticles()
  - [x] updateCacheStats()
- [x] `updateCacheStats()` implementiert mit @MainActor

**Checklist**:
- [x] File erstellt (89 Zeilen)
- [x] Properties definiert
- [x] Dependencies via Factory injiziert
- [x] setupBindings() mit Combine
- [x] Alle Methoden mit @MainActor markiert
- [x] Kompiliert ohne Fehler

---

### 4.2 OfflineSettingsView
**Neue Datei**: `readeck/UI/Settings/OfflineSettingsView.swift`

- [x] Struct `OfflineSettingsView: View`
- [x] @State viewModel
- [x] Body implementiert:
  - [x] Section mit "Offline-Reading" header
  - [x] Toggle: "Offline-Reading aktivieren" gebunden an enabled
  - [x] If enabled:
    - [x] VStack: Erklärungstext (caption, secondary)
    - [x] VStack: Slider "Max. Artikel offline" (0-100, step 10)
    - [x] HStack: Anzeige aktueller Wert
    - [x] Toggle: "Bilder speichern" mit Erklärung
    - [x] Button: "Jetzt synchronisieren" mit ProgressView
    - [x] If syncProgress: Text anzeigen (caption)
    - [x] If lastSyncDate: Text "Zuletzt: relative"
    - [x] If cachedArticlesCount > 0: HStack mit Stats
- [x] task: loadSettings() bei Erscheinen
- [x] onChange Handler für alle Settings (auto-save)

**Checklist**:
- [x] File erstellt (145 Zeilen)
- [x] Form Structure mit Section
- [x] Toggle für enabled mit Erklärung
- [x] Slider für maxUnreadArticles mit Wert-Anzeige
- [x] Toggle für saveImages
- [x] Sync-Button mit Progress und Icon
- [x] Stats-Anzeige (Artikel + Größe)
- [x] Preview mit MockFactory
- [x] Kompiliert ohne Fehler

---

### 4.3 SettingsContainerView Integration
**Datei**: `readeck/UI/Settings/SettingsContainerView.swift`

- [x] OfflineSettingsView direkt eingebettet (kein NavigationLink)
- [x] Nach SyncSettingsView platziert
- [x] Konsistent mit anderen Settings-Sections

**Checklist**:
- [x] OfflineSettingsView() hinzugefügt (Zeile 28)
- [x] Korrekte Platzierung in der Liste
- [x] Kompiliert ohne Fehler

---

### 4.4 Factory erweitern
**Dateien**: `readeck/UI/Factory/DefaultUseCaseFactory.swift` + `MockUseCaseFactory.swift`

- [x] Protocol `UseCaseFactory` erweitert:
  - [x] `makeSettingsRepository() -> PSettingsRepository`
  - [x] `makeOfflineCacheSyncUseCase() -> POfflineCacheSyncUseCase`
- [x] `DefaultUseCaseFactory` implementiert:
  - [x] `offlineCacheRepository` als lazy property
  - [x] `makeSettingsRepository()` gibt settingsRepository zurück
  - [x] `makeOfflineCacheSyncUseCase()` erstellt UseCase mit 3 Dependencies
- [x] `MockUseCaseFactory` implementiert:
  - [x] `MockSettingsRepository` mit allen Methoden
  - [x] `MockOfflineCacheSyncUseCase` mit Publishers

**Checklist**:
- [x] Protocol erweitert (2 neue Methoden)
- [x] DefaultUseCaseFactory: beide Methoden implementiert
- [x] MockUseCaseFactory: Mock-Klassen erstellt
- [x] ViewModel nutzt Factory korrekt
- [x] Kompiliert ohne Fehler
- [ ] Test: ViewModel wird erstellt ohne Crash

---

### 4.5 MockUseCaseFactory erweitern (optional)
**Datei**: `readeck/UI/Factory/MockUseCaseFactory.swift`

- [x] Mock-Implementierungen für Tests hinzugefügt

**Checklist**:
- [x] MockSettingsRepository mit allen Protokoll-Methoden
- [x] MockOfflineCacheSyncUseCase mit Publishers
- [x] Kompiliert ohne Fehler

---

## Phase 5: App Integration (Tag 3-4)

### 5.1 AppViewModel erweitern
**Datei**: `readeck/UI/AppViewModel.swift`

- [ ] `onAppStart()` Methode um Sync erweitern:
  - [ ] Nach checkServerReachability()
  - [ ] `syncOfflineArticlesIfNeeded()` aufrufen (ohne await!)
- [ ] `syncOfflineArticlesIfNeeded()` implementieren (private):
  - [ ] SettingsRepository instanziieren
  - [ ] Task.detached(priority: .background) starten
  - [ ] Settings laden
  - [ ] If shouldSyncOnAppStart:
    - [ ] Logger.sync.info("Auto-sync triggered")
    - [ ] syncUseCase holen via Factory
    - [ ] await syncOfflineArticles()
- [ ] Testen: Auto-Sync bei App-Start (4h-Check)

**Checklist**:
- [ ] onAppStart() erweitert
- [ ] syncOfflineArticlesIfNeeded() implementiert
- [ ] Task.detached mit .background
- [ ] Kein await vor syncOfflineArticlesIfNeeded()
- [ ] Logger.sync integriert
- [ ] Test: App startet, Sync läuft im Hintergrund

---

### 5.2 BookmarksViewModel erweitern
**Datei**: `readeck/UI/Bookmarks/BookmarksViewModel.swift`

- [ ] `loadCachedBookmarks()` implementieren (private):
  - [ ] bookmarksRepository.getCachedBookmarks() aufrufen
  - [ ] If nicht leer:
    - [ ] BookmarksPage erstellen mit gecachten Bookmarks
    - [ ] bookmarks Property setzen
    - [ ] hasMoreData = false
    - [ ] errorMessage beibehalten (für Banner)
    - [ ] Logger.viewModel.info
- [ ] `loadBookmarks()` erweitern:
  - [ ] Im Network-Error catch block:
    - [ ] Nach isNetworkError = true
    - [ ] await loadCachedBookmarks() aufrufen
- [ ] Testen: Bei Network-Error werden gecachte Bookmarks geladen

**Checklist**:
- [ ] loadCachedBookmarks() implementiert
- [ ] loadBookmarks() erweitert
- [ ] Logger.viewModel integriert
- [ ] Test: Offline-Modus zeigt gecachte Artikel

---

### 5.3 BookmarksView erweitern
**Datei**: `readeck/UI/Bookmarks/BookmarksView.swift`

- [ ] `offlineBanner` View hinzufügen (private):
  - [ ] HStack mit wifi.slash Icon
  - [ ] Text "Offline-Modus – Zeige gespeicherte Artikel"
  - [ ] Styling: caption, secondary, padding, background
- [ ] `body` anpassen:
  - [ ] ZStack durch VStack(spacing: 0) ersetzen
  - [ ] If isNetworkError && bookmarks nicht leer:
    - [ ] offlineBanner anzeigen
  - [ ] Content darunter
  - [ ] FAB als Overlay über VStack
- [ ] `shouldShowCenteredState` anpassen:
  - [ ] Kommentar: Nur bei leer UND error
  - [ ] return isEmpty && hasError
- [ ] Testen: Offline-Banner erscheint bei Network-Error mit Daten

**Checklist**:
- [ ] offlineBanner View erstellt
- [ ] body mit VStack umgebaut
- [ ] shouldShowCenteredState angepasst
- [ ] Test: Banner wird angezeigt im Offline-Modus

---

### 5.4 BookmarkDetailViewModel erweitern
**Datei**: `readeck/UI/BookmarkDetail/BookmarkDetailViewModel.swift`

- [ ] `loadArticle()` erweitern:
  - [ ] Vor Server-Request:
    - [ ] If let cachedHTML = bookmarksRepository.getCachedArticle(id:)
    - [ ] articleHTML = cachedHTML
    - [ ] isLoading = false
    - [ ] Logger.viewModel.info("Loaded from cache")
    - [ ] return
  - [ ] Nach Server-Request (im Task.detached):
    - [ ] Artikel optional cachen wenn saveImages enabled
- [ ] Testen: Gecachte Artikel laden sofort

**Checklist**:
- [ ] Cache-Check vor Server-Request
- [ ] Logger.viewModel integriert
- [ ] Optional: Background-Caching nach Load
- [ ] Test: Gecachte Artikel laden instant

---

## Phase 6: Testing & Polish (Tag 4-5)

### 6.1 Unit Tests
- [ ] OfflineSettings Tests:
  - [ ] shouldSyncOnAppStart bei erstem Mal
  - [ ] shouldSyncOnAppStart nach 3h (false)
  - [ ] shouldSyncOnAppStart nach 5h (true)
  - [ ] shouldSyncOnAppStart bei disabled (false)
- [ ] SettingsRepository Tests:
  - [ ] Save & Load roundtrip
  - [ ] Default values bei leerem UserDefaults
- [ ] BookmarksRepository Cache Tests:
  - [ ] cacheBookmarkWithMetadata()
  - [ ] getCachedArticle()
  - [ ] hasCachedArticle()
  - [ ] cleanupOldestCachedArticles()
  - [ ] extractImageURLsFromHTML()

**Checklist**:
- [ ] OfflineSettings Tests geschrieben
- [ ] SettingsRepository Tests geschrieben
- [ ] BookmarksRepository Tests geschrieben
- [ ] Alle Tests grün

---

### 6.2 Integration Tests
- [ ] App-Start Sync:
  - [ ] Erste Start: Sync läuft
  - [ ] Zweiter Start < 4h: Kein Sync
  - [ ] Nach 4h: Sync läuft
- [ ] Manual Sync:
  - [ ] Button triggert Sync
  - [ ] Progress wird angezeigt
  - [ ] Success-Message erscheint
- [ ] Offline-Modus:
  - [ ] Flugmodus aktivieren
  - [ ] Gecachte Bookmarks werden angezeigt
  - [ ] Offline-Banner erscheint
  - [ ] Artikel lassen sich öffnen
- [ ] Cache Management:
  - [ ] 20 Artikel cachen
  - [ ] Stats zeigen 20 Artikel + Größe
  - [ ] Cleanup funktioniert bei Limit-Überschreitung

**Checklist**:
- [ ] App-Start Sync getestet
- [ ] Manual Sync getestet
- [ ] Offline-Modus getestet
- [ ] Cache Management getestet

---

### 6.3 Edge Cases
- [ ] Netzwerk-Verlust während Sync:
  - [ ] Partial success wird geloggt
  - [ ] Status-Message korrekt
- [ ] Speicher voll:
  - [ ] Fehlerbehandlung
  - [ ] User-Benachrichtigung
- [ ] 100 Artikel Performance:
  - [ ] Sync dauert < 2 Minuten
  - [ ] App bleibt responsiv
- [ ] CoreData Migration:
  - [ ] Alte App-Version → Neue Version
  - [ ] Keine Datenverluste
- [ ] Kingfisher Cache:
  - [ ] Bilder werden geladen
  - [ ] Cache-Limit wird respektiert

**Checklist**:
- [ ] Netzwerk-Verlust getestet
- [ ] Speicher voll getestet
- [ ] 100 Artikel Performance OK
- [ ] Migration getestet
- [ ] Kingfisher funktioniert

---

### 6.4 Bug-Fixing & Polish
- [ ] Alle gefundenen Bugs gefixt
- [ ] Code-Review durchgeführt
- [ ] Logging überprüft (nicht zu viel, nicht zu wenig)
- [ ] UI-Polish (Spacing, Colors, etc.)
- [ ] Performance-Optimierungen falls nötig

**Checklist**:
- [ ] Alle Bugs gefixt
- [ ] Code reviewed
- [ ] Logging optimiert
- [ ] UI poliert
- [ ] Performance OK

---

## Final Checklist

### Funktionalität
- [ ] Offline-Reading Toggle funktioniert
- [ ] Slider für Artikel-Anzahl funktioniert
- [ ] Bilder-Toggle funktioniert
- [ ] Auto-Sync bei App-Start (4h-Check)
- [ ] Manual-Sync Button funktioniert
- [ ] Offline-Modus zeigt gecachte Artikel
- [ ] Offline-Banner wird angezeigt
- [ ] Cache-Stats werden angezeigt
- [ ] Last-Sync-Date wird angezeigt
- [ ] Background-Sync mit niedriger Priority
- [ ] Kingfisher cached Bilder
- [ ] FIFO Cleanup funktioniert

### Code-Qualität
- [ ] Alle neuen Files erstellt
- [ ] Alle Protokolle definiert
- [ ] Alle Implementierungen vollständig
- [ ] Logging überall integriert
- [ ] Error-Handling implementiert
- [ ] Keine Compiler-Warnings
- [ ] Keine Force-Unwraps
- [ ] Code dokumentiert (Kommentare wo nötig)

### Tests
- [ ] Unit Tests geschrieben
- [ ] Integration Tests durchgeführt
- [ ] Edge Cases getestet
- [ ] Performance getestet
- [ ] Alle Tests grün

### Dokumentation
- [ ] Implementierungsplan vollständig
- [ ] Alle Checkboxen abgehakt
- [ ] Gefundene Issues dokumentiert
- [ ] Nächste Schritte (Stufe 2) überlegt

---

## Commit & PR

- [ ] Alle Änderungen commited
- [ ] Commit-Messages aussagekräftig
- [ ] Branch gepusht
- [ ] PR erstellt gegen `develop`
- [ ] PR-Beschreibung vollständig:
  - [ ] Was wurde implementiert
  - [ ] Wie testen
  - [ ] Screenshots (Settings-UI)
  - [ ] Known Issues (falls vorhanden)

---

## Notes & Issues

### Gefundene Probleme
_(Hier während der Implementation eintragen)_

### Offene Fragen
_(Hier während der Implementation eintragen)_

### Verbesserungsideen für Stufe 2
_(Hier sammeln)_

---

*Erstellt: 2025-11-01*
*Letztes Update: 2025-11-01*
