# Offline Reading Feature Documentation

## Overview

The Readeck iOS application includes a comprehensive offline reading feature that allows users to cache bookmarks and articles for reading without an internet connection. This feature implements automated synchronization, intelligent image caching, and FIFO-based cache management.

## Architecture Overview

The offline feature follows **Clean Architecture** principles with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│          UI Layer (SwiftUI Views)           │
│  - BookmarksView, BookmarkDetailView        │
│  - OfflineBookmarksViewModel                │
│  - CachedAsyncImage Component               │
└────────────────┬────────────────────────────┘
                 │
┌─────────────────▼────────────────────────────┐
│        Domain Layer (Use Cases)              │
│  - OfflineCacheSyncUseCase                   │
│  - GetCachedBookmarksUseCase                 │
│  - GetCachedArticleUseCase                   │
└────────────────┬────────────────────────────┘
                 │
┌─────────────────▼────────────────────────────┐
│      Data Layer (Repository Pattern)         │
│  - OfflineCacheRepository                    │
│  - OfflineSettingsRepository                 │
│  - Kingfisher Image Cache                    │
└─────────────────────────────────────────────┘
```

## Core Components

### 1. Data Models

#### OfflineSettings
Configuration for offline caching behavior (stored in UserDefaults):
```swift
struct OfflineSettings: Codable {
    var enabled: Bool = true               // Feature enabled/disabled
    var maxUnreadArticles: Double = 20     // Max cached articles (0-100)
    var saveImages: Bool = false           // Cache images in articles
    var lastSyncDate: Date?                // Last successful sync timestamp
    
