# Unit Testing Design: Critical Path Coverage

**Date:** 2026-03-21
**Goal:** Release confidence through testing the critical paths: Auth, Bookmarks CRUD, Share Extension
**Framework:** Swift Testing (migrate all existing XCTest tests)
**Strategy:** ViewModel-first with mocked repositories + separate Mapper tests

---

## Test Architecture

```
readeckTests/
├── Helpers/
│   ├── TestMocks.swift              (existing — extend)
│   └── MockRepositories.swift       (new — protocol-conforming mocks)
├── Domain/                          (existing — migrate to Swift Testing)
├── Mappers/
│   └── DtoMapperTests.swift         (new)
├── ViewModels/
│   ├── Auth/
│   │   └── AppViewModelAuthTests.swift   (auth logic lives in AppViewModel)
│   ├── Bookmarks/
│   │   ├── BookmarksViewModelTests.swift
│   │   └── BookmarkDetailViewModelTests.swift
│   └── ShareExtension/
│       └── ShareBookmarkViewModelTests.swift  (URLShare target)
├── OAuth/                           (existing — migrate)
├── Utils/                           (existing — migrate)
├── StringExtensionsTests.swift      (existing at root — migrate)
└── ...
```

**Note:** Auth logic is handled by `AppViewModel` and inline in `OnboardingServerView` — there is no dedicated `LoginViewModel`. Auth tests target `AppViewModel`. Share Extension logic lives in `ShareBookmarkViewModel` in the `URLShare` target.

---

## Mock Strategy

Classes conforming to existing repository protocols (consistent with existing `TestMockAPI` pattern). Configurable `Result` properties, tracking flags only where needed.

### New Mocks

**MockBookmarksRepository** (implements `PBookmarksRepository`):
- Configurable results for: fetch, create, update, delete
- Archive via `updateBookmark` with archived state (no dedicated archive method)
- Tracking: `deleteCalled`, `updateCalledWith`, `createCalledWith`

**MockAuthRepository / Extended MockAPI**:
- Configurable results for: login, OAuth token refresh, session validation
- Simulate: expired tokens, server unreachable, invalid credentials

**MockTokenProvider** (extend existing):
- Make token expiry simulatable
- Add `refreshCalled` tracking

### Pattern

```swift
class MockBookmarksRepository: PBookmarksRepository {
    var fetchResult: Result<[Bookmark], Error> = .success([])
    var createResult: Result<Bookmark, Error> = .success(Bookmark.testFixture())
    var deleteCalled = false
    // Protocol methods return configured results
}
```

**Test fixtures:** Create `Bookmark.testFixture()` static factory method as test helper (no `.mock` exists on domain models).

No mock frameworks. No over-engineering.

---

## Test Scope

### Auth (~5 test cases) — targets `AppViewModel`

| Test | Verifies |
|------|----------|
| Login with valid credentials | Token stored, state → logged in |
| Login with invalid credentials | Error message in state |
| OAuth token refresh success | New token, stays logged in |
| OAuth token refresh failure | Logout triggered |
| Server unreachable | Error state set |

### Bookmarks CRUD (~7 test cases)

| Test | Verifies |
|------|----------|
| Load bookmarks | List populated in state |
| Create bookmark | Appears in list |
| Archive bookmark (via update) | Removed from active list |
| Delete bookmark | Removed from list |
| Empty list | Empty state shown |
| Load error | Error state set |
| Update read progress | Value correctly stored |

### Share Extension (~4 test cases) — targets `ShareBookmarkViewModel`

| Test | Verifies |
|------|----------|
| Share URL | Bookmark created |
| Share URL without login | Error/hint state |
| Share URL with labels | Labels sent correctly |
| Server unreachable | Error message or offline queue |

**Note:** `ShareBookmarkViewModel` lives in the `URLShare` target. Tests need access to that target or the ViewModel needs to be in a shared framework.

### Mappers (~5 test cases)

| Test | Verifies |
|------|----------|
| `BookmarkDto` → `Bookmark` | All fields mapped correctly |
| Missing/null fields | Sensible defaults |
| Empty strings | Handled gracefully |
| Label mapping | Tags/labels converted correctly |
| Date mapping | Timestamps parsed correctly |

**Note:** Mapping logic is spread across `BookmarkMapper.swift`, `DtoMapper.swift` (annotations), and `BookmarkEntityMapper.swift` (CoreData). Use `Dto` suffix (not `DTO`) to match codebase convention.

### XCTest Migration (4 files, ~89 test cases)

Migrate to Swift Testing (`@Suite`, `@Test`, `#expect`):
- `EndpointValidatorTests` (~52 tests)
- `PKCEGeneratorTests` (~12 tests)
- `ServerInfoTests` (~13 tests)
- `StringExtensionsTests` (~12 tests)

**Already on Swift Testing (no migration needed):** `HTMLImageEmbedderTests`, `HTMLImageExtractorTests`, `KingfisherImagePrefetcherTests`, `OfflineSyncManagerTests`, `OfflineSettingsTests`, `OfflineCacheRepositoryTests`

---

## Constraints

- **Pure unit tests only** — no network, no real server
- **All mocks via dependency injection** — leveraging existing Clean Architecture protocols
- **Swift Testing exclusively** — `import Testing`, `@Suite`, `@Test`, `#expect`
- **No mock frameworks** — classes with configurable results (matches existing pattern)
- **`@MainActor` where needed** — ViewModels publish on main thread

---

## Out of Scope

- UI tests (SwiftUI views)
- Integration tests against real server
- Use Case tests (thin wrappers, tested implicitly through ViewModel tests)
- Offline sync tests (already well-covered)
- Performance / snapshot tests
