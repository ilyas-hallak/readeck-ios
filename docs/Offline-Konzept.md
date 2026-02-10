# Offline-Konzept für Readeck iOS App

## Übersicht

Dieses Dokument beschreibt ein mehrstufiges Konzept zur Offline-Funktionalität der Readeck iOS App. Das Konzept ist modular aufgebaut und ermöglicht eine schrittweise Implementierung – von einer einfachen Caching-Strategie für ungelesene Artikel bis hin zu einer vollständig offline-fähigen App.

---

## Stufe 1: Smart Cache für Unread Items (Basis-Offline)

### Beschreibung
Die App lädt automatisch eine konfigurierbare Anzahl ungelesener Artikel herunter und hält diese offline verfügbar. Dies ist die Grundlage für eine bessere Offline-Erfahrung ohne großen Implementierungsaufwand.

### Features
- **Automatisches Caching**: Beim App-Start und bei Pull-to-Refresh werden die neuesten ungelesenen Artikel im Hintergrund heruntergeladen
- **Konfigurierbare Anzahl**: User kann in den Einstellungen festlegen, wie viele Artikel gecacht werden sollen (z.B. 10, 25, 50, 100)
- **Nur Artikel-Content**: Es wird nur der HTML-Content des Artikels (`/api/bookmarks/{id}/article`) gecached
- **Automatische Verwaltung**: Ältere gecachte Artikel werden automatisch entfernt, wenn neue hinzukommen (FIFO-Prinzip)
- **Offline-Indikator**: In der Bookmark-Liste wird angezeigt, welche Artikel offline verfügbar sind

### Technische Umsetzung
```swift
// Neue Settings
struct OfflineSettings {
    var enabled: Bool = true
    var maxUnreadArticles: Int = 25 // 10, 25, 50, 100
    var onlyWiFi: Bool = true
}

// Neue Repository-Methode
protocol PBookmarksRepository {
    func cacheBookmarkArticle(id: String, html: String) async throws
    func getCachedArticle(id: String) -> String?
    func hasCachedArticle(id: String) -> Bool
}
```

### Datenspeicherung
- **CoreData** für Artikel-HTML und Metadaten (Titel, URL, Datum, Reihenfolge)
- **FileManager** optional für große HTML-Dateien (falls CoreData zu groß wird)

### User Experience
- Bookmark-Liste zeigt Download-Icon für offline verfügbare Artikel
- Beim Öffnen eines gecachten Artikels: Sofortiges Laden ohne Netzwerk-Anfrage
- In Settings: "Offline-Modus" Sektion mit Slider für Anzahl der Artikel
- Cache-Größe wird angezeigt (z.B. "23 Artikel, 12.5 MB")

---

## Stufe 2: Offline-First mit Sync (Erweitert)

### Beschreibung
Die App funktioniert vollständig offline. Alle Aktionen werden lokal gespeichert und bei Netzwerkverbindung mit dem Server synchronisiert.

### Features
- **Vollständige Offline-Funktionalität**: Alle Lese-Operationen funktionieren offline
- **Lokale Schreib-Operationen**:
  - Bookmarks erstellen, bearbeiten, löschen
  - Labels hinzufügen/entfernen
  - Artikel archivieren/favorisieren
  - Lesefortschritt speichern
  - Annotationen/Highlights erstellen
- **Intelligente Synchronisierung**:
  - Automatische Sync bei Netzwerkverbindung
  - Konfliktauflösung (Server gewinnt vs. Client gewinnt)
  - Retry-Mechanismus bei fehlgeschlagenen Syncs
- **Sync-Status**: User sieht jederzeit, ob und was synchronisiert wird
- **Offline-Indikator**: Klarer Status in der UI (Online/Offline/Syncing)

### Technische Umsetzung

#### Sync-Manager
```swift
class OfflineSyncManager {
    // Bereits vorhanden für Bookmark-Erstellung
    // Erweitern für alle Operations

    enum SyncOperation {
        case createBookmark(CreateBookmarkRequest)
        case updateBookmark(id: String, BookmarkUpdateRequest)
        case deleteBookmark(id: String)
        case addLabels(bookmarkId: String, labels: [String])
        case removeLabels(bookmarkId: String, labels: [String])
        case updateReadProgress(bookmarkId: String, progress: Int)
        case createAnnotation(AnnotationRequest)
        case deleteAnnotation(bookmarkId: String, annotationId: String)
    }

    func queueOperation(_ operation: SyncOperation) async
    func syncAllPendingOperations() async throws
    func getPendingOperationsCount() -> Int
}
```

#### Lokale Datenbank-Struktur
```swift
// CoreData Entities
entity OfflineBookmark {
    id: String
    title: String
    url: String
    content: String? // HTML
    metadata: Data // JSON mit allen Bookmark-Daten
    labels: [String]
    isArchived: Bool
    isMarked: Bool
    readProgress: Int
    annotations: [OfflineAnnotation]
    lastModified: Date
    syncStatus: String // "synced", "pending", "conflict"
}

entity PendingSyncOperation {
    id: UUID
    type: String // operation type
    payload: Data // JSON der Operation
    createdAt: Date
    retryCount: Int
    lastError: String?
}
```

