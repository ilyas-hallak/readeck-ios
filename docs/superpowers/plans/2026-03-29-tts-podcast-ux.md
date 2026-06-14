# TTS Podcast-UX Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the TTS read-aloud feature into a podcast-like listening experience with a 3-tier player UI, seek/position tracking, NowPlaying lock screen integration, drag & drop queue management, and voice preview settings.

**Architecture:** Rebuild the player UI as Mini-Player → Half-Sheet → Fullscreen (sheet detents). Extend `TTSManager` with character-position tracking and seek. Add `NowPlayingManager` for lock screen controls. Extend `SpeechQueue` with reorder/insert operations. Enhance `VoiceManager` with per-language voice selection and preview.

**Tech Stack:** Swift, SwiftUI, AVFoundation (AVSpeechSynthesizer), MediaPlayer (MPNowPlayingInfoCenter, MPRemoteCommandCenter), Combine

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `readeck/UI/Utils/TTSManager.swift` | Modify | Add character-position tracking, seek-to-position, `onPositionUpdate` callback |
| `readeck/UI/Utils/SpeechQueue.swift` | Modify | Add `lastCharacterIndex` to item, `insertAfterCurrent()`, `move()`, periodic position save, auto-show mini-player |
| `readeck/UI/Utils/VoiceManager.swift` | Modify | Per-language voice storage, preview playback |
| `readeck/UI/Utils/NowPlayingManager.swift` | Create | MPNowPlayingInfoCenter + MPRemoteCommandCenter integration |
| `readeck/UI/SpeechPlayer/MiniPlayerView.swift` | Create | Mini-player bar for tab accessory / ZStack overlay |
| `readeck/UI/SpeechPlayer/PlayerSheetView.swift` | Create | Half-Sheet + Fullscreen player with seek bar, queue list |
| `readeck/UI/SpeechPlayer/SpeechPlayerView.swift` | Rewrite | Thin wrapper coordinating MiniPlayerView + sheet presentation |
| `readeck/UI/SpeechPlayer/SpeechPlayerViewModel.swift` | Modify | Add seek, position, sheet state, next/previous, estimated duration |
| `readeck/UI/SpeechPlayer/GlobalPlayerContainerView.swift` | Modify | Use MiniPlayerView, manage sheet |
| `readeck/UI/Menu/PhoneTabView.swift` | Modify | Use MiniPlayerView in bottom accessory, manage sheet |
| `readeck/UI/Models/PlayerUIState.swift` | Delete | No longer needed — mini-player auto-shows when queue has items |
| `readeck/UI/Settings/TTSLanguageSettingsView.swift` | Rewrite | Voice list grouped by quality, tap-to-preview, per-language selection |
| `readeck/UI/Settings/ReadingSettingsView.swift` | Modify | Add NavigationLink to TTSLanguageSettingsView |
| `readeck/UI/Bookmarks/BookmarkCardView.swift` | Modify | Add "Play Next" swipe action |
| `readeck/UI/BookmarkDetail/BookmarkDetailView2.swift` | Modify | Add "Play Next" button alongside existing "Read article aloud" |
| `readeck/UI/BookmarkDetail/BookmarkDetailLegacyView.swift` | Modify | Same as above |
| `readeck/Localizations/Base.lproj/Localizable.strings` | Modify | New strings |
| `readeck/Localizations/de.lproj/Localizable.strings` | Modify | German translations |

---

### Task 1: Extend SpeechQueueItem with position tracking

Add `lastCharacterIndex` and `totalCharacters` to `SpeechQueueItem` so position can be persisted and restored.

**Files:**
- Modify: `readeck/UI/Utils/SpeechQueue.swift`

- [ ] **Step 1: Add position fields to SpeechQueueItem**

In `SpeechQueue.swift`, add two fields to the struct:

```swift
struct SpeechQueueItem: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let content: String?
    let url: String
    let labels: [String]?
    let imageUrl: String?
    let language: String
    var lastCharacterIndex: Int = 0
    var totalCharacters: Int = 0
}
```

- [ ] **Step 2: Update `toSpeechQueueItem` to set `totalCharacters`**

In the `BookmarkDetail` extension in the same file:

```swift
extension BookmarkDetail {
    func toSpeechQueueItem(_ content: String? = nil) -> SpeechQueueItem {
        let text = content ?? self.content ?? ""
        return SpeechQueueItem(
            id: self.id,
            title: title,
            content: content ?? self.content,
            url: url,
            labels: labels,
            imageUrl: imageUrl,
            language: lang.isEmpty ? "en" : lang,
            lastCharacterIndex: 0,
            totalCharacters: (title + "\n" + text).trimmingCharacters(in: .whitespacesAndNewlines).count
        )
    }
}
```

- [ ] **Step 3: Add position update method and periodic save to SpeechQueue**

Add a method to update position on the current item, and a timer-based save:

```swift
private var lastSaveTime: Date = .distantPast

func updateCurrentPosition(_ characterIndex: Int) {
    guard !queue.isEmpty else { return }
    queue[0].lastCharacterIndex = characterIndex
    queueItems = queue

    // Save every 5 seconds
    let now = Date()
    if now.timeIntervalSince(lastSaveTime) >= 5.0 {
        lastSaveTime = now
        saveQueue()
    }
}

func savePositionNow() {
    saveQueue()
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```
feat: add position tracking fields to SpeechQueueItem
```

---

### Task 2: Extend TTSManager with position tracking and seek

Add character-level position tracking via the `willSpeakRange` delegate and a `seek(to:)` method that restarts speech from a given character index.

**Files:**
- Modify: `readeck/UI/Utils/TTSManager.swift`

- [ ] **Step 1: Add position-tracking properties and callback**

Add after the existing `@Published` properties and callbacks:

```swift
@Published var currentCharacterIndex: Int = 0
@Published var totalCharacterCount: Int = 0
var onPositionUpdate: ((Int) -> Void)?