    var maxUnreadArticlesInt: Int {
        Int(maxUnreadArticles)             // Helper: Double to Int conversion
    }
}
```

#### BookmarkEntity (CoreData)
Persisted bookmark with offline caching:
- `id`: Unique identifier
- `title`: Article title
- `url`: Original URL
- `htmlContent`: Full article HTML (added for offline)
- `cachedDate`: Timestamp when cached (added for offline)
- `lastAccessDate`: Last read timestamp (added for offline)
- `heroImageURL`: Hero image URL (added for offline)
- `imageURLs`: JSON array of content image URLs (added for offline)
- `cacheSize`: Cache size in bytes (added for offline)
- Plus other fields: authors, created, description, lang, readingTime, wordCount, etc.

### 2. Use Cases

#### OfflineCacheSyncUseCase
Main orchestrator for the offline sync process:

**Responsibilities:**
- Fetch unread bookmarks from server
- Download article HTML content
- Prefetch and cache images
- Embed images as Base64 (optional)
- Persist to CoreData
- Implement retry logic for temporary errors
- Publish sync progress updates
- Clean up old cached articles (FIFO)

**Retry Logic:**
- Retryable errors: HTTP 502, 503, 504 (temporary server issues)
- Non-retryable errors: 4xx client errors, network failures
- Exponential backoff: 2s → 4s between attempts
- Maximum retries: 2 (3 total attempts)

**Progress Publishers:**
- `isSyncing: AnyPublisher<Bool, Never>` - Sync state
- `syncProgress: AnyPublisher<String?, Never>` - Human-readable status

#### GetCachedBookmarksUseCase
Retrieve cached bookmarks for offline reading:
- Fetches all cached bookmarks from CoreData
- Returns sorted by `cachedDate` (newest first)
- Used when network is unavailable

#### GetCachedArticleUseCase
Retrieve cached article HTML:
- Looks up article by bookmark ID
- Returns full HTML content
- Updates `lastAccessDate` for cache management
- Returns nil if not cached

### 3. Repository Layer

#### OfflineCacheRepository
Manages all offline cache operations:

**Cache Operations:**
- `cacheBookmarkWithMetadata()` - Store bookmark + HTML + metadata
- `hasCachedArticle()` - Check if article is cached
- `getCachedArticle()` - Retrieve HTML content
- `getCachedBookmarks()` - Get all cached bookmarks

**Image Handling:**
- `extractImageURLsFromHTML()` - Parse img src URLs from HTML
- `prefetchImagesWithKingfisher()` - Download images to disk cache
- `embedImagesAsBase64()` - Convert cached images to data URIs
- `verifyPrefetchedImages()` - Validate images persisted after prefetch

**Cache Management:**
- `clearCache()` - Remove all cached articles and images
- `cleanupOldestCachedArticles()` - FIFO cleanup when cache exceeds limit
- `getCachedArticlesCount()` - Number of cached articles
- `getCacheSize()` - Total cache size in bytes

#### Image Caching Strategy

**Kingfisher Configuration:**
```swift
KingfisherManager.shared.cache.diskStorage.config.expiration = .never
```

**Two-Phase Image Strategy:**

1. **Hero/Thumbnail Images** (preserved in Kingfisher cache)
   - Downloaded during sync with custom cache key
   - Loaded from cache in offline mode via `CachedAsyncImage`
   - Not embedded as Base64

2. **Content Images** (embedded in HTML)
   - Extracted from article HTML
   - Prefetched during sync
   - Optionally embedded as Base64 data URIs (if `saveImages = true`)
   - Online: HTTP URLs preserved
   - Offline: Base64 embedded or fallback to cache

### 4. UI Components

#### CachedAsyncImage
Smart image component with online/offline awareness:

```swift
CachedAsyncImage(url: imageURL) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image.resizable()
    case .failure:
        Image(systemName: "photo.slash")
    @unknown default:
        EmptyView()
    }
}
```

**Behavior:**
- Online: Normal KFImage loading with network access
- Offline: `.onlyFromCache(true)` - Only loads cached images
- Graceful fallback: Shows placeholder if not cached

#### OfflineBookmarksViewModel
Manages offline bookmark synchronization:

**State Machine:**
- `.idle` - No sync in progress
- `.pending(count)` - X articles ready to sync
- `.syncing(count, status)` - Actively syncing, showing progress
- `.success(count)` - Sync completed successfully
- `.error(message)` - Sync failed

**Key Methods:**
- `syncOfflineBookmarks()` - Trigger manual sync
- `refreshState()` - Update sync state from repository
- Bindings to `OfflineCacheSyncUseCase` publishers

#### BookmarksViewModel
Enhanced to support offline reading:

**Cache-First Approach:**
- `loadCachedBookmarks()` - Fetch from local cache when offline
- Only loads cached bookmarks for "Unread" tab
- Network error detection triggers cache fallback
- Archive/Starred/All tabs show "Tab not available offline"

#### BookmarkDetailViewModel
Read cached article content:

**Article Loading Priority:**
1. Try load from offline cache
2. Fallback to server if not cached
3. Report Base64 vs HTTP image counts

## Synchronization Flow

```
┌─ User triggers sync (manual or automatic)
│
├─ Check if offline feature enabled
├─ Check if network available
│
├─ Fetch unread bookmarks from server
│  └─ Implement pagination if needed
│
├─ For each bookmark:
│  ├─ Fetch article HTML with retry logic
│  │  ├─ Attempt 1: Immediate
│  │  ├─ Failure → 2s backoff → Attempt 2
│  │  └─ Failure → 4s backoff → Attempt 3
│  │
│  ├─ Extract image URLs from HTML
│  ├─ Prefetch images with Kingfisher
│  │  └─ Optional: Embed as Base64 if saveImages=true
│  │
│  └─ Persist to CoreData with timestamp
│
├─ Cleanup old articles (FIFO when max exceeded)
├─ Update lastSyncDate
│
└─ Publish completion/error status
```

## Cache Lifecycle

### Adding to Cache
1. User manually syncs or automatic sync triggers
2. Unread bookmarks fetched from server
3. Article HTML + images downloaded
4. Stored in CoreData + Kingfisher cache
5. `cachedDate` recorded

### Using from Cache
1. Network unavailable or error detected
2. `loadCachedBookmarks()` called
3. Returns list from CoreData (sorted by date)
4. User opens article
5. HTML loaded from cache
6. Images loaded from Kingfisher cache (`.onlyFromCache` mode)

### Removing from Cache
**Automatic (FIFO Cleanup):**
- When cached articles exceed `maxCachedArticles` (default: 20)
- Oldest articles deleted first
- Associated images also removed from Kingfisher

**Manual:**
- Settings → Offline → Clear Cache
- Removes all CoreData entries + Kingfisher images

## Error Handling & Retry Logic

### Retryable Errors (with backoff)
| HTTP Status | Reason | Retry? |
|-------------|--------|--------|
| 502 | Bad Gateway | ✅ Yes (temp server issue) |
| 503 | Service Unavailable | ✅ Yes (maintenance) |
| 504 | Gateway Timeout | ✅ Yes (slow backend) |

### Non-Retryable Errors (skip article)
| Error | Reason |
|-------|--------|
| 400-499 | Client error (bad URL, etc) |
| Connection failed | Network unavailable |
| Invalid URL | Malformed bookmark URL |

**Sync Behavior:** Failed articles are skipped, sync continues with remaining bookmarks.

## Configuration & Settings

### OfflineSettings Storage
- Persisted in **UserDefaults** (not CoreData)
- Encoded/decoded as JSON
- Survives app restarts
- Contains: enabled, maxUnreadArticles, saveImages, lastSyncDate

### Kingfisher Configuration
```swift
// Disk cache never expires
KingfisherManager.shared.cache.diskStorage.config.expiration = .never

