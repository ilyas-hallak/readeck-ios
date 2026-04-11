# TTS Bugfix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the buggy TTS feature — eliminate polling-based queue processing, fix language defaults, resolve race conditions, fix player UI visibility, and adopt iOS 26 native `.tabViewBottomAccessory` for the player.

**Architecture:** Replace the polling loop in `SpeechQueue` with delegate-based callbacks from `TTSManager`. Fix hard-coded German language defaults. Ensure thread-safe queue operations. Fix the player never appearing by resolving the ViewModel setup chicken-and-egg problem. On iOS 26 iPhone, use `.tabViewBottomAccessory` for native tab bar integration; on iPad and iOS 18, keep the ZStack overlay (with fixes).

**Tech Stack:** Swift, AVFoundation (AVSpeechSynthesizer), Combine, SwiftUI

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `readeck/UI/Utils/TTSManager.swift` | Modify | Add completion/cancel callbacks, remove language default, fix audio session, thread safety |
| `readeck/UI/Utils/SpeechQueue.swift` | Modify | Replace polling with callback, thread-safe queue ops |
| `readeck/UI/Utils/VoiceManager.swift` | Modify | Remove hard-coded `"de-DE"` default, fix selectedVoice language check, quality-based voice selection |
| `readeck/UI/Settings/TTSLanguageSettingsView.swift` | Modify | Refresh voice cache on appear |
| `readeck/UI/SpeechPlayer/SpeechPlayerViewModel.swift` | Modify | Fix stop() to clear queue |
| `readeck/UI/SpeechPlayer/SpeechPlayerView.swift` | Modify | Remove local ViewModel, accept it from parent |
| `readeck/UI/SpeechPlayer/GlobalPlayerContainerView.swift` | Modify | Call `setup()` on ViewModel, pass it to SpeechPlayerView |
| `readeck/UI/Menu/PhoneTabView.swift` | Modify | Add `.tabViewBottomAccessory` for iOS 26, keep GlobalPlayerContainerView for iOS 18 |

---

### Task 1: Fix player UI never appearing (ViewModel setup bug)

The `GlobalPlayerContainerView` creates its own `SpeechPlayerViewModel` but never calls `setup()`, so Combine bindings are never established and `hasItems` stays `false` forever. Meanwhile `SpeechPlayerView` creates a *second* ViewModel and calls `setup()` on it in `onAppear` — but that View is never shown because the container already hides it.

**Files:**
- Modify: `readeck/UI/SpeechPlayer/GlobalPlayerContainerView.swift`
- Modify: `readeck/UI/SpeechPlayer/SpeechPlayerView.swift`

- [ ] **Step 1: Add `.task` to `GlobalPlayerContainerView` to call `setup()`**

In `GlobalPlayerContainerView.swift`, add a `.task` modifier to the ZStack so the ViewModel's bindings get established:

```swift
struct GlobalPlayerContainerView<Content: View>: View {
    let content: Content
    @StateObject private var viewModel = SpeechPlayerViewModel()
    @EnvironmentObject var playerUIState: PlayerUIState
    @EnvironmentObject var appSettings: AppSettings

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if appSettings.enableTTS && viewModel.hasItems && playerUIState.isPlayerVisible {
                VStack(spacing: 0) {
                    SpeechPlayerView(viewModel: viewModel, onClose: { playerUIState.hidePlayer() })
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
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
```

Key changes:
- Added `.task { await viewModel.setup() }` to establish Combine bindings
- Pass `viewModel` into `SpeechPlayerView` instead of letting it create its own

- [ ] **Step 2: Change `SpeechPlayerView` to accept ViewModel from parent**

In `SpeechPlayerView.swift`, change from creating its own ViewModel to receiving one:

```swift
struct SpeechPlayerView: View {
    @ObservedObject var viewModel: SpeechPlayerViewModel
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    var onClose: (() -> Void)? = nil

    private let minHeight: CGFloat = 60
    private let maxHeight: CGFloat = UIScreen.main.bounds.height / 2

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                ExpandedPlayerView(viewModel: viewModel, isExpanded: $isExpanded, onClose: onClose)
            } else {
                CollapsedPlayerBar(viewModel: viewModel, isExpanded: $isExpanded)
            }
        }
        .frame(height: isExpanded ? maxHeight : minHeight)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 8, x: 0, y: -2)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        if value.translation.height < -50 && !isExpanded {
                            isExpanded = true
                        } else if value.translation.height > 50 && isExpanded {
                            isExpanded = false
                        }
                        dragOffset = 0
                    }
                }
        )
    }
}
```