private var currentFullText: String = ""
private var currentLanguage: String = "en-US"
private var currentStartOffset: Int = 0
```

- [ ] **Step 2: Update `speak()` to store full text and support start offset**

Replace the existing `speak()` method:

```swift
func speak(text: String, language: String, utteranceIndex: Int = 0, totalUtterances: Int = 1, startFromCharacter: Int = 0) {
    guard !text.isEmpty else { return }

    if synthesizer.isSpeaking {
        synthesizer.stopSpeaking(at: .immediate)
    }

    self.currentFullText = text
    self.currentLanguage = language
    self.currentStartOffset = startFromCharacter
    self.totalCharacterCount = text.count
    self.currentCharacterIndex = startFromCharacter
    self.isSpeaking = true
    self.currentUtterance = text
    self.currentUtteranceIndex = utteranceIndex
    self.totalUtterances = totalUtterances
    self.updateProgress()
    self.articleProgress = text.isEmpty ? 0 : Double(startFromCharacter) / Double(text.count)

    let textToSpeak: String
    if startFromCharacter > 0 && startFromCharacter < text.count {
        let startIndex = text.index(text.startIndex, offsetBy: startFromCharacter)
        textToSpeak = String(text[startIndex...])
    } else {
        textToSpeak = text
    }

    let utterance = AVSpeechUtterance(string: textToSpeak)
    utterance.voice = voiceManager.getVoice(for: language)
    utterance.rate = rate
    utterance.pitchMultiplier = 1.0
    utterance.volume = volume
    synthesizer.speak(utterance)
}
```

- [ ] **Step 3: Update `willSpeakRangeOfSpeechString` to track absolute position**

Replace the existing delegate method:

```swift
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
    let spoken = characterRange.location + characterRange.length
    let absolutePosition = currentStartOffset + spoken
    let total = currentFullText.count

    DispatchQueue.main.async {
        self.currentCharacterIndex = absolutePosition
        if total > 0 {
            self.articleProgress = min(Double(absolutePosition) / Double(total), 1.0)
        }
        self.onPositionUpdate?(absolutePosition)
    }
}
```

- [ ] **Step 4: Add `seek(toCharacter:)` method**

```swift
func seek(toCharacter index: Int) {
    guard !currentFullText.isEmpty else { return }
    let clampedIndex = max(0, min(index, currentFullText.count))
    speak(
        text: currentFullText,
        language: currentLanguage,
        utteranceIndex: currentUtteranceIndex,
        totalUtterances: totalUtterances,
        startFromCharacter: clampedIndex
    )
}

func seekBack(seconds: Double = 30) {
    let charsPerSecond = estimatedCharactersPerSecond()
    let charsToSkip = Int(seconds * charsPerSecond)
    let targetIndex = max(0, currentCharacterIndex - charsToSkip)
    seek(toCharacter: targetIndex)
}

func seekForward(seconds: Double = 30) {
    let charsPerSecond = estimatedCharactersPerSecond()
    let charsToSkip = Int(seconds * charsPerSecond)
    let targetIndex = min(currentFullText.count, currentCharacterIndex + charsToSkip)
    seek(toCharacter: targetIndex)
}

func estimatedCharactersPerSecond() -> Double {
    // AVSpeechUtterance rate 0.5 ≈ natural speaking ≈ 15 chars/sec
    // Scale linearly: rate 0.25 ≈ 7.5, rate 1.0 ≈ 30
    return Double(rate) * 30.0
}

func estimatedDuration(for totalChars: Int) -> TimeInterval {
    let cps = estimatedCharactersPerSecond()
    return cps > 0 ? Double(totalChars) / cps : 0
}