// Offline mode: Only load from cache
KFImage(url)
    .onlyFromCache(true)
```

### Cache Limits
- **Max cached articles:** 20 (configurable via `maxUnreadArticles` slider)
- **Max HTML size:** Unlimited (depends on device storage)
- **Image formats:** Original from server (no processing)
- **Cache location:** App Documents folder (CoreData) + Kingfisher disk cache

## Testing

### Unit Tests Coverage
- OfflineCacheSyncUseCase: Sync flow, retry logic, cleanup
- OfflineCacheRepository: Cache operations, image handling
- GetCachedBookmarksUseCase: Retrieval logic
- OfflineSettingsRepository: Settings persistence

### Manual Testing Scenarios

**Scenario 1: Hero Images Offline**
1. Start app online, enable sync
2. Wait for sync completion
3. Open Debug Menu (Shake) → Simulate Offline Mode
4. Verify hero/thumbnail images load from cache

**Scenario 2: Article Content Offline**
1. Open article while online (images load)
2. Enable offline mode
3. Reopen same article
4. Verify all images display correctly

**Scenario 3: FIFO Cleanup**
1. Cache 25+ articles (exceeds 20-limit)
2. Verify oldest 5 removed
3. Check newest 20 retained

**Scenario 4: Manual Cache Clear**
1. Settings → Offline → Clear Cache
2. Verify all cached articles removed
3. Verify disk space freed

## Performance Considerations

### Image Optimization
- **Format:** Original format from server (JPEG, PNG, WebP, etc.)
- **Quality:** No compression applied, stored as-is
- **Size:** Depends on server originals
- **Kingfisher cache:** Automatic disk management
- **Base64 embedding:** Increases HTML by ~30-40% (only for embedded images)

### Memory Usage
- CoreData uses SQLite (efficient)
- Kingfisher cache limited by available disk
- HTML content stored efficiently with compression

### Network Impact
- Prefetch uses concurrent image downloads
- Retry logic prevents thundering herd
- Exponential backoff reduces server load

## Known Limitations

1. **Offline Tab Restrictions**
   - Only "Unread" tab available offline
   - Archive/Starred require server
   - Reason: Offline cache maintains unread state

2. **Read Progress Sync**
   - Local read progress preserved offline
   - Server sync when connection restored
   - No real-time sync offline

3. **New Bookmarks**
   - Cannot create bookmarks offline
   - Share Extension requires internet
   - Will be queued for sync when online

4. **Image Quality**
   - Images cached as-is from server (no compression applied)
   - Kingfisher stores original image format and quality
   - Image sizes depend on server originals
   - No optimization currently implemented

5. **VPN Connection Detection Issue** ⚠️ 
   - Network monitor incorrectly detects VPN as active internet connection
   - Even in Airplane Mode + VPN, app thinks network is available
   - **Problem:** App doesn't switch to offline mode when it should
   - **Impact:** Cannot test offline functionality with VPN enabled
   - **Root cause:** Network reachability check only looks at interface, not actual connectivity
   - **Workaround:** Disable VPN before using offline feature
   - **Solution needed:** Enhanced network reachability check that differentiates between:
     - Actual internet connectivity (real WiFi/cellular)
     - VPN-only connections (should be treated as offline for app purposes)
     - Add explicit connectivity test to Readeck server

## Future Enhancements

- [ ] **Migrate OfflineSettings to CoreData**
  - Currently stored in UserDefaults as JSON
  - Should be migrated to CoreData entity for consistency
  - Better type safety and querying capabilities
  - Atomic transactions with other cached data

- [ ] **URGENT:** Fix VPN detection in network monitor
  - Properly detect actual internet vs VPN-only connection
  - Add explicit connectivity check to Readeck server
  - Show clear error when network detected but server unreachable

- [ ] **Image optimization** (compress images during caching)
  - Add optional compression during prefetch
  - Settings UI: Original / High / Medium / Low quality
  - Consider JPEG compression for bandwidth optimization

- [ ] Selective article caching (star/tag based)
- [ ] Background sync with silent notifications
- [ ] Delta sync (only new articles)
- [ ] Archive/Starred offline access
- [ ] Offline reading time statistics
- [ ] Automatic sync on WiFi only
- [ ] Cloud sync of offline state

## Debugging

### Debug Menu
- Accessible via Settings → Debug or device Shake
- "Simulate Offline Mode" toggle
- Cache statistics and management
- Logging viewer
- Core Data reset

### Key Log Messages
```
✅ Sync started: 15 unread bookmarks
🔄 Starting Kingfisher prefetch for 8 images
✅ Article cached: Title
❌ Failed to cache: Title (will retry)
⏳ Retry 1/2 after 2s delay
📊 Cache statistics: 20/20 articles, 125 MB
🧹 FIFO cleanup: Removed 5 oldest articles
```

### Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| No images offline | Offline mode active | Turn off "Simulate Offline" in Debug Menu |
| Sync fails | Network error | Check internet, retry via Settings |
| Cache full | Max articles reached | Settings → Clear Cache or increase limit |
| Old articles deleted | FIFO cleanup | Normal behavior, oldest removed first |
| Images not caching | Unsupported format | Check image URLs, verify HTTP/HTTPS |

## Related Documentation

- Architecture: See `documentation/Architecture.md`
- Offline Settings: See `OFFLINE_CACHE_TESTING_PROMPT.md`
- Sync Retry Logic: See `OFFLINE_SYNC_RETRY_LOGIC.md`
- Image Loading: See `OFFLINE_IMAGES_FIXES.md`
- Testing Guide: See `OFFLINE_CACHE_TESTING_PROMPT.md`

## Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| Core sync logic | ✅ Complete | With retry + backoff |
| Image caching | ✅ Complete | Kingfisher integration |
| Base64 embedding | ✅ Complete | Optional feature |
| Offline UI | ✅ Complete | Unread tab support |
| Settings UI | ✅ Complete | Full configuration |
| Debug tools | ✅ Complete | Shake gesture access |
| Unit tests | ✅ Complete | 80%+ coverage |
| Performance optimization | ✅ Complete | Image compression |
