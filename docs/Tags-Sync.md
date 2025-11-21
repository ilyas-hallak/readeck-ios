# Tags Synchronization

This document describes how tags (labels) are synchronized and updated throughout the readeck app.

## Overview

The app uses a **cache-first strategy** with background synchronization to ensure fast UI responses while keeping data up-to-date with the server.

## Architecture

### Components

1. **Core Data Storage** (`TagEntity`)
   - Local persistent storage for all tags
   - Fields: `name` (String), `count` (Int32)
   - Used as the single source of truth for all UI components

2. **LabelsRepository**
   - Manages tag synchronization between API and Core Data
   - Implements cache-first loading strategy

3. **CoreDataTagManagementView**
   - SwiftUI view component for tag management
   - Uses `@FetchRequest` to directly query Core Data
   - Automatically updates when Core Data changes

4. **LabelsView**
   - Full-screen tag list view
   - Accessible via "More" → "Tags" tab
   - Triggers manual tag synchronization

## Synchronization Flow

### When Tags are Fetched

Tags are synchronized in the following scenarios:

#### 1. Opening the Tags Tab
**Trigger**: User navigates to "More" → "Tags"
**Location**: `LabelsView.swift:43-46`

```swift
.onAppear {
    Task {
        await viewModel.loadLabels()
    }
}
```

**Process**:
1. Immediately loads tags from Core Data (instant response)
2. Starts background API call to fetch latest tags
3. Updates Core Data if API call succeeds
4. Silently fails if server is unreachable (keeps cached data)

#### 2. Background Sync Strategy
**Implementation**: `LabelsRepository.getLabels()`

The repository uses a two-phase approach:

**Phase 1: Instant Response**
```swift
let cachedLabels = try await loadLabelsFromCoreData()
```
- Returns immediately with cached data
- Ensures UI is never blocked

**Phase 2: Background Update**
```swift
Task.detached(priority: .background) {
    let dtos = try await self.api.getBookmarkLabels()
    try? await self.saveLabels(dtos)
}
```
- Runs asynchronously in background
- Updates Core Data with latest server data
- Silent failure - no error shown to user if sync fails

#### 3. Adding a New Bookmark
**Trigger**: User opens "Add Bookmark" sheet
**Location**: `AddBookmarkView.swift:61-66`

```swift
.onAppear {
    viewModel.checkClipboard()
    Task {
        await viewModel.syncTags()
    }
}
```

**Process**:
1. Triggers background sync when view appears
2. `CoreDataTagManagementView` shows cached tags immediately
3. View automatically updates via `@FetchRequest` when sync completes

#### 4. Editing Bookmark Labels
**Trigger**: User opens "Manage Labels" sheet from bookmark detail
**Location**: `BookmarkLabelsView.swift:49-53`

```swift
.onAppear {
    Task {
        await viewModel.syncTags()
    }
}
```

**Process**:
1. Triggers background sync when view appears
2. `CoreDataTagManagementView` shows cached tags immediately
3. View automatically updates via `@FetchRequest` when sync completes

#### 5. Share Extension

Tags are **not** synced in the Share Extension:
- Uses cached tags from Core Data only
- No API calls to minimize extension launch time
- Relies on tags synced by main app

**Reason**: Share Extensions should be fast and lightweight. Tags are already synchronized by the main app when opening tags tab or managing bookmark labels.

### When Core Data Updates

Core Data tag updates trigger automatic UI refreshes in all views using `@FetchRequest`:
- `CoreDataTagManagementView`
- `LabelsView`

This happens when:
- Background sync completes successfully
- New tags are created via bookmark operations
- Tag counts change due to bookmark label modifications

## Tag Display Configuration

### Share Extension
- **Fixed sorting**: Always by usage count (`.byCount`)
- **Display limit**: Top 150 tags
- **Label**: "Most used tags"
- **Rationale**: Quick access to most frequently used tags for fast bookmark creation

### Main App
- **User-configurable sorting**: Either by usage count or alphabetically
- **Display limit**: All tags (no limit)
- **Setting location**: Settings → Appearance → Tag Sort Order
- **Labels**:
  - "Sorted by usage count" (when `.byCount`)
  - "Sorted alphabetically" (when `.alphabetically`)

## Data Persistence

### Core Data Updates
Tags in Core Data are updated through:

1. **Batch sync** (`LabelsRepository.saveLabels`)
   - Compares existing tags with new data from server
   - Updates counts for existing tags
   - Inserts new tags
   - Only saves if changes detected

2. **Efficiency optimizations**:
   - Batch fetch of existing entities
   - Dictionary-based lookups for fast comparison
   - Conditional saves to minimize disk I/O

## Error Handling

### Network Failures
- **Behavior**: Silent failure
- **User Experience**: App continues to work with cached data
- **Rationale**: Tags are not critical for app functionality; offline access is prioritized

### Core Data Errors
- **Read errors**: UI shows empty state or cached data
- **Write errors**: Logged but do not block UI operations

## Implementation Notes

### Deprecated Components
- `LegacyTagManagementView.swift`: Old API-based tag management (marked for removal)
- `TagManagementView.swift`: Deleted, replaced by `CoreDataTagManagementView.swift`

### Key Differences: New vs Old Approach

**Old (LegacyTagManagementView)**:
- Fetched tags from API on every view appearance
- Slower initial load
- Required network connectivity
- More server load

**New (CoreDataTagManagementView)**:
- Uses Core Data with `@FetchRequest`
- Instant UI response
- Works offline
- Automatic UI updates via SwiftUI reactivity
- Reduced server load through background sync

## Future Considerations

1. **Offline tag creation**: Currently, new tags can be created offline but won't sync until server is reachable
2. **Tag deletion**: Not implemented in current version
3. **Tag renaming**: Not implemented in current version
4. **Conflict resolution**: Tags created offline with same name as server tags will merge on sync
