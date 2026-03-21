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
│   │   ├── LoginViewModelTests.swift
│   │   └── OAuthFlowTests.swift
│   ├── Bookmarks/
│   │   ├── BookmarksViewModelTests.swift
│   │   └── BookmarkDetailViewModelTests.swift
│   └── AddBookmark/
│       └── AddBookmarkViewModelTests.swift
├── OAuth/                           (existing — migrate)
├── Utils/                           (existing — migrate)
└── ...
```

---

## Mock Strategy

Simple structs conforming to existing repository protocols. Configurable `Result` properties, tracking flags only where needed.

### New Mocks

**MockBookmarksRepository** (implements `PBookmarksRepository`):
- Configurable results for: fetch, create, update, delete, archive
- Tracking: `deleteCalled`, `archiveCalled`, `createCalledWith`

**MockAuthRepository / Extended MockAPI**:
- Configurable results for: login, OAuth token refresh, session validation
- Simulate: expired tokens, server unreachable, invalid credentials

**MockTokenProvider** (extend existing):
- Make token expiry simulatable
- Add `refreshCalled` tracking

### Pattern

```swift
struct MockBookmarksRepository: PBookmarksRepository {
    var fetchResult: Result<[Bookmark], Error> = .success([])
    var createResult: Result<Bookmark, Error> = .success(.mock)
    var deleteCalled = false
    // Protocol methods return configured results
}
```

No mock frameworks. No over-engineering.

---

## Test Scope

### Auth (~5 test cases)

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
| Archive bookmark | Removed from active list |
| Delete bookmark | Removed from list |
| Empty list | Empty state shown |
| Load error | Error state set |
| Update read progress | Value correctly stored |

### Share Extension (~4 test cases)

| Test | Verifies |
|------|----------|
| Share URL | Bookmark created |
| Share URL without login | Error/hint state |
| Share URL with labels | Labels sent correctly |
| Server unreachable | Error message or offline queue |

### Mappers (~5 test cases)

| Test | Verifies |
|------|----------|
| BookmarkDTO → Bookmark | All fields mapped correctly |
| Missing/null fields | Sensible defaults |
| Empty strings | Handled gracefully |
| Label mapping | Tags/labels converted correctly |
| Date mapping | Timestamps parsed correctly |

### XCTest Migration (~80 existing test cases)

Migrate to Swift Testing (`@Suite`, `@Test`, `#expect`):
- `EndpointValidatorTests` (54 tests)
- `PKCEGeneratorTests` (10 tests)
- `ServerInfoTests` (12 tests)
- `StringExtensionsTests` (8 tests)

---

## Constraints

- **Pure unit tests only** — no network, no real server
- **All mocks via dependency injection** — leveraging existing Clean Architecture protocols
- **Swift Testing exclusively** — `import Testing`, `@Suite`, `@Test`, `#expect`
- **No mock frameworks** — simple structs with configurable results
- **`@MainActor` where needed** — ViewModels publish on main thread

---

## Out of Scope

- UI tests (SwiftUI views)
- Integration tests against real server
- Use Case tests (thin wrappers, tested implicitly through ViewModel tests)
- Offline sync tests (already well-covered)
- Performance / snapshot tests
