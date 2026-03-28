# Swipe Action Customization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users configure which actions appear on left/right swipe in the bookmark list view.

**Architecture:** New `SwipeAction` enum and `SwipeActionConfig` struct stored in Settings via CoreData. `BookmarkCardView` renders swipe actions dynamically from config. New Settings UI section for configuration.

**Tech Stack:** SwiftUI, CoreData, existing Settings/Repository architecture

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `readeck/Domain/Model/SwipeAction.swift` | Create | SwipeAction enum + SwipeActionConfig struct |
| `readeck/Domain/Model/Settings.swift` | Modify | Add swipeActionConfig property |
| `readeck/UI/Models/AppSettings.swift` | Modify | Add swipeActionConfig computed property |
| `readeck/Data/Repository/SettingsRepository.swift` | Modify | Save/load swipe config as JSON string in CoreData |
| `readeck/Domain/Protocols/PSettingsRepository.swift` | Modify | Add save/load swipeActionConfig methods |
| `readeck/Domain/UseCase/Settings/SaveSettingsUseCase.swift` | Modify | Add execute(swipeActionConfig:) method |
| `readeck/readeck.xcdatamodeld/readeck.xcdatamodel/contents` | Modify | Add swipeActionConfig String attribute to SettingEntity |
| `readeck/UI/Bookmarks/BookmarkCardView.swift` | Modify | Dynamic swipe actions from config, unified callback |
| `readeck/UI/Bookmarks/BookmarksView.swift` | Modify | Pass config and unified callback |
| `readeck/UI/Bookmarks/BookmarksViewModel.swift` | Modify | Handle unified onSwipeAction callback |
| `readeck/UI/Settings/SwipeActionsSettingsView.swift` | Create | Settings UI for configuring swipe actions |
| `readeck/UI/Settings/SettingsContainerView.swift` | Modify | Add SwipeActionsSettingsView section |

---

### Task 1: SwipeAction Enum and SwipeActionConfig Model

**Files:**
- Create: `readeck/Domain/Model/SwipeAction.swift`

- [ ] **Step 1: Create SwipeAction enum and SwipeActionConfig struct**

```swift
// readeck/Domain/Model/SwipeAction.swift

import Foundation

enum SwipeAction: String, Codable, CaseIterable, Identifiable {
    case archive
    case favorite
    case delete
    case showTags
    case openInBrowser

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .archive: return "Archive"
        case .favorite: return "Favorite"
        case .delete: return "Delete"
        case .showTags: return "Tags"
        case .openInBrowser: return "Open in Browser"
        }
    }

    var iconName: String {
        switch self {
        case .archive: return "archivebox"
        case .favorite: return "heart.fill"
        case .delete: return "trash"
        case .showTags: return "tag"
        case .openInBrowser: return "safari"
        }
    }
}

struct SwipeActionConfig: Codable, Equatable {
    var leadingActions: [SwipeAction]
    var trailingActions: [SwipeAction]

    static let `default` = SwipeActionConfig(
        leadingActions: [.archive, .favorite],
        trailingActions: [.delete]
    )

    /// All actions currently assigned to either side
    var assignedActions: Set<SwipeAction> {
        Set(leadingActions + trailingActions)
    }

    /// Actions not yet assigned to any side
    var availableActions: [SwipeAction] {
        SwipeAction.allCases.filter { !assignedActions.contains($0) }
    }

    static let maxActionsPerSide = 3
}
```

