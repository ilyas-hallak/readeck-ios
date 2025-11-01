# Offline Stufe 1 - Implementierungs-Tracking

**Branch**: `offline-sync`
**Start**: 2025-11-01
**Geschätzte Dauer**: 5-8 Tage

---

## Phase 1: Foundation & Models (Tag 1)

### 1.1 Logging-Kategorie erweitern
**Datei**: `readeck/Utils/Logger.swift`

- [ ] `LogCategory.sync` zur enum hinzufügen
- [ ] `Logger.sync` zur Extension hinzufügen
- [ ] Testen: Logging funktioniert

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

- [ ] Struct OfflineSettings erstellen
- [ ] Properties hinzufügen:
  - [ ] `enabled: Bool = true`
  - [ ] `maxUnreadArticles: Double = 20`
  - [ ] `saveImages: Bool = false`
  - [ ] `lastSyncDate: Date?`
- [ ] Computed Property `maxUnreadArticlesInt` implementieren
- [ ] Computed Property `shouldSyncOnAppStart` implementieren (4-Stunden-Check)
- [ ] Codable Conformance
- [ ] Testen: shouldSyncOnAppStart Logic

**Checklist**:
- [ ] File erstellt
- [ ] Alle Properties vorhanden
- [ ] 4-Stunden-Check funktioniert
- [ ] Kompiliert ohne Fehler

---

### 1.3 CoreData Entity: CachedArticle
**Datei**: `readeck.xcdatamodeld`

- [ ] Neue Model-Version erstellen
- [ ] CachedArticle Entity hinzufügen
- [ ] Attributes definieren:
  - [ ] `id` (String, indexed)
  - [ ] `bookmarkId` (String, indexed, unique constraint)
  - [ ] `bookmarkJSON` (String)
  - [ ] `htmlContent` (String)
  - [ ] `cachedDate` (Date, indexed)
  - [ ] `lastAccessDate` (Date)
  - [ ] `size` (Integer 64)
  - [ ] `imageURLs` (String, optional)
- [ ] Current Model Version setzen
- [ ] Lightweight Migration in CoreDataManager aktivieren
- [ ] Testen: App startet ohne Crash, keine Migration-Fehler

**Checklist**:
- [ ] Entity erstellt
- [ ] Alle Attributes vorhanden
- [ ] Indexes gesetzt
- [ ] Migration funktioniert
- [ ] App startet erfolgreich

---

## Phase 2: Data Layer (Tag 1-2)

### 2.1 Settings Repository Protocol
**Neue Datei**: `readeck/Domain/Protocols/PSettingsRepository.swift`

- [ ] Protocol `PSettingsRepository` erstellen
- [ ] Methode `loadOfflineSettings()` definieren
- [ ] Methode `saveOfflineSettings(_ settings: OfflineSettings)` definieren

**Checklist**:
- [ ] File erstellt
- [ ] Protocol definiert
- [ ] Methoden deklariert
- [ ] Kompiliert ohne Fehler

---

### 2.2 Settings Repository Implementation
**Neue Datei**: `readeck/Data/Repository/SettingsRepository.swift`

- [ ] Class `SettingsRepository` erstellen
- [ ] `PSettingsRepository` implementieren
- [ ] `loadOfflineSettings()` implementieren:
  - [ ] UserDefaults laden
  - [ ] JSON dekodieren
  - [ ] Default-Settings zurückgeben bei Fehler
  - [ ] Logger.data für Erfolgsmeldung
- [ ] `saveOfflineSettings()` implementieren:
  - [ ] JSON enkodieren
  - [ ] UserDefaults speichern
  - [ ] Logger.data für Erfolgsmeldung
- [ ] Testen: Save & Load funktioniert

**Checklist**:
- [ ] File erstellt
- [ ] loadOfflineSettings() implementiert
- [ ] saveOfflineSettings() implementiert
- [ ] Logging integriert
- [ ] Manueller Test erfolgreich

---

### 2.3 BookmarksRepository Protocol erweitern
**Datei**: `readeck/Domain/Protocols/PBookmarksRepository.swift`

