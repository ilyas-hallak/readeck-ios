# Collapsible Toolbar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hide the navigation bar toolbar when scrolling down in the article reader and show it again after a meaningful scroll-up distance, eliminating button/text overlap (issue #31).

**Architecture:** Add scroll direction tracking to `BookmarkDetailView2` using the existing `ScrollOffsetPreferenceKey` + `GeometryReader`. A handful of `@State` properties track previous offset, accumulated scroll-up distance, and toolbar visibility. The `.toolbar` modifier toggles visibility with an animated slide.

**Tech Stack:** SwiftUI, iOS 26+

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `readeck/UI/BookmarkDetail/BookmarkDetailView2.swift` | Add scroll tracking state, offset change handler, toolbar visibility toggle |

This is a single-file change. All logic lives in `BookmarkDetailView2` — no new files needed.

---

### Task 1: Add scroll tracking state properties

**Files:**
- Modify: `readeck/UI/BookmarkDetail/BookmarkDetailView2.swift:10-23`

- [ ] **Step 1: Add state properties for scroll tracking**

Add these properties after the existing `@State` declarations (after line 23):

```swift
@State private var isToolbarVisible: Bool = true
@State private var previousScrollOffset: CGFloat = 0
@State private var accumulatedScrollUp: CGFloat = 0
```

- [ ] **Step 2: Add threshold constant**

Add this constant after the existing `headerHeight` constant (after line 31):

```swift
private let scrollUpThresholdRatio: CGFloat = 0.12
```

- [ ] **Step 3: Verify build**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 2: Wire up scroll offset tracking to detect direction

**Files:**
- Modify: `readeck/UI/BookmarkDetail/BookmarkDetailView2.swift:248-250`

- [ ] **Step 1: Replace the empty `onPreferenceChange(ScrollOffsetPreferenceKey.self)` handler**

Replace the current no-op handler at line 248-250:

```swift
.onPreferenceChange(ScrollOffsetPreferenceKey.self) { _ in
    // Not needed anymore, we track via ContentHeightPreferenceKey
}
```

With the scroll direction tracking logic:

```swift
.onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
    let currentOffset = offset.y
    let delta = currentOffset - previousScrollOffset

    defer { previousScrollOffset = currentOffset }

    // Always show toolbar at top of content
    if currentOffset >= 0 {
        if !isToolbarVisible {
            isToolbarVisible = true
        }
        accumulatedScrollUp = 0
        return
    }

    let screenHeight = geometry.size.height
    guard screenHeight > 0 else { return }

    if delta < 0 {
        // Scrolling down — hide toolbar
        accumulatedScrollUp = 0
        if isToolbarVisible {
            isToolbarVisible = false
        }
    } else if delta > 0 {
        // Scrolling up — accumulate distance
        accumulatedScrollUp += delta
        let threshold = screenHeight * scrollUpThresholdRatio
        if accumulatedScrollUp >= threshold && !isToolbarVisible {
            isToolbarVisible = true
        }
    }
}
```

- [ ] **Step 2: Verify build**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 3: Apply toolbar visibility modifier

**Files:**
- Modify: `readeck/UI/BookmarkDetail/BookmarkDetailView2.swift:44-48`

- [ ] **Step 1: Add toolbar visibility and animation modifiers**

In `mainView`, add the toolbar visibility modifier after the `.toolbar { toolbarContent }` line (after line 48). The result should look like:

```swift
private var mainView: some View {
    content
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .toolbar(isToolbarVisible ? .visible : .hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.25), value: isToolbarVisible)
        .sheet(isPresented: $showingFontSettings) {
```

- [ ] **Step 2: Verify build**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 4: Handle edge case — short content

**Files:**
- Modify: `readeck/UI/BookmarkDetail/BookmarkDetailView2.swift` (inside `onPreferenceChange(ContentHeightPreferenceKey.self)`)

- [ ] **Step 1: Ensure toolbar stays visible when content doesn't scroll**

Inside the existing `onPreferenceChange(ContentHeightPreferenceKey.self)` handler, after the `guard totalScrollableDistance > 0 else { return }` line (line 224), add a check to keep the toolbar visible:

```swift
guard totalScrollableDistance > 0 else {
    if !isToolbarVisible {
        isToolbarVisible = true
    }
    return
}
```

This replaces the existing `guard totalScrollableDistance > 0 else { return }`.

- [ ] **Step 2: Verify build**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

---

### Task 5: Manual testing and commit

- [ ] **Step 1: Run on simulator**

Run: `xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Manual test checklist**

Verify in the simulator or device:
1. Open an article — toolbar is visible
2. Scroll down — toolbar slides away
3. Small scroll up (< 12% screen height) — toolbar stays hidden
4. Larger scroll up (> 12% screen height) — toolbar slides back in
5. Scroll back to top — toolbar is visible
6. Short article that doesn't need scrolling — toolbar always visible
7. Status bar remains visible at all times

- [ ] **Step 3: Commit all changes**

```bash
git add readeck/UI/BookmarkDetail/BookmarkDetailView2.swift
git commit -m "feat: collapsible toolbar in article reader

Hide navigation bar on scroll-down, show after meaningful
scroll-up distance (~12% of screen height). Fixes #31."
```