func estimatedCurrentTime() -> TimeInterval {
    let cps = estimatedCharactersPerSecond()
    return cps > 0 ? Double(currentCharacterIndex) / cps : 0
}
```

- [ ] **Step 5: Update `stop()` and `pause()` to save position**

Update `stop()`:

```swift
func stop() {
    synthesizer.stopSpeaking(at: .immediate)
    isSpeaking = false
    currentUtterance = ""
    articleProgress = 0.0
    updateProgress()
    onPositionUpdate?(currentCharacterIndex)
}
```

Update `pause()`:

```swift
func pause() {
    synthesizer.pauseSpeaking(at: .immediate)
    isSpeaking = false
    onPositionUpdate?(currentCharacterIndex)
}
```

- [ ] **Step 6: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```
feat: add character-level position tracking and seek to TTSManager
```

---

### Task 3: Wire position tracking from TTSManager into SpeechQueue

Connect the `onPositionUpdate` callback and update `processQueue()` to support resume from saved position.

**Files:**
- Modify: `readeck/UI/Utils/SpeechQueue.swift`

- [ ] **Step 1: Register position callback in init**

Update the `init`:

```swift
private init(ttsManager: TTSManager = .shared) {
    self.ttsManager = ttsManager
    loadQueue()
    updatePublishedProperties()

    ttsManager.onUtteranceFinished = { [weak self] in
        self?.onCurrentItemFinished()
    }
    ttsManager.onUtteranceCancelled = { [weak self] in
        self?.onCurrentItemCancelled()
    }
    ttsManager.onPositionUpdate = { [weak self] charIndex in
        self?.updateCurrentPosition(charIndex)
    }
}
```

- [ ] **Step 2: Update `processQueue()` to resume from saved position**

Replace `processQueue()`:

```swift
private func processQueue() {
    guard !isProcessing, !queue.isEmpty else { return }
    isProcessing = true
    let next = queue[0]
    updatePublishedProperties()
    saveQueue()
    let currentIndex = queueItems.count - queue.count
    let textToSpeak = (next.title + "\n" + (next.content ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
    let languageCode = convertToBCP47(next.language)
    ttsManager.speak(
        text: textToSpeak,
        language: languageCode,
        utteranceIndex: currentIndex,
        totalUtterances: queueItems.count,
        startFromCharacter: next.lastCharacterIndex
    )
}
```

- [ ] **Step 3: Save position on pause/stop/background**

Add background observer and update `stop()`:

```swift
func stop() {
    print("[SpeechQueue] stop() aufgerufen")
    saveQueue()
    ttsManager.stop()
    isProcessing = false
    updatePublishedProperties()
}

func pauseAndSave() {
    ttsManager.pause()
    saveQueue()
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```
feat: wire position tracking between TTSManager and SpeechQueue
```

---

### Task 4: Add queue management operations (insertAfter, move, next/previous)

Extend `SpeechQueue` with insert-after-current, reorder, and skip operations.

**Files:**
- Modify: `readeck/UI/Utils/SpeechQueue.swift`

- [ ] **Step 1: Add `insertAfterCurrent()` method**

```swift
func insertAfterCurrent(_ item: SpeechQueueItem) {
    if queue.isEmpty {
        enqueue(item)
    } else {
        queue.insert(item, at: 1)
        updatePublishedProperties()
        saveQueue()
        if !isProcessing {
            processQueue()
        }
    }
}
```

- [ ] **Step 2: Add `move()` for drag & drop reorder**

```swift
func move(from source: IndexSet, to destination: Int) {
    // Don't allow moving the currently playing item (index 0)
    let adjustedSource = source.filter { $0 > 0 }
    guard !adjustedSource.isEmpty else { return }
    let adjustedDestination = max(1, destination)
    queue.move(fromOffsets: IndexSet(adjustedSource), toOffset: adjustedDestination)
    updatePublishedProperties()
    saveQueue()
}

func remove(at offsets: IndexSet) {
    let removingCurrent = offsets.contains(0)
    queue.remove(atOffsets: offsets)
    updatePublishedProperties()
    saveQueue()
    if removingCurrent {
        ttsManager.stop()
        isProcessing = false
        processQueue()
    }
}
```

- [ ] **Step 3: Add `skipToNext()` and seeking**

```swift
func skipToNext() {
    guard !queue.isEmpty else { return }
    ttsManager.stop()
    queue.removeFirst()
    isProcessing = false
    updatePublishedProperties()
    saveQueue()
    processQueue()
}

func seekBack(seconds: Double = 30) {
    ttsManager.seekBack(seconds: seconds)
}

func seekForward(seconds: Double = 30) {
    ttsManager.seekForward(seconds: seconds)
}

func seekToPosition(_ percentage: Double) {
    guard let current = queue.first else { return }
    let totalChars = current.totalCharacters
    let targetChar = Int(percentage * Double(totalChars))
    ttsManager.seek(toCharacter: targetChar)
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```
feat: add queue management operations (insert, move, skip, seek)
```

---

### Task 5: Update SpeechPlayerViewModel with new capabilities

Extend the ViewModel with seek, position, next/previous, estimated time, and sheet presentation state.

**Files:**
- Modify: `readeck/UI/SpeechPlayer/SpeechPlayerViewModel.swift`

- [ ] **Step 1: Add new published properties**

Add after the existing `@Published` properties:

```swift
@Published var currentCharacterIndex: Int = 0
@Published var totalCharacterCount: Int = 0
@Published var isPlayerSheetPresented: Bool = false
@Published var selectedSheetDetent: PresentationDetent = .medium
```

- [ ] **Step 2: Add new bindings in `setupBindings()`**

Add at the end of `setupBindings()`:

```swift
ttsManager?.$currentCharacterIndex
    .assign(to: \.currentCharacterIndex, on: self)
    .store(in: &cancellables)

ttsManager?.$totalCharacterCount
    .assign(to: \.totalCharacterCount, on: self)
    .store(in: &cancellables)
```

- [ ] **Step 3: Add new methods**

```swift
var estimatedDuration: TimeInterval {
    ttsManager?.estimatedDuration(for: totalCharacterCount) ?? 0
}

var estimatedCurrentTime: TimeInterval {
    ttsManager?.estimatedCurrentTime() ?? 0
}

func seekBack() {
    speechQueue?.seekBack(seconds: 30)
}

func seekForward() {
    speechQueue?.seekForward(seconds: 30)
}

func seekToPosition(_ percentage: Double) {
    speechQueue?.seekToPosition(percentage)
}

func skipToNext() {
    speechQueue?.skipToNext()
}

func insertAfterCurrent(_ item: SpeechQueueItem) {
    speechQueue?.insertAfterCurrent(item)
}

func moveItems(from source: IndexSet, to destination: Int) {
    speechQueue?.move(from: source, to: destination)
}

func removeItems(at offsets: IndexSet) {
    speechQueue?.remove(at: offsets)
}

func clearQueue() {
    speechQueue?.clear()
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```
feat: extend SpeechPlayerViewModel with seek, skip, queue management
```

---

### Task 6: Create MiniPlayerView

Build the compact mini-player bar that lives in the tab bar accessory or ZStack overlay.

**Files:**
- Create: `readeck/UI/SpeechPlayer/MiniPlayerView.swift`

- [ ] **Step 1: Create MiniPlayerView**

```swift
import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar at top
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * viewModel.articleProgress, height: 2)
            }
            .frame(height: 2)

            HStack(spacing: 12) {
                // Article title
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.queueItems.first?.title ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if viewModel.queueCount > 1 {
                        Text("\(viewModel.queueCount) articles in queue")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .onTapGesture { onTap() }

                Spacer()

                // Play/Pause
                Button(action: {
                    if viewModel.isSpeaking {
                        viewModel.pause()
                    } else {
                        viewModel.resume()
                    }
                }) {
                    Image(systemName: viewModel.isSpeaking ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```
feat: create MiniPlayerView for tab bar accessory
```

---

### Task 7: Create PlayerSheetView (Half-Sheet + Fullscreen)

Build the sheet-based player with seek bar, transport controls, and queue list.

**Files:**
- Create: `readeck/UI/SpeechPlayer/PlayerSheetView.swift`

- [ ] **Step 1: Create the main PlayerSheetView**

```swift
import SwiftUI

struct PlayerSheetView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    @State private var seekPosition: Double? = nil
    @State private var isSeeking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                playerHeader
                seekBar
                transportControls
                speedAndVolume
                queueSection
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Header with cover art

    @ViewBuilder
    private var playerHeader: some View {
        VStack(spacing: 12) {
            // Cover image
            if let imageUrl = viewModel.queueItems.first?.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    coverPlaceholder
                }
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
            } else {
                coverPlaceholder
            }

            // Title + source
            Text(viewModel.queueItems.first?.title ?? "")
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 20)

            if let url = viewModel.queueItems.first?.url,
               let host = URL(string: url)?.host {
                Text(host)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .frame(width: 200, height: 200)
            .overlay(
                Image(systemName: "book.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
            )
    }

    // MARK: - Seek Bar

    @ViewBuilder
    private var seekBar: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { seekPosition ?? viewModel.articleProgress },
                    set: { newValue in
                        seekPosition = newValue
                        isSeeking = true
                    }
                ),
                in: 0...1,
                onEditingChanged: { editing in
                    if !editing, let position = seekPosition {
                        viewModel.seekToPosition(position)
                        seekPosition = nil
                        isSeeking = false
                    }
                }
            )
            .accentColor(.accentColor)

            HStack {
                Text(formatTime(viewModel.estimatedCurrentTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                Spacer()
                Text(formatTime(viewModel.estimatedDuration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Transport Controls

    @ViewBuilder
    private var transportControls: some View {
        HStack(spacing: 40) {
            // 30s back
            Button(action: { viewModel.seekBack() }) {
                Image(systemName: "gobackward.30")
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            // Play/Pause
            Button(action: {
                if viewModel.isSpeaking {
                    viewModel.pause()
                } else {
                    viewModel.resume()
                }
            }) {
                Image(systemName: viewModel.isSpeaking ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
            }

            // Next article
            Button(action: { viewModel.skipToNext() }) {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.queueCount > 1 ? .primary : .secondary)
            }
            .disabled(viewModel.queueCount <= 1)
        }
    }

    // MARK: - Speed & Volume

    @ViewBuilder
    private var speedAndVolume: some View {
        VStack(spacing: 12) {
            // Speed
            HStack {
                Text("Speed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Picker("Speed", selection: Binding(
                    get: { viewModel.rate },
                    set: { viewModel.setRate($0) }
                )) {
                    ForEach([Float(0.25), 0.5, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0], id: \.self) { value in
                        Text(String(format: "%.2fx", value)).tag(value)
                    }
                }
                .pickerStyle(.menu)
            }

            // Volume
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: Binding(
                    get: { viewModel.volume },
                    set: { viewModel.setVolume($0) }
                ), in: 0...1)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Queue Section

    @ViewBuilder
    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Queue")
                    .font(.headline)
                Spacer()
                if viewModel.queueCount > 1 {
                    Button("Clear All") {
                        viewModel.clearQueue()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 24)

            List {
                ForEach(Array(viewModel.queueItems.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        if index == 0 {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.accentColor)
                                .font(.caption)
                                .frame(width: 24)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                        }
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            if let host = URL(string: item.url)?.host {
                                Text(host)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    viewModel.removeItems(at: offsets)
                }
                .onMove { source, destination in
                    viewModel.moveItems(from: source, to: destination)
                }
            }
            .listStyle(.plain)
            .frame(minHeight: 200)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```
feat: create PlayerSheetView with seek bar, controls, and queue list
```

---

### Task 8: Rewrite SpeechPlayerView as coordinator

Replace the old collapsed/expanded view with the new Mini → Sheet architecture.

**Files:**
- Rewrite: `readeck/UI/SpeechPlayer/SpeechPlayerView.swift`

- [ ] **Step 1: Rewrite SpeechPlayerView**

Replace the entire file content:

```swift
import SwiftUI

struct SpeechPlayerView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel

    var body: some View {
        MiniPlayerView(viewModel: viewModel) {
            viewModel.isPlayerSheetPresented = true
        }
        .sheet(isPresented: $viewModel.isPlayerSheetPresented) {
            PlayerSheetView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
    }
}

#Preview {
    SpeechPlayerView(viewModel: SpeechPlayerViewModel())
}
```

- [ ] **Step 2: Update GlobalPlayerContainerView**

In `GlobalPlayerContainerView.swift`, update the visibility condition. Remove `playerUIState` dependency — mini-player shows whenever queue has items:

```swift
import SwiftUI

struct GlobalPlayerContainerView<Content: View>: View {
    let content: Content
    @StateObject private var viewModel = SpeechPlayerViewModel()
    @EnvironmentObject var appSettings: AppSettings

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if appSettings.enableTTS && viewModel.hasItems {
                VStack(spacing: 0) {
                    SpeechPlayerView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 49)
                }
            }
        }
        .animation(.spring(), value: viewModel.hasItems)
        .task {
            await viewModel.setup()
        }
    }
}

#Preview {
    GlobalPlayerContainerView {
        Text("Main Content")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
    .environmentObject(AppSettings())
}
```

- [ ] **Step 3: Update PhoneTabView**

In `PhoneTabView.swift`, update the `shouldShowPlayer` and bottom accessory to remove `playerUIState` dependency:

```swift
private var shouldShowPlayer: Bool {
    appSettings.enableTTS && speechPlayerViewModel.hasItems
}
```

And update the bottom accessory content:

```swift
if #available(iOS 26.1, *) {
    tabViewContent
        .tabViewBottomAccessory(isEnabled: shouldShowPlayer) {
            SpeechPlayerView(viewModel: speechPlayerViewModel)
        }
        .task {
            await speechPlayerViewModel.setup()
        }
} else {
    GlobalPlayerContainerView {
        tabViewContent
    }
}
```

- [ ] **Step 4: Remove `playerUIState` references from PhoneTabView**

Remove `@EnvironmentObject var playerUIState: PlayerUIState` from `PhoneTabView` since the mini-player now auto-shows based on queue state.

- [ ] **Step 5: Update BookmarkDetailView2 and BookmarkDetailLegacyView**

In both files, remove `playerUIState.showPlayer()` from the "Read article aloud" button — it's no longer needed since the mini-player auto-appears:

```swift
if appSettings.enableTTS {
    metaRow(icon: "speaker.wave.2") {
        Button(action: {
            viewModel.addBookmarkToSpeechQueue()
        }) {
            Text("Read article aloud")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
```

- [ ] **Step 6: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED — fix any remaining `playerUIState` references if the build fails

- [ ] **Step 7: Commit**

```
feat: rewrite player as Mini → Sheet architecture, auto-show on queue
```

---

### Task 9: Create NowPlayingManager for lock screen controls

Integrate with `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` for lock screen and Control Center controls.

**Files:**
- Create: `readeck/UI/Utils/NowPlayingManager.swift`
- Modify: `readeck/UI/Utils/TTSManager.swift`

- [ ] **Step 1: Create NowPlayingManager**

```swift
import Foundation
import MediaPlayer
import UIKit

class NowPlayingManager {
    static let shared = NowPlayingManager()
    private let commandCenter = MPRemoteCommandCenter.shared()
    private var ttsManager: TTSManager { .shared }
    private var speechQueue: SpeechQueue { .shared }

    private init() {
        setupRemoteCommands()
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.ttsManager.resume()
            self?.updateNowPlayingPlaybackState(isPlaying: true)
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.ttsManager.pause()
            self?.updateNowPlayingPlaybackState(isPlaying: false)
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.speechQueue.skipToNext()
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.ttsManager.seekBack(seconds: 30)
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            let cps = self?.ttsManager.estimatedCharactersPerSecond() ?? 15
            let targetChar = Int(positionEvent.positionTime * cps)
            self?.ttsManager.seek(toCharacter: targetChar)
            return .success
        }
    }

    // MARK: - Now Playing Info

    func updateNowPlayingInfo(title: String, source: String?, imageUrl: String?, duration: TimeInterval, currentTime: TimeInterval) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]

        if let source {
            info[MPMediaItemPropertyArtist] = source
        }

        // Load artwork async
        if let imageUrl, let url = URL(string: imageUrl) {
            loadArtwork(from: url) { artwork in
                if let artwork {
                    var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                    updatedInfo[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
                }
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func updateNowPlayingPlaybackState(isPlaying: Bool) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = ttsManager.estimatedCurrentTime()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func updateNowPlayingPosition() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = ttsManager.estimatedCurrentTime()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Artwork Loading

    private func loadArtwork(from url: URL, completion: @escaping (MPMediaItemArtwork?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            DispatchQueue.main.async { completion(artwork) }
        }.resume()
    }
}
```

- [ ] **Step 2: Wire NowPlayingManager into TTSManager**

In `TTSManager.swift`, add a property and update the relevant methods:

Add property after the callbacks:

```swift
private lazy var nowPlayingManager = NowPlayingManager.shared
```

In `speak()`, after `synthesizer.speak(utterance)`, add:

```swift
let source = SpeechQueue.shared.currentItem.flatMap { URL(string: $0.url)?.host }
let imageUrl = SpeechQueue.shared.currentItem?.imageUrl
nowPlayingManager.updateNowPlayingInfo(
    title: SpeechQueue.shared.currentItem?.title ?? "",
    source: source,
    imageUrl: imageUrl,
    duration: estimatedDuration(for: currentFullText.count),
    currentTime: estimatedCurrentTime()
)
```

In `pause()`, add:

```swift
nowPlayingManager.updateNowPlayingPlaybackState(isPlaying: false)
```

In `resume()`, add:

```swift
nowPlayingManager.updateNowPlayingPlaybackState(isPlaying: true)
```

In `stop()`, add:

```swift
nowPlayingManager.clearNowPlaying()
```

In `willSpeakRangeOfSpeechString`, add inside the `DispatchQueue.main.async` block:

```swift
self.nowPlayingManager.updateNowPlayingPosition()
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```
feat: add NowPlaying lock screen controls for TTS
```

---

### Task 10: Add "Play Next" action to bookmark cards and detail views

Add a "Play Next" swipe action on bookmark cards and a button in article detail.

**Files:**
- Modify: `readeck/UI/Bookmarks/BookmarkCardView.swift`
- Modify: `readeck/UI/BookmarkDetail/BookmarkDetailView2.swift`
- Modify: `readeck/UI/BookmarkDetail/BookmarkDetailLegacyView.swift`

- [ ] **Step 1: Add `onPlayNext` callback to BookmarkCardView**

In `BookmarkCardView.swift`, add the callback to the init:

```swift
var onPlayNext: ((Bookmark) -> Void)? = nil
```

Add a new swipe action in the leading edge group, after the favorite button:

```swift
if onPlayNext != nil {
    Button {
        onPlayNext?(bookmark)
    } label: {
        Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
    }
    .tint(.purple)
}
```

- [ ] **Step 2: Add "Play Next" button in BookmarkDetailView2**

In `BookmarkDetailView2.swift`, add below the existing "Read article aloud" button, still inside the `if appSettings.enableTTS` block:

```swift
metaRow(icon: "text.line.first.and.arrowtriangle.forward") {
    Button(action: {
        viewModel.addBookmarkToSpeechQueueNext()
    }) {
        Text("Play Next")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
}
```

This requires adding `addBookmarkToSpeechQueueNext()` to `BookmarkDetailViewModel`. Add in `BookmarkDetailViewModel.swift`:

```swift
func addBookmarkToSpeechQueueNext() {
    bookmarkDetail.content = articleContent
    let text = bookmarkDetail.title + "\n" + (articleContent?.stripHTML ?? bookmarkDetail.description.stripHTML)
    SpeechQueue.shared.insertAfterCurrent(bookmarkDetail.toSpeechQueueItem(text))
}
```

- [ ] **Step 3: Apply the same to BookmarkDetailLegacyView**

Add the same "Play Next" button in `BookmarkDetailLegacyView.swift` below the existing "Read article aloud" button.

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```
feat: add Play Next action to bookmark cards and detail views
```

---

### Task 11: Rewrite TTSLanguageSettingsView with voice preview and per-language selection

Replace the simple language picker with a full voice browser: grouped by quality, tap-to-preview, per-language selection.

**Files:**
- Modify: `readeck/UI/Utils/VoiceManager.swift`
- Rewrite: `readeck/UI/Settings/TTSLanguageSettingsView.swift`
- Modify: `readeck/UI/Settings/ReadingSettingsView.swift`

- [ ] **Step 1: Add per-language voice storage and preview to VoiceManager**

In `VoiceManager.swift`, add:

```swift
private let perLanguageVoiceKey = "tts_per_language_voices"
private(set) var perLanguageVoices: [String: String] = [:] // languageCode -> voiceIdentifier
private var previewSynthesizer = AVSpeechSynthesizer()

private func loadPerLanguageVoices() {
    if let data = userDefaults.data(forKey: perLanguageVoiceKey),
       let dict = try? JSONDecoder().decode([String: String].self, from: data) {
        perLanguageVoices = dict
    }
}

func setVoice(_ voice: AVSpeechSynthesisVoice, for language: String) {
    perLanguageVoices[language] = voice.identifier
    cachedVoices.removeValue(forKey: language)
    if let data = try? JSONEncoder().encode(perLanguageVoices) {
        userDefaults.set(data, forKey: perLanguageVoiceKey)
    }
}

func getSelectedVoiceIdentifier(for language: String) -> String? {
    return perLanguageVoices[language]
}

func previewVoice(_ voice: AVSpeechSynthesisVoice, sampleText: String) {
    previewSynthesizer.stopSpeaking(at: .immediate)
    let utterance = AVSpeechUtterance(string: sampleText)
    utterance.voice = voice
    utterance.rate = 0.5
    previewSynthesizer.speak(utterance)
}

func stopPreview() {
    previewSynthesizer.stopSpeaking(at: .immediate)
}
```

Call `loadPerLanguageVoices()` at the end of `private init()`.

Update `getVoice(for:)` to check per-language voices first:

```swift
func getVoice(for language: String) -> AVSpeechSynthesisVoice {
    if let cachedVoice = cachedVoices[language] {
        return cachedVoice
    }

    // Check per-language selection
    if let voiceId = perLanguageVoices[language],
       let voice = availableVoices.first(where: { $0.identifier == voiceId }) {
        cachedVoices[language] = voice
        return voice
    }

    // Check global selectedVoice if language matches
    let langPrefix = String(language.prefix(2))
    if let selected = selectedVoice, selected.language.hasPrefix(langPrefix) {
        cachedVoices[language] = selected
        return selected
    }

    let voice = findEnhancedVoice(for: language)
    cachedVoices[language] = voice
    return voice
}
```

- [ ] **Step 2: Rewrite TTSLanguageSettingsView**

Replace the entire file:

```swift
import SwiftUI
import AVFoundation

struct TTSLanguageSettingsView: View {
    @AppStorage("tts_preferred_language") private var preferredLanguage: String = "en-US"
    @ObservedObject private var voiceManager = VoiceManager.shared
    @State private var selectedLanguage: String? = nil
    @State private var previewingVoiceId: String? = nil

    private let supportedLanguages: [(code: String, name: String)] = [
        ("de-DE", "Deutsch"),
        ("en-US", "English (US)"),
        ("en-GB", "English (UK)"),
        ("es-ES", "Español"),
        ("fr-FR", "Français"),
        ("it-IT", "Italiano"),
        ("pt-PT", "Português"),
        ("nl-NL", "Nederlands"),
        ("pl-PL", "Polski"),
        ("ru-RU", "Русский"),
        ("ja-JP", "日本語"),
        ("zh-CN", "中文"),
        ("ko-KR", "한국어"),
        ("ar-SA", "العربية"),
        ("tr-TR", "Türkçe"),
        ("sv-SE", "Svenska"),
        ("da-DK", "Dansk"),
        ("nb-NO", "Norsk"),
        ("fi-FI", "Suomi"),
        ("cs-CZ", "Čeština"),
        ("hu-HU", "Magyar"),
        ("ro-RO", "Română"),
        ("sk-SK", "Slovenčina"),
        ("uk-UA", "Українська"),
        ("el-GR", "Ελληνικά"),
        ("he-IL", "עברית"),
        ("hi-IN", "हिन्दी"),
        ("th-TH", "ไทย"),
        ("id-ID", "Bahasa Indonesia"),
        ("vi-VN", "Tiếng Việt"),
    ].sorted { $0.name < $1.name }

    var body: some View {
        List {
            Section {
                ForEach(supportedLanguages, id: \.code) { language in
                    NavigationLink {
                        VoiceListView(languageCode: language.code, languageName: language.name)
                    } label: {
                        HStack {
                            Text(language.name)
                            Spacer()
                            if let voiceId = voiceManager.getSelectedVoiceIdentifier(for: language.code),
                               let voice = voiceManager.availableVoices.first(where: { $0.identifier == voiceId }) {
                                Text(voice.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Auto")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Languages & Voices")
            } footer: {
                Text("Select a voice for each language. Articles are read in their detected language.")
            }

            Section {
                Button {
                    openAccessibilitySettings()
                } label: {
                    HStack {
                        Label("Download Premium Voices", systemImage: "arrow.down.circle")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                Text("Premium voices sound more natural. Download them in iOS Settings > Accessibility > Spoken Content > Voices.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Language & Voices")
        .onAppear {
            voiceManager.refreshVoices()
        }
        .onDisappear {
            voiceManager.stopPreview()
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "App-prefs:ACCESSIBILITY&path=SPOKEN_CONTENT") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Voice List for a specific language

struct VoiceListView: View {
    let languageCode: String
    let languageName: String
    @ObservedObject private var voiceManager = VoiceManager.shared
    @State private var previewingVoiceId: String? = nil

    private var voicesByQuality: [(quality: String, voices: [AVSpeechSynthesisVoice])] {
        let voices = voiceManager.getAvailableVoices(for: languageCode)
        var groups: [(String, [AVSpeechSynthesisVoice])] = []

        let premium = voices.filter { $0.quality == .premium }
        let enhanced = voices.filter { $0.quality == .enhanced }
        let standard = voices.filter { $0.quality == .default }

        if !premium.isEmpty { groups.append(("Premium", premium)) }
        if !enhanced.isEmpty { groups.append(("Enhanced", enhanced)) }
        if !standard.isEmpty { groups.append(("Default", standard)) }

        return groups
    }

    private var selectedVoiceId: String? {
        voiceManager.getSelectedVoiceIdentifier(for: languageCode)
    }

    var body: some View {
        List {
            // Auto option
            Section {
                Button {
                    voiceManager.setVoice(voiceManager.getAvailableVoices(for: languageCode).first!, for: "")
                    // Remove per-language override
                    voiceManager.perLanguageVoices.removeValue(forKey: languageCode)
                } label: {
                    HStack {
                        Text("Automatic (best available)")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedVoiceId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }

            ForEach(voicesByQuality, id: \.quality) { group in
                Section(group.quality) {
                    ForEach(group.voices, id: \.identifier) { voice in
                        Button {
                            voiceManager.setVoice(voice, for: languageCode)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(voice.name)
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                                if selectedVoiceId == voice.identifier {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                                // Preview button
                                Button {
                                    if previewingVoiceId == voice.identifier {
                                        voiceManager.stopPreview()
                                        previewingVoiceId = nil
                                    } else {
                                        let sampleText = sampleSentence(for: languageCode, voiceName: voice.name)
                                        voiceManager.previewVoice(voice, sampleText: sampleText)
                                        previewingVoiceId = voice.identifier
                                    }
                                } label: {
                                    Image(systemName: previewingVoiceId == voice.identifier ? "stop.circle.fill" : "play.circle")
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(languageName)
        .onDisappear {
            voiceManager.stopPreview()
            previewingVoiceId = nil
        }
    }

    private func sampleSentence(for language: String, voiceName: String) -> String {
        switch language.prefix(2) {
        case "de": return "Hallo, ich bin \(voiceName). So werde ich deine Artikel vorlesen."
        case "en": return "Hi, I'm \(voiceName). This is how I'll read your articles."
        case "es": return "Hola, soy \(voiceName). Así leeré tus artículos."
        case "fr": return "Bonjour, je suis \(voiceName). Voici comment je lirai vos articles."
        case "it": return "Ciao, sono \(voiceName). Ecco come leggerò i tuoi articoli."
        default: return "Hello, I'm \(voiceName). This is how I'll read your articles."
        }
    }
}

#Preview {
    NavigationStack {
        TTSLanguageSettingsView()
    }
}
```

- [ ] **Step 3: Wire TTSLanguageSettingsView into ReadingSettingsView**

In `ReadingSettingsView.swift`, add a NavigationLink when TTS is enabled:

```swift
var body: some View {
    Group {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Read Aloud Feature", isOn: $viewModel.enableTTS)
                    .onChange(of: viewModel.enableTTS) {
                        Task {
                            await viewModel.saveGeneralSettings()
                        }
                    }

                Text("Activate the Read Aloud Feature to read aloud your articles.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }

            if viewModel.enableTTS {
                NavigationLink {
                    TTSLanguageSettingsView()
                } label: {
                    HStack {
                        Label("Language & Voices", systemImage: "waveform")
                        Spacer()
                    }
                }
            }
        } header: {
            Text("Reading Settings")
        }
    }
    .task {
        await viewModel.loadGeneralSettings()
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```
feat: add voice preview, per-language selection, wire settings navigation
```

---

### Task 12: Add localization strings

Add English and German strings for all new UI text.

**Files:**
- Modify: `readeck/Localizations/Base.lproj/Localizable.strings`
- Modify: `readeck/Localizations/de.lproj/Localizable.strings`

- [ ] **Step 1: Add English strings**

Append to `Base.lproj/Localizable.strings`:

```
// TTS Player
"Play Next" = "Play Next";
"Queue" = "Queue";
"Clear All" = "Clear All";
"Speed" = "Speed";
"articles in queue" = "articles in queue";

// TTS Settings
"Languages & Voices" = "Languages & Voices";
"Language & Voices" = "Language & Voices";
"Auto" = "Auto";
"Automatic (best available)" = "Automatic (best available)";
"Download Premium Voices" = "Download Premium Voices";
"Premium voices sound more natural. Download them in iOS Settings > Accessibility > Spoken Content > Voices." = "Premium voices sound more natural. Download them in iOS Settings > Accessibility > Spoken Content > Voices.";
"Select a voice for each language. Articles are read in their detected language." = "Select a voice for each language. Articles are read in their detected language.";
"Premium" = "Premium";
"Enhanced" = "Enhanced";
"Default" = "Default";
```

- [ ] **Step 2: Add German strings**

Append to `de.lproj/Localizable.strings`:

```
// TTS Player
"Play Next" = "Als Nächstes abspielen";
"Queue" = "Warteschlange";
"Clear All" = "Alle entfernen";
"Speed" = "Geschwindigkeit";
"articles in queue" = "Artikel in der Warteschlange";

// TTS Settings
"Languages & Voices" = "Sprachen & Stimmen";
"Language & Voices" = "Sprachen & Stimmen";
"Auto" = "Automatisch";
"Automatic (best available)" = "Automatisch (beste verfügbar)";
"Download Premium Voices" = "Premium-Stimmen laden";
"Premium voices sound more natural. Download them in iOS Settings > Accessibility > Spoken Content > Voices." = "Premium-Stimmen klingen natürlicher. Lade sie unter iOS-Einstellungen > Bedienungshilfen > Gesprochene Inhalte > Stimmen.";
"Select a voice for each language. Articles are read in their detected language." = "Wähle eine Stimme für jede Sprache. Artikel werden in ihrer erkannten Sprache vorgelesen.";
"Premium" = "Premium";
"Enhanced" = "Erweitert";
"Default" = "Standard";
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```
feat: add TTS localization strings for EN and DE
```

---

### Task 13: Clean up PlayerUIState and unused code

Remove `PlayerUIState` and all references since the mini-player now auto-shows based on queue state.

**Files:**
- Delete: `readeck/UI/Models/PlayerUIState.swift`
- Modify: Any remaining files referencing `PlayerUIState`

- [ ] **Step 1: Search for all PlayerUIState references**

Run: `grep -r "PlayerUIState\|playerUIState\|isPlayerVisible\|showPlayer\|hidePlayer" --include="*.swift" readeck/`

Remove or update all references. Common locations:
- `MainTabView.swift` or app entry — remove `.environmentObject(PlayerUIState())`
- `PlayerQueueResumeButton.swift` — simplify to just show resume when queue has items but not speaking
- Any remaining views that inject or use `playerUIState`

- [ ] **Step 2: Delete PlayerUIState.swift**

Remove the file.

- [ ] **Step 3: Update PlayerQueueResumeButton**

Simplify since there's no more `isPlayerVisible` concept:

```swift
struct PlayerQueueResumeButton: View {
    @ObservedObject private var queue = SpeechQueue.shared

    var body: some View {
        if queue.hasItems {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Read-aloud Queue")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(queue.queueItems.count) articles in the queue")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(Color(.systemBackground))
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color(.systemBackground))
            .padding(.bottom, 8)
        }
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep -E "BUILD SUCCEEDED|BUILD FAILED|error:" | tail -5`
Expected: BUILD SUCCEEDED — fix any remaining references

- [ ] **Step 5: Commit**

```
refactor: remove PlayerUIState, mini-player auto-shows on queue state
```

---

## Summary of Changes

| Feature | Implementation |
|---------|---------------|
| 3-tier Player (Mini → Half → Full) | MiniPlayerView + PlayerSheetView with `.presentationDetents` |
| Position Tracking | `lastCharacterIndex` on SpeechQueueItem, `willSpeakRange` callback |
| Seek (30s back, slider) | `TTSManager.seek(toCharacter:)`, substring-based re-utterance |
| Resume after restart | Position persisted to UserDefaults, restored on processQueue |
| Lock Screen / Control Center | NowPlayingManager with MPNowPlayingInfoCenter + MPRemoteCommandCenter |
| Queue: Play Next | `SpeechQueue.insertAfterCurrent()`, swipe action + detail button |
| Queue: Drag & Drop | `List` + `.onMove` + `.onDelete` in PlayerSheetView |
| Voice Preview | `VoiceManager.previewVoice()`, per-language selection UI |
| Settings Navigation | TTSLanguageSettingsView linked from ReadingSettingsView |
| Auto-show Player | Mini-player visible when `enableTTS && hasItems`, no manual show/hide |