- [ ] Neue Methoden zum Protocol hinzufügen:
  - [ ] `cacheBookmarkWithMetadata(bookmark:html:saveImages:) async throws`
  - [ ] `getCachedArticle(id:) -> String?`
  - [ ] `hasCachedArticle(id:) -> Bool`
  - [ ] `getCachedBookmarks() async throws -> [Bookmark]`
  - [ ] `getCachedArticlesCount() -> Int`
  - [ ] `getCacheSize() -> String`
  - [ ] `clearCache() async throws`
  - [ ] `cleanupOldestCachedArticles(keepCount:) async throws`

**Checklist**:
- [ ] Alle Methoden deklariert
- [ ] Async/throws korrekt gesetzt
- [ ] Kompiliert ohne Fehler

---

### 2.4 BookmarksRepository Implementation
**Datei**: `readeck/Data/Repository/BookmarksRepository.swift`

- [ ] `import Kingfisher` hinzufügen
- [ ] `cacheBookmarkWithMetadata()` implementieren:
  - [ ] Prüfen ob bereits gecacht
  - [ ] Bookmark als JSON enkodieren
  - [ ] CoreData CachedArticle erstellen
  - [ ] Speichern in CoreData
  - [ ] Logger.sync.info
  - [ ] Bei saveImages: extractImageURLsFromHTML() aufrufen
  - [ ] Bei saveImages: prefetchImagesWithKingfisher() aufrufen
- [ ] `extractImageURLsFromHTML()` implementieren:
  - [ ] Regex für `<img src="...">` Tags
  - [ ] URLs extrahieren
  - [ ] Nur absolute URLs (http/https)
  - [ ] Logger.sync.debug
- [ ] `prefetchImagesWithKingfisher()` implementieren:
  - [ ] URLs zu URL-Array konvertieren
  - [ ] ImagePrefetcher erstellen
  - [ ] Optional: downloadPriority(.low) setzen
  - [ ] prefetcher.start()
  - [ ] Logger.sync.info
- [ ] `getCachedArticle()` implementieren:
  - [ ] NSFetchRequest mit predicate
  - [ ] lastAccessDate updaten
  - [ ] htmlContent zurückgeben
- [ ] `hasCachedArticle()` implementieren
- [ ] `getCachedBookmarks()` implementieren:
  - [ ] Fetch alle CachedArticle
  - [ ] Sort by cachedDate descending
  - [ ] JSON zu Bookmark dekodieren
  - [ ] Array zurückgeben
- [ ] `getCachedArticlesCount()` implementieren
- [ ] `getCacheSize()` implementieren:
  - [ ] Alle sizes summieren
  - [ ] ByteCountFormatter nutzen
- [ ] `clearCache()` implementieren:
  - [ ] NSBatchDeleteRequest
  - [ ] Logger.sync.info
- [ ] `cleanupOldestCachedArticles()` implementieren:
  - [ ] Sort by cachedDate ascending
  - [ ] Älteste löschen wenn > keepCount
  - [ ] Logger.sync.info
- [ ] Testen: Alle Methoden funktionieren

**Checklist**:
- [ ] Kingfisher import
- [ ] cacheBookmarkWithMetadata() fertig
- [ ] extractImageURLsFromHTML() fertig
- [ ] prefetchImagesWithKingfisher() fertig
- [ ] getCachedArticle() fertig
- [ ] hasCachedArticle() fertig
- [ ] getCachedBookmarks() fertig
- [ ] getCachedArticlesCount() fertig
- [ ] getCacheSize() fertig
- [ ] clearCache() fertig
- [ ] cleanupOldestCachedArticles() fertig
- [ ] Logging überall integriert
- [ ] Manuelle Tests erfolgreich

---

## Phase 3: Use Case & Business Logic (Tag 2)

### 3.1 OfflineCacheSyncUseCase Protocol
**Neue Datei**: `readeck/Domain/UseCase/OfflineCacheSyncUseCase.swift`