### Sync-Strategien

#### Option A: Last-Write-Wins (Einfach)
- Server-Version überschreibt bei Konflikt immer lokale Version
- Einfach zu implementieren
- Potentieller Datenverlust bei Offline-Änderungen

#### Option B: Timestamp-basiert (Empfohlen)
- Neueste Änderung (basierend auf Timestamp) gewinnt
- Server sendet `updated` Timestamp mit jeder Response
- Client vergleicht mit lokalem Timestamp

#### Option C: Operational Transformation (Komplex)
- Granulare Merge-Strategien für verschiedene Felder
- Beispiel: Lokale Labels + Server Labels = Union
- Aufwändig, aber maximale Datenerhaltung

### User Experience
- **Offline-Banner**: "Du bist offline. Änderungen werden synchronisiert, sobald du online bist."
- **Sync-Status Indicator**:
  - Grün: Alles synchronisiert
  - Gelb: Synchronisierung läuft
  - Rot: Sync-Fehler
  - Grau: Offline
- **Pending Changes Badge**: Zeigt Anzahl nicht synchronisierter Änderungen
- **Manual Sync Button**: Manuelles Anstoßen der Synchronisierung
- **Sync-Konflikt-Dialog**: Bei Konflikten User entscheiden lassen (Lokal behalten / Server übernehmen / Beide behalten)

---

## Stufe 3: Vollständig Offline-Fähig (Maximum)

### Beschreibung
Die App kann komplett ohne Server-Verbindung genutzt werden, inklusive lokaler Volltext-Suche und erweiterter Offline-Features.

### Zusätzliche Features
- **Lokale Volltext-Suche**:
  - SQLite FTS5 (Full-Text Search) für schnelle Suche
  - Suche in Titeln, URLs, Content, Labels
  - Highlighting von Suchbegriffen
- **Intelligente Offline-Strategie**:
  - Predictive Caching basierend auf Leseverhalten
  - Automatisches Herunterladen von "Ähnlichen Artikeln"
  - Background Refresh für häufig gelesene Labels/Tags
- **Erweiterte Export-Funktionen**:
  - Kompletten Offline-Cache als ZIP exportieren
  - Import von Offline-Daten auf anderem Gerät
  - Backup & Restore
- **Reader Mode Optimierungen**:
  - Lokale Schriftarten für Offline-Nutzung
  - CSS/JS lokal gespeichert
  - Keine externen Dependencies
- **Offline-Statistiken**:
  - Lesezeit offline vs. online
  - Meistgelesene offline Artikel
  - Speicherplatz-Statistiken

### Erweiterte Technische Umsetzung

#### FTS5 für Suche
```swift
// SQLite Schema
CREATE VIRTUAL TABLE bookmarks_fts USING fts5(
    title,
    url,
    content,
    labels,
    content='offline_bookmarks',
    content_rowid='id'
);

// Suche
func searchOfflineBookmarks(query: String) -> [Bookmark] {
    let sql = """
        SELECT * FROM offline_bookmarks
        WHERE id IN (
            SELECT rowid FROM bookmarks_fts
            WHERE bookmarks_fts MATCH ?
        )
        ORDER BY rank
    """
    // Execute and return results
}
```

#### Predictive Caching
```swift
class PredictiveCacheManager {
    // Analysiere Leseverhalten
    func analyzeReadingPatterns() -> ReadingProfile

    // Lade ähnliche Artikel basierend auf:
    // - Gleiche Labels/Tags
    // - Gleiche Autoren
    // - Gleiche Domains
    func prefetchRelatedArticles(for bookmark: Bookmark) async

    // Machine Learning (optional)
    // CoreML Model für Content-Empfehlungen
    func trainRecommendationModel()
}
```

#### Background Sync
```swift
// BackgroundTasks Framework
class BackgroundSyncScheduler {
    func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: "de.readeck.sync")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min

        try? BGTaskScheduler.shared.submit(request)
    }

    func handleBackgroundSync(task: BGTask) async {
        // Sync neue Artikel
        // Update gecachte Artikel
        // Cleanup alte Artikel
    }
}
```

### Datenspeicherung
- **SQLite + FTS5**: Für Volltextsuche
- **CoreData**: Für strukturierte Daten und Relationships
- **FileManager**: Für HTML-Content, Bilder, Assets
- **NSUbiquitousKeyValueStore**: Optional für iCloud-Sync der Einstellungen

### User Experience
- **Offline-First Ansatz**: App fühlt sich immer schnell an, auch bei schlechter Verbindung
- **Smart Downloads**:
  - "20 neue Artikel verfügbar. Jetzt herunterladen?"
  - "Für dich empfohlen: 5 Artikel zum Offline-Lesen"
