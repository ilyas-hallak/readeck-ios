# Share Extension: Send Page Content (HTML)

**Date:** 2026-04-13
**Status:** Approved

## Overview

Extend the Readeck iOS Share Extension to optionally send the full HTML content of a web page along with the bookmark URL. This enables saving articles behind paywalls, since the HTML is captured from the authenticated Safari session.

## Approach

JavaScript Preprocessing captures the page HTML before the Share Extension UI appears. The HTML is always available in the ViewModel but only sent to the API when the user opts in via a toggle. This avoids timing issues (JS runs before the UI) and keeps the default flow unchanged.

## API

Uses the existing JSON endpoint with an additional `html` field:

```
POST /api/bookmarks
Content-Type: application/json

{
  "url": "https://example.com/article",
  "title": "Optional title",
  "labels": ["tag1"],
  "html": "<html>...full page content...</html>"
}
```

The `html` field is optional. When omitted, behavior is identical to current implementation. Available in Readeck server v0.22+.

## Components

### 1. JavaScript Preprocessing — `URLShare/ShareExtension.js`

New JavaScript file executed by Safari before the Share Extension opens.

- Reads `document.URL`, `document.title`, `document.documentElement.outerHTML`
- Returns all three as a dictionary via `arguments.completionFunction()`
- Registered in `URLShare/Info.plist` via `NSExtensionJavaScriptPreprocessingFile: "ShareExtension"`

`ShareViewController` extracts the HTML from the `NSExtensionItem` via `kUTTypePropertyList`. The HTML is passed to the ViewModel as an optional string (`pageHTML: String?`).

### 2. UI — Toggle in ShareBookmarkView

New toggle in `ShareBookmarkView`, positioned between the tag management section and the title field:

- **Label:** "Send page content"
- **Subtitle:** "Useful for paywalled articles" (caption style, secondary color)
- Standard iOS `Toggle` with `.toggleStyle(.switch)`
- Bound to `viewModel.includeHTML` (default: `false`, reset on each share)
- Only visible when `viewModel.pageHTML != nil` (hidden for non-web shares or when JS preprocessing didn't return HTML)

### 3. API & DTOs

**`CreateBookmarkRequestDto`** — add optional `html: String?` field.

**`SimpleAPI.addBookmark()`** — accepts optional `html` parameter. Includes it in the JSON body only when `includeHTML == true` and `pageHTML` is non-nil.

**Success message:**
- Toggle off: existing message "Saved: {server message}"
- Toggle on: "Saved with page content"

### 4. Offline Support

**CoreData — `ArticleURLEntity`:**
- New optional attribute `html: String?`
- `OfflineBookmarkManager.saveOfflineBookmark()` accepts optional `html` parameter
- HTML is stored only when the toggle was enabled at save time

**`OfflineSyncManager`:**
- During sync: if `html` is present on the entity, include it in the `CreateBookmarkRequestDto`
- If not, sync as URL-only (existing behavior)

## Data Flow

```
Safari Page
    │
    ▼
ShareExtension.js (JavaScript Preprocessing)
    │  extracts: url, title, html
    ▼
ShareViewController
    │  passes url, title, html to ViewModel
    ▼
ShareBookmarkViewModel
    │  pageHTML: String? (always populated if JS ran)
    │  includeHTML: Bool (toggle state, default false)
    │
    ├─ Online + toggle ON  → SimpleAPI.addBookmark(url, title, labels, html)
    ├─ Online + toggle OFF → SimpleAPI.addBookmark(url, title, labels, nil)
    ├─ Offline + toggle ON → OfflineBookmarkManager.save(url, title, tags, html)
    └─ Offline + toggle OFF→ OfflineBookmarkManager.save(url, title, tags, nil)
```

## Out of Scope

- Multipart/form-data with embedded resources (images, SVGs) — potential future enhancement
- HTML size limits or truncation — rely on server-side handling for now
- Persisting toggle state between shares — intentionally resets to off each time