Key changes:
- `@State private var viewModel` → `@ObservedObject var viewModel` (received from parent)
- Removed `.onAppear { Task { await viewModel.setup() } }` (parent handles setup)
- Added `viewModel` as init parameter

- [ ] **Step 3: Update the Preview**

```swift
#Preview {
    SpeechPlayerView(viewModel: SpeechPlayerViewModel())
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```
fix: resolve TTS player never appearing by fixing ViewModel setup
```

---

### Task 2: Fix hard-coded German language defaults

**Files:**
- Modify: `readeck/UI/Utils/TTSManager.swift:50`
- Modify: `readeck/UI/Utils/VoiceManager.swift:21,43,47`

- [ ] **Step 1: Remove `"de-DE"` default from `TTSManager.speak()`**

In `TTSManager.swift`, change the method signature at line 50:

```swift
// Before:
func speak(text: String, language: String = "de-DE", utteranceIndex: Int = 0, totalUtterances: Int = 1) {

// After:
func speak(text: String, language: String, utteranceIndex: Int = 0, totalUtterances: Int = 1) {
```

This forces all callers to explicitly pass a language — no silent German fallback.

- [ ] **Step 2: Remove `"de-DE"` defaults from `VoiceManager`**

In `VoiceManager.swift`, remove the default parameter from all three public methods:

```swift
// Line 21 — Before:
func getVoice(for language: String = "de-DE") -> AVSpeechSynthesisVoice {

// After:
func getVoice(for language: String) -> AVSpeechSynthesisVoice {
```

```swift
// Line 43 — Before:
func getAvailableVoices(for language: String = "de-DE") -> [AVSpeechSynthesisVoice] {

// After:
func getAvailableVoices(for language: String) -> [AVSpeechSynthesisVoice] {
```

```swift
// Line 47 — Before:
func getPreferredVoices(for language: String = "de-DE") -> [AVSpeechSynthesisVoice] {

// After:
func getPreferredVoices(for language: String) -> [AVSpeechSynthesisVoice] {
```

- [ ] **Step 3: Fix `selectedVoice` ignoring article language**

In `VoiceManager.swift`, change the `getVoice(for:)` method to only use `selectedVoice` when its language matches:

```swift
func getVoice(for language: String) -> AVSpeechSynthesisVoice {
    // Check cache first
    if let cachedVoice = cachedVoices[language] {
        return cachedVoice
    }

    // Only use selectedVoice if its language matches
    let langPrefix = String(language.prefix(2))
    if let selected = selectedVoice, selected.language.hasPrefix(langPrefix) {
        cachedVoices[language] = selected
        return selected
    }

    // Find best voice for this language
    let voice = findEnhancedVoice(for: language)
    cachedVoices[language] = voice
    return voice
}
```

- [ ] **Step 4: Build and verify no compile errors**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (no callers use the defaults — `SpeechQueue.processQueue()` already passes language explicitly)

- [ ] **Step 5: Commit**

```
fix: remove hard-coded German TTS defaults, respect article language
```

---

### Task 3: Replace polling with delegate-based queue advancement

This is the core fix. `SpeechQueue.waitForSpeechToFinish()` polls every 0.1s and has a race condition. Instead, `TTSManager` should notify `SpeechQueue` when an utterance finishes via a callback.

**Files:**
- Modify: `readeck/UI/Utils/TTSManager.swift`
- Modify: `readeck/UI/Utils/SpeechQueue.swift`

- [ ] **Step 1: Add `onUtteranceFinished` callback to `TTSManager`**

In `TTSManager.swift`, add a callback property and fire it from `didFinish`:

```swift
// Add after line 18 (after the @Published properties):
var onUtteranceFinished: (() -> Void)?
```

Update the `didFinish` delegate method (lines 123-129):

```swift
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    DispatchQueue.main.async {
        self.isSpeaking = false
        self.currentUtterance = ""
        self.currentUtteranceIndex += 1
        self.updateProgress()
        self.articleProgress = 1.0
        self.onUtteranceFinished?()
    }
}
```

Also wrap the `didCancel` delegate in `DispatchQueue.main.async` for consistency:

```swift
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    DispatchQueue.main.async {
        self.isSpeaking = false
        self.currentUtterance = ""
        self.articleProgress = 0.0
    }
}
```

- [ ] **Step 2: Rewrite `SpeechQueue` to use callback instead of polling**

In `SpeechQueue.swift`, make these changes:

**In `init`** — register the callback:

```swift
private init(ttsManager: TTSManager = .shared) {
    self.ttsManager = ttsManager
    loadQueue()
    updatePublishedProperties()

    ttsManager.onUtteranceFinished = { [weak self] in
        self?.onCurrentItemFinished()
    }
}
```

**Delete** the entire `waitForSpeechToFinish()` method (lines 142-157).

**Add** the new callback handler:

```swift
private func onCurrentItemFinished() {
    guard isProcessing else { return }
    if !queue.isEmpty {
        queue.removeFirst()
    }
    isProcessing = false
    updatePublishedProperties()
    saveQueue()
    processQueue()
}
```

**Remove** the polling dispatch from `processQueue()`. Change lines 127-140 to:

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
    ttsManager.speak(text: textToSpeak, language: languageCode, utteranceIndex: currentIndex, totalUtterances: queueItems.count)
}
```

The key difference: no more `DispatchQueue.main.asyncAfter` + `waitForSpeechToFinish()`. The queue now advances only when `TTSManager` fires `onUtteranceFinished`.

- [ ] **Step 3: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```
fix: replace TTS polling loop with delegate-based queue advancement
```

---

### Task 4: Fix thread safety and audio session issues

**Files:**
- Modify: `readeck/UI/Utils/TTSManager.swift`
- Modify: `readeck/UI/Utils/SpeechQueue.swift`

- [ ] **Step 1: Fix duplicate audio session configuration**

In `TTSManager.swift`, `configureAudioSession()` calls `setCategory` twice (lines 30 and 32) with identical parameters. Remove the duplicate:

```swift
private func configureAudioSession() {
    do {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers, .allowBluetooth, .allowBluetoothA2DP])
        try audioSession.setActive(true)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    } catch {
        print("Fehler beim Konfigurieren der Audio-Session: \(error)")
    }
}
```

- [ ] **Step 2: Ensure `speak()` state updates happen before synthesis starts**

In `TTSManager.swift`, the current `speak()` method updates state async on main queue (lines 52-59) but then immediately calls `synthesizer.speak()` (line 68). On iOS 26, if the synthesizer fires `willSpeakRange` before the main queue dispatch executes, `articleProgress` resets after speech starts.

Fix by making state updates synchronous when already on main thread:

```swift
func speak(text: String, language: String, utteranceIndex: Int = 0, totalUtterances: Int = 1) {
    guard !text.isEmpty else { return }

    if synthesizer.isSpeaking {
        synthesizer.stopSpeaking(at: .immediate)
    }

    self.isSpeaking = true
    self.currentUtterance = text
    self.currentUtteranceIndex = utteranceIndex
    self.totalUtterances = totalUtterances
    self.updateProgress()
    self.articleProgress = 0.0

    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = voiceManager.getVoice(for: language)
    utterance.rate = rate
    utterance.pitchMultiplier = 1.0
    utterance.volume = volume
    synthesizer.speak(utterance)
}
```

Note: `speak()` is always called from `SpeechQueue.processQueue()` which runs on main thread (it's called from `enqueue` which is called from UI actions, and from `onCurrentItemFinished` which is dispatched to main in `didFinish`). Moving `stopSpeaking` before state updates also eliminates the race where the polling could see `isCurrentlySpeaking() == false` between stop and speak — though with Task 3 done, this is defense-in-depth.

- [ ] **Step 3: Add `@MainActor` to `SpeechQueue` for thread safety**

In `SpeechQueue.swift`, mark the class `@MainActor` to guarantee all queue mutations happen on the main thread:

```swift
@MainActor
class SpeechQueue: ObservableObject {
```

This makes `isProcessing` and `queue` mutations thread-safe without locks. All callers already call from the main thread (UI actions, delegate callbacks dispatched to main).

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```
fix: thread safety and audio session cleanup for TTS
```

---

### Task 5: Fix `stop()` not clearing queue state properly

**Files:**
- Modify: `readeck/UI/Utils/TTSManager.swift`
- Modify: `readeck/UI/Utils/SpeechQueue.swift`
- Modify: `readeck/UI/SpeechPlayer/SpeechPlayerViewModel.swift`

Currently `SpeechPlayerViewModel.stop()` calls `ttsManager?.stop()` which stops playback but leaves the queue intact. When `didCancel` fires (from `stopSpeaking`), the callback doesn't advance the queue — but `isProcessing` stays `true`, so the queue is stuck.

- [ ] **Step 1: Add `onUtteranceCancelled` callback to `TTSManager`**

In `TTSManager.swift`, add another callback:

```swift
var onUtteranceCancelled: (() -> Void)?
```

Fire it from the `didCancel` delegate:

```swift
func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    DispatchQueue.main.async {
        self.isSpeaking = false
        self.currentUtterance = ""
        self.articleProgress = 0.0
        self.onUtteranceCancelled?()
    }
}
```

- [ ] **Step 2: Handle cancel in `SpeechQueue`**

In `SpeechQueue.swift`, register the cancel callback in `init`:

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
}
```

Add the cancel handler:

```swift
private func onCurrentItemCancelled() {
    isProcessing = false
    updatePublishedProperties()
}
```

This resets `isProcessing` so the queue isn't stuck, but doesn't remove the item (it wasn't finished, just stopped).

- [ ] **Step 3: Wire up `SpeechPlayerViewModel.stop()` to clear the queue**

In `SpeechPlayerViewModel.swift`, change `stop()` to clear the entire queue, since stop means "stop everything":

```swift
func stop() {
    speechQueue?.clear()
}
```

`SpeechQueue.clear()` already calls `ttsManager.stop()` internally and clears the queue.

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```
fix: stop button clears TTS queue, cancel callback prevents stuck state
```

---

### Task 6: Use `.tabViewBottomAccessory` on iOS 26 for native player placement

On iOS 26, the TTS player should use the native `.tabViewBottomAccessory` modifier on `TabView` instead of the ZStack overlay. This integrates with Liquid Glass and the tab bar minimize behavior already enabled in the app. On iOS 18, the existing `GlobalPlayerContainerView` ZStack approach is kept as fallback.

**Files:**
- Modify: `readeck/UI/Menu/PhoneTabView.swift`
- Modify: `readeck/UI/SpeechPlayer/GlobalPlayerContainerView.swift`

- [ ] **Step 1: Add `.tabViewBottomAccessory` to `PhoneTabView` for iOS 26**

In `PhoneTabView.swift`, restructure the body to conditionally use the native bottom accessory on iOS 26:

```swift
var body: some View {
    if #available(iOS 26, *) {
        tabViewContent
            .tabViewBottomAccessory {
                if appSettings.enableTTS && speechPlayerViewModel.hasItems && playerUIState.isPlayerVisible {
                    SpeechPlayerView(viewModel: speechPlayerViewModel, onClose: { playerUIState.hidePlayer() })
                }
            }
    } else {
        GlobalPlayerContainerView {
            tabViewContent
        }
    }
}
```

This requires extracting the TabView into a computed property. Add the ViewModel and extract:

```swift
struct PhoneTabView: View {
    private let mainTabs: [SidebarTab] = [.all, .unread, .favorite, .archived]
    private let moreTabs: [SidebarTab] = [.article, .videos, .pictures, .tags, .settings]

    @State private var selectedTab: SidebarTab = .unread
    @State private var offlineBookmarksViewModel = OfflineBookmarksViewModel()
    @StateObject private var speechPlayerViewModel = SpeechPlayerViewModel()

    // Navigation paths for each tab
    @State private var allPath = NavigationPath()
    @State private var unreadPath = NavigationPath()
    @State private var favoritePath = NavigationPath()
    @State private var archivedPath = NavigationPath()
    @State private var morePath = NavigationPath()

    // Search functionality
    @State private var searchViewModel = SearchBookmarksViewModel()
    @FocusState private var searchFieldIsFocused: Bool

    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var playerUIState: PlayerUIState

    private var cardLayoutStyle: CardLayoutStyle {
        appSettings.settings?.cardLayoutStyle ?? .compact
    }

    private var offlineBookmarksBadgeCount: Int {
        offlineBookmarksViewModel.state.localBookmarkCount > 0 ? offlineBookmarksViewModel.state.localBookmarkCount : 0
    }

    var body: some View {
        if #available(iOS 26, *) {
            tabViewContent
                .tabViewBottomAccessory {
                    if appSettings.enableTTS && speechPlayerViewModel.hasItems && playerUIState.isPlayerVisible {
                        SpeechPlayerView(viewModel: speechPlayerViewModel, onClose: { playerUIState.hidePlayer() })
                    }
                }
                .task {
                    await speechPlayerViewModel.setup()
                }
        } else {
            GlobalPlayerContainerView {
                tabViewContent
            }
        }
    }

    @ViewBuilder
    private var tabViewContent: some View {
        TabView(selection: $selectedTab) {
            // ... all existing Tab declarations unchanged ...
        }
        .tabBarMinimizeBehaviorIfAvailable()
        .accentColor(.accentColor)
        .searchToolbarBehaviorIfAvailable()
    }

    // ... rest of existing computed properties and methods unchanged ...
}
```

Key changes:
- Added `@StateObject private var speechPlayerViewModel = SpeechPlayerViewModel()`
- Added `@EnvironmentObject var playerUIState: PlayerUIState` (was missing, already injected by MainTabView)
- Extracted `TabView` into `tabViewContent` computed property
- iOS 26: Use `.tabViewBottomAccessory` directly on TabView with `.task` for setup
- iOS 18: Keep `GlobalPlayerContainerView` wrapper as before

- [ ] **Step 2: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```
feat: use native tabViewBottomAccessory for TTS player on iOS 26
```

---

### Task 7: Prefer highest quality voice (premium > enhanced > default)

The current `VoiceManager.findEnhancedVoice()` selects voices by **name** (Anna, Helena, Siri...), which is fragile and doesn't use the actual quality metadata. `AVSpeechSynthesisVoice` has a `.quality` property with three levels: `.premium`, `.enhanced`, `.default`. Premium and enhanced voices must be downloaded by the user (Settings > Accessibility > Spoken Content > Voices), but the app already links to that page in `TTSLanguageSettingsView`. The VoiceManager just doesn't prioritize them.

**Files:**
- Modify: `readeck/UI/Utils/VoiceManager.swift`

- [ ] **Step 1: Rewrite `findEnhancedVoice(for:)` to sort by quality**

Replace the current name-based lookup with quality-based selection:

```swift
private func findEnhancedVoice(for language: String) -> AVSpeechSynthesisVoice {
    let voicesForLanguage = availableVoices.filter { $0.language == language }

    // Prefer highest quality available: premium > enhanced > default
    if let premium = voicesForLanguage.first(where: { $0.quality == .premium }) {
        return premium
    }
    if let enhanced = voicesForLanguage.first(where: { $0.quality == .enhanced }) {
        return enhanced
    }
    if let defaultVoice = voicesForLanguage.first {
        return defaultVoice
    }

    // Ultimate fallback
    return AVSpeechSynthesisVoice(language: language) ?? AVSpeechSynthesisVoice()
}
```

- [ ] **Step 2: Remove the hard-coded preferred voice names**

Delete the `getPreferredVoices(for:)` method entirely — it's no longer called by `findEnhancedVoice` and was only used there. The name list ("Anna", "Helena", "Siri", "Karen", "Daniel"...) is fragile and unnecessary when we have quality metadata.

If `getPreferredVoices` is used elsewhere (check first), keep it but it's no longer part of the voice selection path.

- [ ] **Step 3: Clear voice cache when user changes voices in Settings**

Add a method to invalidate the cache so newly downloaded voices are picked up:

```swift
func refreshVoices() {
    cachedVoices.removeAll()
    loadAvailableVoices()
}
```

Call this in `TTSLanguageSettingsView` when the user returns from iOS Settings. In `TTSLanguageSettingsView.swift`, add `.onAppear` to the view body:

```swift
var body: some View {
    List {
        // ... existing sections ...
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Language & Voices")
    .onAppear {
        VoiceManager.shared.refreshVoices()
    }
}
```

This ensures that if the user downloads a premium voice in iOS Settings and comes back, the app picks it up immediately.

- [ ] **Step 4: Build and verify**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```
feat: prefer premium/enhanced TTS voices over default quality
```

---

## Summary of Changes

| Bug / Enhancement | Root Cause | Fix |
|-------------------|-----------|-----|
| Player never appears | `GlobalPlayerContainerView` ViewModel never calls `setup()` | Add `.task { await viewModel.setup() }`, single ViewModel |
| Always reads German | Hard-coded `"de-DE"` defaults, selectedVoice ignores language | Remove defaults, check language prefix |
| Queue replays first article | Polling race condition in `waitForSpeechToFinish` | Delegate-based `onUtteranceFinished` callback |
| Queue gets stuck after stop | `isProcessing` stays true after cancel | `onUtteranceCancelled` callback resets state |
| Thread safety | No synchronization on `isProcessing` / `queue` | `@MainActor` on `SpeechQueue` |
| iOS 26 timing issues | Async state update before sync `synthesizer.speak()` | Synchronous state updates in `speak()` |
| Player floats over tab bar | Custom ZStack overlay doesn't integrate with tab bar | `.tabViewBottomAccessory` on iOS 26 |
| Low voice quality | Name-based voice selection ignores quality metadata | Sort by `.premium` > `.enhanced` > `.default`, refresh cache on return from Settings |
