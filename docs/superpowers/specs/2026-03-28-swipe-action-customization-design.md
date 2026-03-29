# Swipe Action Customization — Design Spec

**Issue:** #32 — List view gesture customization suggestions
**Scope:** Configurable swipe actions per side using native SwiftUI
**Date:** 2026-03-28

---

## Overview

Let users configure which actions appear on left and right swipe in the bookmark list view. Uses SwiftUI's native `.swipeActions()` — no custom gesture system.

## Available Actions

| Action | Icon | Color | Behavior |
|--------|------|-------|----------|
| `archive` | `archivebox` / `tray.and.arrow.up` | orange / blue | Toggle archived state |
| `favorite` | `heart.fill` / `heart.slash` | pink / gray | Toggle favorite (icon only, no text) |
| `delete` | `trash` | red (destructive) | Delete with 3-second undo |
| `showTags` | `tag` | teal | Open tag sheet |
| `openInBrowser` | `safari` | blue | Open URL using URL opener setting |

## Data Model

### `SwipeAction` enum
Cases: `.archive`, `.favorite`, `.delete`, `.showTags`, `.openInBrowser`

Codable and stored as part of Settings.

### `SwipeActionConfig` struct
```swift
struct SwipeActionConfig: Codable {
    var leadingActions: [SwipeAction]  // max 3
    var trailingActions: [SwipeAction] // max 3
}
```

### Defaults
- **Trailing (right swipe):** `[.delete]`
- **Leading (left swipe):** `[.archive, .favorite]`

Matches current hardcoded behavior — no change for existing users.

### Persistence
Stored in the existing `Settings` struct as a new `swipeActionConfig` property. Flows through `AppSettings` to the views like all other settings.

## BookmarkCardView Changes

- Receives `SwipeActionConfig` as a parameter
- Dynamically renders `.swipeActions()` by iterating over the config arrays
- Single unified callback: `onSwipeAction: (SwipeAction, Bookmark) -> Void`
  - Replaces individual `onArchive`, `onDelete`, `onToggleFavorite` callbacks
  - ViewModel handles action routing via switch
  - Undo system for delete triggered through the same path
- Full swipe enabled only for the **first action** on each side
- Each action renders based on its enum case (icon, color, role)

## ViewModel Changes

- New method handling the unified `onSwipeAction` callback
- Routes to existing logic: `toggleArchive`, `toggleFavorite`, `deleteBookmarkWithUndo`
- New handlers for `showTags` (present sheet) and `openInBrowser` (use URL opener setting)
- No new use cases needed — all actions use existing functionality

## Settings UI

New section **"Swipe Actions"** in Settings:

- Split into **Right (Trailing)** and **Left (Leading)** subsections
- Each subsection shows ordered list of configured actions (icon + name)
- Actions reorderable via drag & drop (`.onMove`)
- Actions removable via swipe or minus button
- "Add Action" button shows only unassigned actions
- Max 3 per side — add button disabled when full
- "Reset to Default" button at the bottom

## New Actions Implementation

### Show Tags
- Opens a sheet with the bookmark's tags
- Reuses existing tag display/editing logic from the detail view

### Open in Browser
- Reads `urlOpener` setting (in-app browser vs Safari)
- Opens the bookmark's URL accordingly
- Reuses existing URL opening logic

## Constraints

- Max 3 actions per side
- Each action can only appear once across both sides
- Native SwiftUI `.swipeActions()` — no custom gesture recognizers
- Full swipe only on first action per side
