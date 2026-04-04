# TTS Podcast-UX Redesign — Design Spec

**Date:** 2026-03-29
**Goal:** Transform the TTS read-aloud feature from an early preview into a podcast-like listening experience with queue management, seek, position persistence, lock screen controls, and improved voice settings.

**Approach:** Rebuild the player UI as a 3-tier system (Mini → Half-Sheet → Fullscreen). Keep `AVSpeechSynthesizer` as TTS engine. Extend `TTSManager` and `SpeechQueue` (post-bugfix) with position tracking, seek, and NowPlaying integration.

---

## 1. Player UI — 3-Tier Architecture

### Mini-Player
- Lives in `.tabViewBottomAccessory` (iOS 26) or ZStack overlay (iOS 18)
- Shows: thin progress bar at top edge, article title (1 line, truncated), Play/Pause button
- Tap anywhere (except Play/Pause) → opens Half-Sheet
- Visible when: `enableTTS && queue.hasItems` (no separate `isPlayerVisible` needed — if the queue has items, the mini player shows; closing = clearing the queue)

### Half-Sheet
- Presented as `.sheet` with `.presentationDetents([.medium, .large])`
- Content:
  - Article image as "cover art" (from `SpeechQueueItem.imageUrl`, fallback: app icon placeholder)
  - Article title + source domain
  - Seek bar with current position / estimated total duration (e.g. "2:34 / 8:12")
  - Transport controls: 30s back, Play/Pause, Next article
  - Speed picker (0.25x–3.0x) + Volume slider
  - "Queue" button → pulls sheet to `.large`

### Fullscreen (Sheet at `.large` detent)
- Everything from Half-Sheet at the top
- Below: queue list with:
  - Currently playing article highlighted
  - Drag & Drop reorder via native `List` + `.onMove`
  - Swipe-to-delete on individual items
  - "Clear Queue" button with confirmation dialog
  - Currently playing article (index 0) is not draggable

### Shared State
- All three tiers share one `SpeechPlayerViewModel` owned by `PhoneTabView` (iOS 26) or `GlobalPlayerContainerView` (iOS 18)
- Sheet presentation state managed via `@State private var isPlayerSheetPresented: Bool`

---

## 2. Position Tracking & Seek

### Character-Index Tracking
- `willSpeakRangeOfSpeechString` delivers the current `NSRange` on every spoken word
- Store `lastCharacterIndex: Int` on `SpeechQueueItem`
- Persist to UserDefaults every ~5 seconds and on Pause/Stop/App-Background

### Time Estimation
- Estimated total duration: `textLength / charactersPerSecond` (derived from `rate`)
- Current position: `characterIndex / totalCharacters * estimatedDuration`
- Seek bar displays "mm:ss / mm:ss"

### 30-Second Rewind
- Calculate `charsToSkipBack = 30 * charactersPerSecond`
- New index: `max(0, currentIndex - charsToSkipBack)`
- Stop current utterance, start new one from calculated index (substring of full text)

### Seek via Slider
- User drags seek bar → calculate target `characterIndex` from slider percentage
- Stop current utterance, start from new position
- Same mechanism as 30s rewind, different target index

### Resume After App Restart
- On app start: load queue + positions from UserDefaults
- Player shows with mini-player if queue is non-empty
- Playback does NOT auto-start — user must press Play

---

## 3. NowPlaying / Lock Screen Integration

### New class: `NowPlayingManager`
- Initialized by `TTSManager`
- Receives updates from `TTSManager` and `SpeechQueue`

### MPNowPlayingInfoCenter
- `MPMediaItemPropertyTitle` → article title
- `MPMediaItemPropertyArtist` → source domain
- `MPMediaItemPropertyArtwork` → article image (async download, app icon fallback)
- `MPMediaItemPropertyPlaybackDuration` → estimated duration
- `MPNowPlayingInfoPropertyElapsedPlaybackTime` → current position
- Update on: play, pause, seek, next article

### MPRemoteCommandCenter
- `playCommand` → TTSManager.resume()
- `pauseCommand` → TTSManager.pause()
- `nextTrackCommand` → next article in queue
- `previousTrackCommand` → 30s rewind (consistent with in-app behavior)
- `changePlaybackPositionCommand` → seek to position

---

## 4. Queue Management