- **Storage Dashboard**:
  - Visualisierung des genutzten Speichers
  - Top 10 größte Artikel
  - "Speicher optimieren" Funktion (Bilder komprimieren, alte Artikel löschen)
- **Offline-Modus Toggle**: Bewusster "Nur Offline"-Modus aktivierbar
- **Sync-Schedule**: "Täglich um 6:00 Uhr synchronisieren"

---

## Implementierungs-Roadmap

### Phase 1: Basis (Stufe 1) - ca. 2-3 Wochen

- [ ] Settings für Offline-Anzahl
- [ ] CoreData Schema für cached Articles
- [ ] Download-Logic in BookmarksRepository
- [ ] UI-Indikatoren für gecachte Artikel
- [ ] Cleanup-Logic (FIFO)

### Phase 2: Offline-First mit Sync (Stufe 2) - ca. 4-6 Wochen

- [ ] Erweiterte CoreData Entities
- [ ] OfflineSyncManager erweitern
- [ ] Konfliktauflösung implementieren
- [ ] Sync-Status UI
- [ ] Comprehensive Testing (Edge Cases)

### Phase 3: Advanced Features (Stufe 3) - ca. 4-6 Wochen

- [ ] SQLite FTS5 Integration
- [ ] Predictive Caching
- [ ] Background Tasks
- [ ] Export/Import
- [ ] Analytics & Optimizations

---

## Technische Überlegungen

### Performance
- **Lazy Loading**: Artikel-Content nur laden, wenn benötigt
- **Pagination**: Auch offline große Listen paginieren
- **Image Optimization**: Bilder komprimieren vor dem Speichern (WebP, HEIC)
- **Incremental Sync**: Nur Änderungen synchronisieren, nicht alles neu laden

### Speicherplatz
- **Quotas**: Maximale Größe für Offline-Cache (z.B. 500MB, 1GB, 2GB)
- **Cleanup-Strategien**:
  - Älteste zuerst (FIFO)
  - Größte zuerst
  - Am wenigsten gelesen zuerst
- **Kompression**: HTML und JSON komprimieren (gzip)

### Sicherheit
- **Verschlüsselung**: Offline-Daten mit iOS Data Protection verschlüsseln
- **Sensitive Data**: Passwörter niemals lokal speichern (nur Token mit Keychain)
- **Cleanup bei Logout**: Alle Offline-Daten löschen

### Testing
- **Unit Tests**: Für Sync-Logic, Conflict Resolution
- **Integration Tests**: Offline→Online Szenarien
- **UI Tests**: Offline-Modi, Sync-Status
- **Edge Cases**:
  - App-Kill während Sync
  - Netzwerk-Loss während Download
  - Speicher voll
  - Server-Konflikte

---

## Bestehende Features die von Offline profitieren

### Bereits implementiert
- ✅ **Offline Bookmark Erstellung**: Bookmarks werden lokal gespeichert und bei Verbindung synchronisiert ([OfflineSyncManager.swift](readeck/Data/Repository/OfflineSyncManager.swift))
- ✅ **Server Reachability Check**: Check ob Server erreichbar ist vor Sync-Operationen
- ✅ **Sync Status UI**: isSyncing und syncStatus werden bereits getrackt

### Erweiterbar
- **Text-to-Speech**: Geht bereits offline, wenn Artikel gecacht ist
- **Annotations/Highlights**: Können offline erstellt und später synchronisiert werden
- **Lesefortschritt**: Kann lokal getrackt und bei Sync übertragen werden
- **Labels**: Offline hinzufügen/entfernen mit Sync
- **Read Progress**: Bereits vorhanden im BookmarkDetail Model, kann offline getrackt werden

---

## Metriken für Erfolg

### User-Metriken
- Durchschnittliche Offline-Nutzungszeit
- % der Nutzer, die Offline-Features aktivieren
- Anzahl der offline gelesenen Artikel pro User
- User-Feedback zur Offline-Erfahrung

### Technische Metriken
- Erfolgsrate der Synchronisierungen
- Durchschnittliche Sync-Dauer
- Anzahl der Sync-Konflikte
- Speicherplatz-Nutzung pro User
- Crash-Rate während Offline-Operationen

### Performance-Metriken
- App-Start-Zeit mit/ohne Offline-Cache
- Ladezeit für gecachte vs. nicht-gecachte Artikel
- Netzwerk-Traffic Reduktion durch Caching
- Battery Impact durch Background-Sync

---

## Nächste Schritte

1. **Entscheidung**: Welche Stufe soll zuerst implementiert werden?
2. **Prototyping**: Quick PoC für CoreData Schema und Cache-Logic
3. **UI/UX Design**: Mockups für Offline-Indikatoren und Settings
4. **Implementation**: Schrittweise nach Roadmap
5. **Testing**: Ausgiebiges Testen von Edge Cases
6. **Beta**: TestFlight mit fokussiertem Offline-Testing
7. **Launch**: Schrittweises Rollout mit Feature-Flags

---

*Dokument erstellt: 2025-11-01*
*Version: 1.0*
