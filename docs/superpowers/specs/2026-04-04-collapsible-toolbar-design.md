# Collapsible Toolbar for Article Reader

**Issue:** #31 — Reduce button/text overlap
**Date:** 2026-04-04
**Scope:** BookmarkDetailView2 (iOS 26+) only

## Problem

The navigation bar toolbar buttons (tags, annotations, font settings) overlap article content while scrolling. The `ScrollView` uses `.ignoresSafeArea(edges: [.top, .bottom])`, so content scrolls behind the navigation bar with no mechanism to hide it.

## Solution

Implement a collapsible navigation bar that hides on scroll-down and reappears after a meaningful scroll-up distance, using the existing `ScrollOffsetPreferenceKey` infrastructure.

## Behavior

- **Initial state:** Toolbar visible when entering the reader
- **Scroll down:** Toolbar hides immediately
- **Scroll up:** Toolbar reappears only after scrolling up ~10-15% of screen height (threshold prevents flicker from micro-scrolls)
- **At top of content:** Toolbar always visible (offset ≤ 0)
- **Short content:** Toolbar always visible when content is shorter than the screen
- **Status bar:** Stays visible at all times — only the navigation bar hides
- **Animation:** Slide up/down with `.easeInOut(duration: 0.25)`

## Implementation Approach

**Approach A: ScrollView Offset + GeometryReader (pure SwiftUI)**

### Scroll Direction Tracking

Track scroll offset via the existing `ScrollOffsetPreferenceKey` and `GeometryReader` already present in `BookmarkDetailView2`. On each offset change:

1. Compare current offset to stored `previousOffset` to detect direction
2. If scrolling down → set `isToolbarVisible = false`, reset accumulator
3. If scrolling up → accumulate distance in `accumulatedScrollUp`
4. When `accumulatedScrollUp` exceeds threshold → set `isToolbarVisible = true`
5. Reset accumulator when direction reverses

### State

```swift
@State private var isToolbarVisible: Bool = true
@State private var previousScrollOffset: CGFloat = 0
@State private var accumulatedScrollUp: CGFloat = 0
```

### Toolbar Visibility

```swift
.toolbar(isToolbarVisible ? .visible : .hidden, for: .navigationBar)
.animation(.easeInOut(duration: 0.25), value: isToolbarVisible)
```

### Threshold Constant

```swift
private let scrollUpThresholdRatio: CGFloat = 0.12 // 12% of screen height
```

### Edge Cases

- **Offset ≤ 0:** Always show toolbar (user is at top)
- **Content shorter than screen:** Always show toolbar (no scrolling needed)
- **Rapid direction changes:** Accumulator resets on direction reversal, preventing false triggers
- **Rubber-band bounce at bottom:** Treat as scroll-up, but threshold prevents premature show

## Out of Scope

- Legacy reader view (`BookmarkDetailLegacyView`)
- Compact back button behavior
- Status bar hiding
- User-configurable threshold settings
