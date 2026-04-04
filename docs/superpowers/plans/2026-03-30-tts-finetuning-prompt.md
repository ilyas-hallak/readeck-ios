Weiter auf Branch `fix/tts-overhaul`. Das TTS Podcast-UX Feature ist fertig implementiert und merged mit hub/main.

## Was gebaut wurde (13 Tasks + Bugfixes)

### Core
- **SpeechQueueItem**: `lastCharacterIndex` + `totalCharacters` für Position-Tracking
- **TTSManager**: Character-level Position-Tracking, `seek(toCharacter:)`, `seekBack/Forward(seconds:)`, `estimatedCharactersPerSecond()`, `estimatedDuration/CurrentTime`, Synthesizer-Reset bei Foreground/Audio-Interruption, Voice-Refresh nach Voice-Download
- **SpeechQueue**: `insertAfterCurrent()`, `move()`, `remove()`, `skipToNext()`, `seekToPosition()`, Position-Save alle 5s, Resume von gespeicherter Position
- **NowPlayingManager** (neu): Lock-Screen + Control Center Controls (Play/Pause/Next/Seek)

### UI
- **MiniPlayerView** (neu): Kompakter Player-Bar mit Progress, Title, Play/Pause, Close-Button
- **PlayerSheetView** (neu): Half-Sheet/Fullscreen mit Cover-Art, Seek-Bar, Transport-Controls, Speed/Volume, Queue-Liste mit Drag&Drop
- **SpeechPlayerView**: Thin wrapper — MiniPlayer + Sheet-Trigger
- **GlobalPlayerContainerView**: Sheet auf stabilem Parent, `isPlayerDismissed` State
- **PhoneTabView**: Player-Sheet, Close/Resume-Flow, auto-reshow bei neuen Queue-Items
- **PlayerQueueResumeButton**: "Show Player" Button im More-Tab wenn Player dismissed

### Features
- "Play Next" Swipe-Action auf Bookmark-Cards (alle Listen + Suche)
- "Play Next" Button in BookmarkDetailView2 + LegacyView
- Per-Language Voice Selection mit Quality-Gruppierung (Premium/Enhanced/Default)
- Voice Preview (Tap to hear sample)
- TTSLanguageSettingsView → VoiceListView Navigation
- PlayerUIState komplett entfernt (auto-show basierend auf Queue-State)

### Bekannte Punkte zum Feintunen
- PlayerSheetView: `List` in `ScrollView` ist ein SwiftUI Anti-Pattern (→ LazyVStack?)
- NowPlayingManager: Kein Artwork-Caching (lädt bei jedem speak() neu)
- SpeechPlayerViewModel: Kein `@MainActor` (wäre sauberer)
- Queue-Liste im Sheet: Drag&Drop Reorder könnte noch getestet/polished werden
- MiniPlayer im iPad-Layout (PadSidebarView) noch nicht optimal integriert
- Localization: Strings sind hardcoded in Views statt NSLocalizedString (z.B. PlayerSheetView)
- Seek-Bar Genauigkeit: Character-basiert, nicht zeitbasiert — könnte bei unterschiedlichen Sprachen ungenau sein