- [ ] **Step 2: Verify it compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add readeck/Domain/Model/SwipeAction.swift
git commit -m "Add SwipeAction enum and SwipeActionConfig model"
```

---

### Task 2: Integrate SwipeActionConfig into Settings Persistence

**Files:**
- Modify: `readeck/Domain/Model/Settings.swift`
- Modify: `readeck/UI/Models/AppSettings.swift`
- Modify: `readeck/readeck.xcdatamodeld/readeck.xcdatamodel/contents`
- Modify: `readeck/Data/Repository/SettingsRepository.swift`
- Modify: `readeck/Domain/Protocols/PSettingsRepository.swift`
- Modify: `readeck/Domain/UseCase/Settings/SaveSettingsUseCase.swift`

- [ ] **Step 1: Add swipeActionConfig to Settings struct**

In `readeck/Domain/Model/Settings.swift`, add after the `urlOpener` property:

```swift
var swipeActionConfig: SwipeActionConfig? = nil
```

- [ ] **Step 2: Add computed property to AppSettings**

In `readeck/UI/Models/AppSettings.swift`, add after the `bookmarkSortDirection` computed property:

```swift
var swipeActionConfig: SwipeActionConfig {
    settings?.swipeActionConfig ?? .default
}
```

- [ ] **Step 3: Add swipeActionConfig attribute to CoreData model**

In `readeck/readeck.xcdatamodeld/readeck.xcdatamodel/contents`, add to the SettingEntity:

```xml
<attribute name="swipeActionConfig" optional="YES" attributeType="String"/>
```

This stores the SwipeActionConfig as a JSON-encoded string, same pattern as other string-stored settings.

- [ ] **Step 4: Update SettingsRepository.saveSettings to persist swipeActionConfig**

In `readeck/Data/Repository/SettingsRepository.swift`, inside `saveSettings(_:)`, add after the `bookmarkSortDirection` block (around line 84):

```swift
if let swipeActionConfig = settings.swipeActionConfig {
    let encoder = JSONEncoder()
    if let jsonData = try? encoder.encode(swipeActionConfig),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        existingSettings.swipeActionConfig = jsonString
    }
}
```

- [ ] **Step 5: Update SettingsRepository.loadSettings to load swipeActionConfig**

In `readeck/Data/Repository/SettingsRepository.swift`, inside `loadSettings()`, add `swipeActionConfig` to the Settings initializer. Decode the JSON string:

Before the `let settings = Settings(` line, add:

```swift
var swipeActionConfig: SwipeActionConfig? = nil
if let jsonString = settingEntity?.swipeActionConfig,
   let jsonData = jsonString.data(using: .utf8) {
    swipeActionConfig = try? JSONDecoder().decode(SwipeActionConfig.self, from: jsonData)
}
```

Then add `swipeActionConfig: swipeActionConfig` to the Settings initializer call.

- [ ] **Step 6: Add execute(swipeActionConfig:) to SaveSettingsUseCase**

In `readeck/Domain/UseCase/Settings/SaveSettingsUseCase.swift`:

Add to protocol `PSaveSettingsUseCase`:
```swift
func execute(swipeActionConfig: SwipeActionConfig) async throws
```

Add to class `SaveSettingsUseCase`:
```swift
func execute(swipeActionConfig: SwipeActionConfig) async throws {
    try await settingsRepository.saveSettings(
        .init(swipeActionConfig: swipeActionConfig)
    )
}
```

- [ ] **Step 7: Verify it compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 8: Commit**

```bash
git add readeck/Domain/Model/Settings.swift readeck/UI/Models/AppSettings.swift readeck/Data/Repository/SettingsRepository.swift readeck/Domain/Protocols/PSettingsRepository.swift readeck/Domain/UseCase/Settings/SaveSettingsUseCase.swift readeck/readeck.xcdatamodeld/readeck.xcdatamodel/contents
git commit -m "Integrate SwipeActionConfig into settings persistence layer"
```

---

### Task 3: Refactor BookmarkCardView to Dynamic Swipe Actions

**Files:**
- Modify: `readeck/UI/Bookmarks/BookmarkCardView.swift`
- Modify: `readeck/UI/Bookmarks/BookmarksViewModel.swift`
- Modify: `readeck/UI/Bookmarks/BookmarksView.swift`

- [ ] **Step 1: Replace individual callbacks with unified onSwipeAction in BookmarkCardView**

In `readeck/UI/Bookmarks/BookmarkCardView.swift`, replace the callback properties and init:

Replace:
```swift
let onArchive: (Bookmark) -> Void
let onDelete: (Bookmark) -> Void
let onToggleFavorite: (Bookmark) -> Void
let onUndoDelete: ((String) -> Void)?
```

With:
```swift
let swipeActionConfig: SwipeActionConfig
let onSwipeAction: (SwipeAction, Bookmark) -> Void
let onUndoDelete: ((String) -> Void)?
```

Update the init accordingly:
```swift
init(
    bookmark: Bookmark,
    currentState: BookmarkState,
    layout: CardLayoutStyle = .magazine,
    pendingDelete: PendingDelete? = nil,
    swipeActionConfig: SwipeActionConfig = .default,
    onSwipeAction: @escaping (SwipeAction, Bookmark) -> Void,
    onUndoDelete: ((String) -> Void)? = nil
) {
    self.bookmark = bookmark
    self.currentState = currentState
    self.layout = layout
    self.pendingDelete = pendingDelete
    self.swipeActionConfig = swipeActionConfig
    self.onSwipeAction = onSwipeAction
    self.onUndoDelete = onUndoDelete
}
```

- [ ] **Step 2: Replace hardcoded swipeActions with dynamic rendering**

Replace the two `.swipeActions` blocks (lines 113-142) with:

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: !swipeActionConfig.trailingActions.isEmpty) {
    if pendingDelete == nil {
        ForEach(Array(swipeActionConfig.trailingActions.enumerated()), id: \.element) { index, action in
            swipeButton(for: action)
        }
    }
}
.swipeActions(edge: .leading, allowsFullSwipe: !swipeActionConfig.leadingActions.isEmpty) {
    if pendingDelete == nil {
        ForEach(Array(swipeActionConfig.leadingActions.enumerated()), id: \.element) { index, action in
            swipeButton(for: action)
        }
    }
}
```

- [ ] **Step 3: Add swipeButton helper method**

Add this method to `BookmarkCardView`:

```swift
@ViewBuilder
private func swipeButton(for action: SwipeAction) -> some View {
    switch action {
    case .archive:
        Button {
            onSwipeAction(.archive, bookmark)
        } label: {
            if currentState == .archived {
                Label("Restore", systemImage: "tray.and.arrow.up")
            } else {
                Label("Archive", systemImage: "archivebox")
            }
        }
        .tint(currentState == .archived ? .blue : .orange)

    case .favorite:
        Button {
            onSwipeAction(.favorite, bookmark)
        } label: {
            if bookmark.isMarked {
                Image(systemName: "heart.slash")
            } else {
                Image(systemName: "heart.fill")
            }
        }
        .tint(bookmark.isMarked ? .gray : .pink)

    case .delete:
        Button(role: .destructive) {
            onSwipeAction(.delete, bookmark)
        } label: {
            Label("Delete", systemImage: "trash")
        }
        .tint(.red)

    case .showTags:
        Button {
            onSwipeAction(.showTags, bookmark)
        } label: {
            Label("Tags", systemImage: "tag")
        }
        .tint(.teal)

    case .openInBrowser:
        Button {
            onSwipeAction(.openInBrowser, bookmark)
        } label: {
            Label("Open", systemImage: "safari")
        }
        .tint(.blue)
    }
}
```

- [ ] **Step 4: Add handleSwipeAction to BookmarksViewModel**

In `readeck/UI/Bookmarks/BookmarksViewModel.swift`, add this method:

```swift
@MainActor
func handleSwipeAction(_ action: SwipeAction, bookmark: Bookmark) {
    switch action {
    case .archive:
        Task { await toggleArchive(bookmark: bookmark) }
    case .favorite:
        Task { await toggleFavorite(bookmark: bookmark) }
    case .delete:
        deleteBookmarkWithUndo(bookmark: bookmark)
    case .showTags:
        showTagsBookmark = bookmark
    case .openInBrowser:
        if let url = URL(string: bookmark.url) {
            URLUtil.open(url: bookmark.url, urlOpener: appSettings.urlOpener)
        }
    }
}
```

Also add the property for showing tags sheet near the other published properties:

```swift
var showTagsBookmark: Bookmark? = nil
```

Note: The ViewModel will need access to `appSettings` for `openInBrowser`. Check if it already has a reference; if not, add it as an init parameter.

- [ ] **Step 5: Update BookmarksView to use unified callback**

In `readeck/UI/Bookmarks/BookmarksView.swift`, replace the BookmarkCardView instantiation (lines 275-296):

```swift
BookmarkCardView(
    bookmark: bookmark,
    currentState: state,
    layout: viewModel.cardLayoutStyle,
    pendingDelete: viewModel.pendingDeletes[bookmark.id],
    swipeActionConfig: appSettings.swipeActionConfig,
    onSwipeAction: { action, bookmark in
        viewModel.handleSwipeAction(action, bookmark: bookmark)
    },
    onUndoDelete: { bookmarkId in
        viewModel.undoDelete(bookmarkId: bookmarkId)
    }
)
```

Also add a `.sheet` modifier for the tags sheet somewhere in BookmarksView:

```swift
.sheet(item: $viewModel.showTagsBookmark) { bookmark in
    // Reuse existing tag display — check what the detail view uses
    NavigationStack {
        TagSelectionView(bookmark: bookmark)
    }
}
```

Note: Check what tag view component exists in the detail view and reuse it. If `TagSelectionView` doesn't exist with that exact name, find the correct view name from the codebase.

- [ ] **Step 6: Verify it compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add readeck/UI/Bookmarks/BookmarkCardView.swift readeck/UI/Bookmarks/BookmarksViewModel.swift readeck/UI/Bookmarks/BookmarksView.swift
git commit -m "Refactor BookmarkCardView to dynamic swipe actions with unified callback"
```

---

### Task 4: Settings UI for Swipe Action Configuration

**Files:**
- Create: `readeck/UI/Settings/SwipeActionsSettingsView.swift`
- Modify: `readeck/UI/Settings/SettingsContainerView.swift`

- [ ] **Step 1: Create SwipeActionsSettingsView**

```swift
// readeck/UI/Settings/SwipeActionsSettingsView.swift

import SwiftUI

struct SwipeActionsSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var config: SwipeActionConfig = .default
    @State private var isLoaded = false

    private let saveSettingsUseCase: PSaveSettingsUseCase

    init(saveSettingsUseCase: PSaveSettingsUseCase = DefaultUseCaseFactory.shared.makeSaveSettingsUseCase()) {
        self.saveSettingsUseCase = saveSettingsUseCase
    }

    var body: some View {
        Section {
            NavigationLink {
                SwipeActionsDetailView(
                    config: $config,
                    onSave: saveConfig
                )
            } label: {
                SettingsRowNavigationLink(
                    icon: "hand.draw.fill",
                    iconColor: .purple,
                    title: "Swipe Actions",
                    subtitle: swipeSummary
                )
            }
        } header: {
            Text("Gestures")
        }
        .onAppear {
            if !isLoaded {
                config = appSettings.swipeActionConfig
                isLoaded = true
            }
        }
    }

    private var swipeSummary: String {
        let left = config.leadingActions.count
        let right = config.trailingActions.count
        return "\(left) left, \(right) right"
    }

    private func saveConfig() {
        Task {
            try? await saveSettingsUseCase.execute(swipeActionConfig: config)
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
}

struct SwipeActionsDetailView: View {
    @Binding var config: SwipeActionConfig
    let onSave: () -> Void
    @State private var showAddLeading = false
    @State private var showAddTrailing = false

    var body: some View {
        List {
            // Leading (Left Swipe) Section
            Section {
                ForEach(config.leadingActions) { action in
                    HStack {
                        Image(systemName: action.iconName)
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        Text(action.displayName)
                    }
                }
                .onDelete { indexSet in
                    config.leadingActions.remove(atOffsets: indexSet)
                    onSave()
                }
                .onMove { from, to in
                    config.leadingActions.move(fromOffsets: from, toOffset: to)
                    onSave()
                }

                if config.leadingActions.count < SwipeActionConfig.maxActionsPerSide,
                   !config.availableActions.isEmpty {
                    Button {
                        showAddLeading = true
                    } label: {
                        Label("Add Action", systemImage: "plus.circle")
                    }
                }
            } header: {
                Text("Left Swipe")
            }

            // Trailing (Right Swipe) Section
            Section {
                ForEach(config.trailingActions) { action in
                    HStack {
                        Image(systemName: action.iconName)
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        Text(action.displayName)
                    }
                }
                .onDelete { indexSet in
                    config.trailingActions.remove(atOffsets: indexSet)
                    onSave()
                }
                .onMove { from, to in
                    config.trailingActions.move(fromOffsets: from, toOffset: to)
                    onSave()
                }

                if config.trailingActions.count < SwipeActionConfig.maxActionsPerSide,
                   !config.availableActions.isEmpty {
                    Button {
                        showAddTrailing = true
                    } label: {
                        Label("Add Action", systemImage: "plus.circle")
                    }
                }
            } header: {
                Text("Right Swipe")
            }

            // Reset Section
            Section {
                Button("Reset to Default") {
                    config = .default
                    onSave()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Swipe Actions")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .sheet(isPresented: $showAddLeading) {
            addActionSheet(for: .leading)
        }
        .sheet(isPresented: $showAddTrailing) {
            addActionSheet(for: .trailing)
        }
    }

    enum Side {
        case leading, trailing
    }

    @ViewBuilder
    private func addActionSheet(for side: Side) -> some View {
        NavigationStack {
            List {
                ForEach(config.availableActions) { action in
                    Button {
                        switch side {
                        case .leading:
                            config.leadingActions.append(action)
                        case .trailing:
                            config.trailingActions.append(action)
                        }
                        onSave()
                        showAddLeading = false
                        showAddTrailing = false
                    } label: {
                        HStack {
                            Image(systemName: action.iconName)
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            Text(action.displayName)
                        }
                    }
                }
            }
            .navigationTitle("Add Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddLeading = false
                        showAddTrailing = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
```

- [ ] **Step 2: Add SwipeActionsSettingsView to SettingsContainerView**

In `readeck/UI/Settings/SettingsContainerView.swift`, add after the `ReadingSettingsView()` line (line 83):

```swift
SwipeActionsSettingsView()
```

- [ ] **Step 3: Verify it compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add readeck/UI/Settings/SwipeActionsSettingsView.swift readeck/UI/Settings/SettingsContainerView.swift
git commit -m "Add swipe actions settings UI with drag-and-drop reordering"
```

---

### Task 5: Wire Up Tags Sheet and Browser Opening

**Files:**
- Modify: `readeck/UI/Bookmarks/BookmarksViewModel.swift`
- Modify: `readeck/UI/Bookmarks/BookmarksView.swift`

This task ensures the two new actions (showTags, openInBrowser) work end-to-end. The exact implementation depends on what tag views and URL opening utilities exist in the codebase.

- [ ] **Step 1: Verify existing tag and URL utilities**

Search the codebase for:
- Tag selection/display views used in the bookmark detail view
- `URLUtil.open` method signature
- How `appSettings` is accessed in the ViewModel (via EnvironmentObject or init parameter)

Adapt the `handleSwipeAction` method from Task 3 based on what you find. The key points:
- `showTags`: Set a published property that triggers a `.sheet` in BookmarksView showing the bookmark's tags
- `openInBrowser`: Call the existing URL opening utility with the bookmark's URL

- [ ] **Step 2: Test all five actions manually**

1. Build and run in simulator
2. Test default config: right swipe should show Delete, left swipe should show Archive + heart icon
3. Go to Settings > Swipe Actions
4. Add "Tags" to left swipe, verify it appears
5. Add "Open in Browser" to right swipe, verify it appears
6. Swipe on a bookmark, verify each action works:
   - Archive toggles the bookmark state
   - Heart icon toggles favorite
   - Delete shows undo toast
   - Tags opens tag sheet
   - Open in Browser opens the URL
7. Remove an action, verify it disappears from swipe
8. Reorder actions, verify order changes
9. Reset to default, verify original layout restores

- [ ] **Step 3: Commit**

```bash
git add readeck/UI/Bookmarks/BookmarksViewModel.swift readeck/UI/Bookmarks/BookmarksView.swift
git commit -m "Wire up tags sheet and browser opening for swipe actions"
```

---

### Task 6: Handle Edge Cases and Polish

**Files:**
- Modify: `readeck/UI/Bookmarks/BookmarkCardView.swift`
- Modify: `readeck/UI/Settings/SwipeActionsSettingsView.swift`

- [ ] **Step 1: Handle archive label in archived context**

In the `swipeButton` method for `.archive`, the label should show "Restore" with `tray.and.arrow.up` when the bookmark is already archived, and "Archive" with `archivebox` otherwise. This is already handled in Task 3's implementation. Verify it works in the Archived tab.

- [ ] **Step 2: Handle empty swipe config**

If a user removes all actions from both sides, swipes should simply do nothing. Verify that `.swipeActions` with an empty array renders correctly (no crash, no visual artifacts).

- [ ] **Step 3: Verify favorite shows only heart icon, no text**

The `.favorite` case in `swipeButton` should render only `Image(systemName:)` without a `Label`. Verify the heart icon appears without accompanying text in the swipe action.

- [ ] **Step 4: Test and commit**

Run the app, verify all edge cases, then:

```bash
git add -A
git commit -m "Handle edge cases for swipe action customization"
```

---

### Task 7: Update MockUseCaseFactory for Tests/Previews

**Files:**
- Modify: `readeck/UI/Factory/MockUseCaseFactory.swift`

- [ ] **Step 1: Add swipeActionConfig method to mock**

The `MockSaveSettingsUseCase` (or equivalent) needs to conform to the updated `PSaveSettingsUseCase` protocol. Add the new method:

```swift
func execute(swipeActionConfig: SwipeActionConfig) async throws {
    // no-op for mock
}
```

- [ ] **Step 2: Verify it compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add readeck/UI/Factory/MockUseCaseFactory.swift
git commit -m "Update MockUseCaseFactory for swipe action config"
```