### Adding Articles
- "Read article aloud" button → appends to end of queue (existing behavior)
- New "Play Next" option in article context menu (long-press / swipe action) → inserts after currently playing article
- If queue is empty, both start playback immediately

### Reorder
- Fullscreen queue list with native `List` + `.onMove` for drag & drop
- Currently playing article (index 0) is pinned — only waiting articles are movable

### Removing
- Swipe-to-delete on individual queue items
- Deleting the currently playing article = skip to next
- "Clear Queue" button with confirmation dialog

### After Listening
- Finished articles are automatically removed from queue
- Queue state persisted immediately

### Re-entry
- App start: load queue + positions from UserDefaults
- Mini-player appears automatically if queue is non-empty
- Playback does NOT auto-start — user presses Play

---

## 5. Voice Settings & Preview

### Integration
- Wire `TTSLanguageSettingsView` into Settings navigation (currently exists but not linked)
- Path: Settings → Language & Voices

### Voice Preview
- Per language: list all available system voices, grouped by quality (Premium, Enhanced, Default)
- Tap on a voice → plays a short sample sentence in that language (e.g. "Hallo, ich bin Anna. So werde ich deine Artikel vorlesen.")
- Selected voice marked with checkmark
- Selection saved per language (de → Helena, en → Samantha)

### Help for Better Voices
- Info box at top of voice list: "Premium voices sound more natural. You can download them in iOS Settings."
- Button "Download Premium Voices" → opens iOS Accessibility Settings (existing `openAccessibilitySettings()`)
- On return: `refreshVoices()` picks up newly downloaded voices (already implemented)

### Per-Language Voice Storage
- `VoiceManager` gets a dictionary `[String: String]` — language code → voice identifier
- Stored in UserDefaults as JSON
- Fallback: quality-based selection (premium > enhanced > default) as currently implemented

---

## 6. What Stays the Same

- **TTS Engine:** `AVSpeechSynthesizer` — no switch to AVPlayer or cloud TTS
- **TTS Toggle:** Remains opt-in in Settings
- **Backend Core:** `TTSManager` and `SpeechQueue` keep their structure (with current bugfixes), get extended
- **iPad:** Same player via `GlobalPlayerContainerView` — no separate iPad design
- **Offline:** Always works — live synthesis, no network required
- **Localization:** New strings for EN + DE, Weblate-compatible via `.strings` files

---

## 7. Future Enhancement: Cloud TTS

Not in scope for this iteration, but the architecture should not prevent it.

**Concept:** Allow users to optionally provide an OpenAI API key for higher-quality TTS via the `tts-1` / `tts-1-hd` API. This would generate real audio files (MP3), enabling native AVPlayer seek and significantly better voice quality.

**Why later:**
- Requires API key management UI + cost transparency for users
- Articles need pre-rendering and local caching
- Offline only works for already-generated articles
- Error handling for network, rate limits, billing

**Architecture compatibility:** The queue management, position tracking, NowPlaying integration, and player UI designed here work identically with both live synthesis and pre-rendered audio. The `TTSManager` could be abstracted behind a protocol to swap engines later.

---

## File Map (Expected)

| Area | Files | Action |
|------|-------|--------|
| Player UI | `SpeechPlayerView.swift` | Rewrite → Mini, Half-Sheet, Fullscreen |
| Player UI | `GlobalPlayerContainerView.swift` | Simplify to mini-player only |
| Player UI | `PhoneTabView.swift` | Update bottom accessory to mini-player |
| ViewModel | `SpeechPlayerViewModel.swift` | Extend with seek, position, sheet state |
| Position | `SpeechQueue.swift` | Add `lastCharacterIndex` tracking, reorder, insert-after |
| Position | `SpeechQueueItem` | Add `lastCharacterIndex` field |
| Position | `TTSManager.swift` | Extend `willSpeakRange` tracking, seek support |
| NowPlaying | `NowPlayingManager.swift` | New — MPNowPlayingInfoCenter + MPRemoteCommandCenter |
| Queue | `SpeechQueue.swift` | Add `insertAfter`, `move`, drag & drop support |
| Settings | `TTSLanguageSettingsView.swift` | Add voice preview, per-language selection |
| Settings | `VoiceManager.swift` | Per-language voice storage, preview playback |
| Settings | Wire into navigation | Link from Settings → Language & Voices |
| Localization | `Localizable.strings` | New strings for player, queue, settings |