- [ ] Protocol `POfflineCacheSyncUseCase` erstellen
- [ ] Published Properties definieren:
  - [ ] `var isSyncing: AnyPublisher<Bool, Never>`
  - [ ] `var syncProgress: AnyPublisher<String?, Never>`
- [ ] Methoden deklarieren:
  - [ ] `func syncOfflineArticles(settings:) async`
  - [ ] `func getCachedArticlesCount() -> Int`
  - [ ] `func getCacheSize() -> String`

**Checklist**:
- [ ] File erstellt
- [ ] Protocol definiert
- [ ] Methoden deklariert
- [ ] Kompiliert ohne Fehler

---

### 3.2 OfflineCacheSyncUseCase Implementation
**Datei**: `readeck/Domain/UseCase/OfflineCacheSyncUseCase.swift` (im selben File)

- [ ] Class `OfflineCacheSyncUseCase` erstellen
- [ ] Dependencies:
  - [ ] `bookmarksRepository: PBookmarksRepository`
  - [ ] `settingsRepository: PSettingsRepository`
- [ ] @Published Properties:
  - [ ] `_isSyncing = false`
  - [ ] `_syncProgress: String?`
- [ ] Publishers als computed properties
- [ ] `syncOfflineArticles()` implementieren:
  - [ ] Guard enabled check
  - [ ] Logger.sync.info("Starting sync")
  - [ ] Set isSyncing = true
  - [ ] Fetch bookmarks (state: .unread, limit: settings.maxUnreadArticlesInt)
  - [ ] Logger.sync.info("Fetched X bookmarks")
  - [ ] Loop durch Bookmarks:
    - [ ] Skip wenn bereits gecacht (Logger.sync.debug)
    - [ ] syncProgress updaten: "Artikel X/Y..."
    - [ ] fetchBookmarkArticle() aufrufen
    - [ ] cacheBookmarkWithMetadata() aufrufen
    - [ ] successCount++
    - [ ] Bei saveImages: syncProgress "...+ Bilder"
    - [ ] Catch: errorCount++, Logger.sync.error
  - [ ] cleanupOldestCachedArticles() aufrufen
  - [ ] lastSyncDate updaten
  - [ ] Logger.sync.info("✅ Synced X, skipped Y, failed Z")
  - [ ] Set isSyncing = false
  - [ ] syncProgress = Status-Message
  - [ ] Sleep 3s, dann syncProgress = nil
- [ ] `getCachedArticlesCount()` implementieren
- [ ] `getCacheSize()` implementieren
- [ ] Error-Handling:
  - [ ] Catch block für Haupt-Try
  - [ ] Logger.sync.error
  - [ ] syncProgress = Error-Message
- [ ] Testen: Sync-Flow komplett durchlaufen

**Checklist**:
- [ ] Class erstellt
- [ ] Dependencies injiziert
- [ ] syncOfflineArticles() komplett
- [ ] Success/Skip/Error Tracking
- [ ] Logging an allen wichtigen Stellen
- [ ] Progress-Updates
- [ ] Error-Handling
- [ ] getCachedArticlesCount() fertig
- [ ] getCacheSize() fertig
- [ ] Test: Sync läuft durch

---

## Phase 4: Settings UI (Tag 3)

### 4.1 OfflineSettingsViewModel
**Neue Datei**: `readeck/UI/Settings/OfflineSettingsViewModel.swift`

- [ ] Class mit @MainActor und @Observable
- [ ] @Published Properties:
  - [ ] `offlineSettings: OfflineSettings`
  - [ ] `isSyncing = false`
  - [ ] `syncProgress: String?`
  - [ ] `cachedArticlesCount = 0`
  - [ ] `cacheSize = "0 KB"`
- [ ] Dependencies:
  - [ ] `settingsRepository: PSettingsRepository`
  - [ ] `offlineCacheSyncUseCase: POfflineCacheSyncUseCase`
- [ ] Init mit Dependencies
- [ ] `setupBindings()` implementieren:
  - [ ] isSyncing Publisher binden
  - [ ] syncProgress Publisher binden
  - [ ] Auto-save bei offlineSettings change (debounce 0.5s)
- [ ] `loadSettings()` implementieren
- [ ] `syncNow()` implementieren:
  - [ ] Kommentar: Manual sync mit höherer Priority
  - [ ] await offlineCacheSyncUseCase.syncOfflineArticles()
  - [ ] updateCacheStats()
- [ ] `updateCacheStats()` implementieren
- [ ] Testen: ViewModel funktioniert

**Checklist**:
- [ ] File erstellt
- [ ] Properties definiert
- [ ] Dependencies injiziert
- [ ] setupBindings() fertig
- [ ] loadSettings() fertig
- [ ] syncNow() fertig
- [ ] updateCacheStats() fertig
- [ ] Test: ViewModel lädt Settings

---

### 4.2 OfflineSettingsView
**Neue Datei**: `readeck/UI/Settings/OfflineSettingsView.swift`

- [ ] Struct `OfflineSettingsView: View`
- [ ] @StateObject viewModel
- [ ] Body implementieren:
  - [ ] Form mit Section
  - [ ] Toggle: "Offline-Reading" gebunden an enabled
  - [ ] If enabled:
    - [ ] VStack: Erklärungstext (caption, secondary)
    - [ ] VStack: Slider "Max. Artikel offline" (0-100, step 10)
    - [ ] HStack: Anzeige aktueller Wert
    - [ ] Toggle: "Bilder speichern"
    - [ ] Button: "Jetzt synchronisieren" mit ProgressView
    - [ ] If syncProgress: Text anzeigen (caption)
    - [ ] If lastSyncDate: Text "Zuletzt synchronisiert: relative"
    - [ ] If cachedArticlesCount > 0: HStack mit Stats
  - [ ] Section header: "Offline-Reading"
- [ ] navigationTitle("Offline-Reading")
- [ ] onAppear: updateCacheStats()
- [ ] Testen: UI wird korrekt angezeigt

**Checklist**:
- [ ] File erstellt
- [ ] Form Structure erstellt
- [ ] Toggle für enabled
- [ ] Slider für maxUnreadArticles
- [ ] Toggle für saveImages
- [ ] Sync-Button mit Progress
- [ ] Stats-Anzeige
- [ ] UI-Preview funktioniert
- [ ] Test: Settings werden angezeigt

---

### 4.3 SettingsContainerView Integration
**Datei**: `readeck/UI/Settings/SettingsContainerView.swift`

- [ ] NavigationLink zu OfflineSettingsView hinzufügen
- [ ] Label mit "Offline-Reading" und Icon "arrow.down.circle"
- [ ] In bestehende Section (z.B. "Allgemein") einfügen
- [ ] Testen: Navigation funktioniert

**Checklist**:
- [ ] NavigationLink hinzugefügt
- [ ] Icon korrekt
- [ ] Navigation funktioniert

---

### 4.4 Factory erweitern
**Datei**: `readeck/UI/Factory/DefaultUseCaseFactory.swift`

- [ ] `makeOfflineSettingsViewModel()` implementieren:
  - [ ] settingsRepository injecten
  - [ ] offlineCacheSyncUseCase injecten
  - [ ] OfflineSettingsViewModel instanziieren
- [ ] `makeSettingsRepository()` implementieren (private):
  - [ ] SettingsRepository instanziieren
- [ ] `makeOfflineCacheSyncUseCase()` implementieren (private):
  - [ ] bookmarksRepository injecten
  - [ ] settingsRepository injecten
  - [ ] OfflineCacheSyncUseCase instanziieren
- [ ] Testen: Dependencies werden korrekt aufgelöst

**Checklist**:
- [ ] makeOfflineSettingsViewModel() fertig
- [ ] makeSettingsRepository() fertig
- [ ] makeOfflineCacheSyncUseCase() fertig
- [ ] Test: ViewModel wird erstellt ohne Crash

---

### 4.5 MockUseCaseFactory erweitern (optional)
**Datei**: `readeck/UI/Factory/MockUseCaseFactory.swift`

- [ ] Mock-Implementierungen für Tests hinzufügen (falls nötig)

**Checklist**:
- [ ] Mocks erstellt (falls nötig)

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
