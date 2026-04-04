# Unit Testing: Critical Path Coverage — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add unit tests for Auth, Bookmarks CRUD, and Share Extension flows to build release confidence.

**Architecture:** ViewModels are tested by injecting a configurable `UseCaseFactory` that returns mock use cases with controllable `Result` values. Existing `MockUseCaseFactory` (in main target) returns hardcoded values — we create a test-target factory with configurable mocks. Mapper tests exercise `toDomain()` extensions directly.

**Tech Stack:** Swift Testing (`@Suite`, `@Test`, `#expect`), `@testable import readeck`

**Spec:** `docs/superpowers/specs/2026-03-21-unit-testing-design.md`

---

## File Structure

### New Files (Test Target: `readeckTests`)

| File | Responsibility |
|------|---------------|
| `readeckTests/Helpers/ConfigurableMocks.swift` | Configurable mock use cases with `Result` properties |
| `readeckTests/Helpers/TestUseCaseFactory.swift` | Test factory returning configurable mocks |
| `readeckTests/ViewModels/BookmarksViewModelTests.swift` | BookmarksViewModel load, archive, delete, error tests |
| `readeckTests/ViewModels/BookmarkDetailViewModelTests.swift` | BookmarkDetailViewModel detail, article, progress tests |
| `readeckTests/ViewModels/AppViewModelTests.swift` | AppViewModel auth/reachability tests |
| `readeckTests/Mappers/BookmarkMapperTests.swift` | BookmarkDto → Bookmark mapping tests |
| `readeckTests/Mappers/AnnotationMapperTests.swift` | AnnotationDto → Annotation mapping tests |

### Modified Files (Migration)

| File | Change |
|------|--------|
| `readeckTests/Domain/EndpointValidatorTests.swift` | XCTest → Swift Testing |
| `readeckTests/Domain/ServerInfoTests.swift` | XCTest → Swift Testing |
| `readeckTests/OAuth/PKCEGeneratorTests.swift` | XCTest → Swift Testing |
| `readeckTests/StringExtensionsTests.swift` | XCTest → Swift Testing |

---

## Task 1: Test Infrastructure — Configurable Mocks

**Files:**
- Create: `readeckTests/Helpers/ConfigurableMocks.swift`
- Create: `readeckTests/Helpers/TestUseCaseFactory.swift`
- Reference: `readeck/UI/Factory/MockUseCaseFactory.swift` (existing pattern)
- Reference: `readeck/UI/Factory/DefaultUseCaseFactory.swift:3-41` (UseCaseFactory protocol)

- [ ] **Step 1: Create configurable mock use cases**

Create `readeckTests/Helpers/ConfigurableMocks.swift` with configurable versions of the use cases needed for testing. Each mock has a `Result` property to control success/failure, and tracking properties where needed.

```swift
import Foundation
import Testing
@testable import readeck

// MARK: - Configurable Mock Use Cases

class ConfigurableGetBookmarksUseCase: PGetBookmarksUseCase {
    var result: Result<BookmarksPage, Error> = .success(
        BookmarksPage(bookmarks: [.mock], currentPage: 1, totalCount: 1, totalPages: 1, links: nil)
    )
    var executeCalled = false
    var lastState: BookmarkState?

    func execute(state: BookmarkState?, limit: Int?, offset: Int?, search: String?, type: [BookmarkType]?, tag: String?) async throws -> BookmarksPage {
        executeCalled = true
        lastState = state
        return try result.get()
    }
}

class ConfigurableUpdateBookmarkUseCase: PUpdateBookmarkUseCase {
    var result: Result<Void, Error> = .success(())
    var toggleArchiveCalled = false
    var toggleFavoriteCalled = false
    var updateProgressCalled = false
    var lastProgressValue: Int?

    func execute(bookmarkId: String, updateRequest: BookmarkUpdateRequest) async throws { try result.get() }
    func toggleArchive(bookmarkId: String, isArchived: Bool) async throws {
        toggleArchiveCalled = true
        try result.get()
    }
    func toggleFavorite(bookmarkId: String, isMarked: Bool) async throws {
        toggleFavoriteCalled = true
        try result.get()
    }
    func markAsDeleted(bookmarkId: String) async throws { try result.get() }
    func updateReadProgress(bookmarkId: String, progress: Int, anchor: String?) async throws {
        updateProgressCalled = true
        lastProgressValue = progress
        try result.get()
    }
    func updateTitle(bookmarkId: String, title: String) async throws { try result.get() }
    func updateLabels(bookmarkId: String, labels: [String]) async throws { try result.get() }
    func addLabels(bookmarkId: String, labels: [String]) async throws { try result.get() }
    func removeLabels(bookmarkId: String, labels: [String]) async throws { try result.get() }
}

class ConfigurableDeleteBookmarkUseCase: PDeleteBookmarkUseCase {
    var result: Result<Void, Error> = .success(())
    var deleteCalled = false
    var lastDeletedId: String?

    func execute(bookmarkId: String) async throws {
        deleteCalled = true
        lastDeletedId = bookmarkId
        try result.get()
    }
}

class ConfigurableGetBookmarkUseCase: PGetBookmarkUseCase {
    var result: Result<BookmarkDetail, Error> = .success(
        BookmarkDetail(id: "123", title: "Test", url: "https://example.com", description: "Test", siteName: "Test", authors: ["Test"], created: "2021-01-01", updated: "2021-01-01", wordCount: 100, readingTime: 2, hasArticle: true, isMarked: false, isArchived: false, labels: [], thumbnailUrl: "", imageUrl: "", lang: "en", readProgress: 0)
    )

    func execute(id: String) async throws -> BookmarkDetail {
        return try result.get()
    }
}

class ConfigurableGetBookmarkArticleUseCase: PGetBookmarkArticleUseCase {
    var result: Result<String, Error> = .success("<p>Test article content</p>")

    func execute(id: String) async throws -> String {
        return try result.get()
    }
}

class ConfigurableLoginUseCase: PLoginUseCase {
    var result: Result<User, Error> = .success(User(id: "123", token: "abc"))
    var executeCalled = false

    func execute(endpoint: String, username: String, password: String) async throws -> User {
        executeCalled = true
        return try result.get()
    }
}

class ConfigurableCheckServerReachabilityUseCase: PCheckServerReachabilityUseCase {
    var isReachable: Bool = true
    var serverInfo: ServerInfo = ServerInfo(version: "1.0.0", isReachable: true, features: ["oauth"])

    func execute() async -> Bool { isReachable }
    func getServerInfo() async throws -> ServerInfo { serverInfo }
}

class ConfigurableCreateBookmarkUseCase: PCreateBookmarkUseCase {
    var result: Result<String, Error> = .success("new-bookmark-id")

    func execute(createRequest: CreateBookmarkRequest) async throws -> String { try result.get() }
    func createFromURL(_ url: String) async throws -> String { try result.get() }
    func createFromURLWithTitle(_ url: String, title: String) async throws -> String { try result.get() }
    func createFromURLWithLabels(_ url: String, labels: [String]) async throws -> String { try result.get() }
    func createFromClipboard() async throws -> String? { try result.get() }
}

// Simple test error
enum TestError: Error, Equatable {
    case networkError
    case unauthorized
    case serverUnreachable
}
```

- [ ] **Step 2: Create TestUseCaseFactory**

Create `readeckTests/Helpers/TestUseCaseFactory.swift` — a factory that holds references to the configurable mocks so tests can access and configure them.

```swift
import Foundation
import Combine
@testable import readeck

class TestUseCaseFactory: UseCaseFactory {
    // Configurable mocks — tests set these before creating ViewModels
    let mockGetBookmarks = ConfigurableGetBookmarksUseCase()
    let mockUpdateBookmark = ConfigurableUpdateBookmarkUseCase()
    let mockDeleteBookmark = ConfigurableDeleteBookmarkUseCase()
    let mockGetBookmark = ConfigurableGetBookmarkUseCase()
    let mockGetBookmarkArticle = ConfigurableGetBookmarkArticleUseCase()
    let mockLogin = ConfigurableLoginUseCase()
    let mockCheckReachability = ConfigurableCheckServerReachabilityUseCase()
    let mockCreateBookmark = ConfigurableCreateBookmarkUseCase()
    let mockSettingsRepository = MockSettingsRepository()

    // Passthrough mocks (non-configurable, just no-ops)
    func makeLoginUseCase() -> PLoginUseCase { mockLogin }
    func makeGetBookmarksUseCase() -> PGetBookmarksUseCase { mockGetBookmarks }
    func makeGetBookmarkUseCase() -> PGetBookmarkUseCase { mockGetBookmark }
    func makeGetBookmarkArticleUseCase() -> PGetBookmarkArticleUseCase { mockGetBookmarkArticle }
    func makeUpdateBookmarkUseCase() -> PUpdateBookmarkUseCase { mockUpdateBookmark }
    func makeDeleteBookmarkUseCase() -> PDeleteBookmarkUseCase { mockDeleteBookmark }
    func makeCreateBookmarkUseCase() -> PCreateBookmarkUseCase { mockCreateBookmark }
    func makeCheckServerReachabilityUseCase() -> PCheckServerReachabilityUseCase { mockCheckReachability }
    func makeGetServerInfoUseCase() -> PGetServerInfoUseCase { MockGetServerInfoUseCase() }

    // Non-configurable — use existing mocks from MockUseCaseFactory pattern
    func makeSaveSettingsUseCase() -> PSaveSettingsUseCase { MockSaveSettingsUseCase() }
    func makeLoadSettingsUseCase() -> PLoadSettingsUseCase { MockLoadSettingsUseCase() }
    func makeLogoutUseCase() -> PLogoutUseCase { MockLogoutUseCase() }
    func makeSearchBookmarksUseCase() -> PSearchBookmarksUseCase { MockSearchBookmarksUseCase() }
    func makeSaveServerSettingsUseCase() -> PSaveServerSettingsUseCase { MockSaveServerSettingsUseCase() }
    func makeAddLabelsToBookmarkUseCase() -> PAddLabelsToBookmarkUseCase { MockAddLabelsToBookmarkUseCase() }
    func makeRemoveLabelsFromBookmarkUseCase() -> PRemoveLabelsFromBookmarkUseCase { MockRemoveLabelsFromBookmarkUseCase() }
    func makeGetLabelsUseCase() -> PGetLabelsUseCase { MockGetLabelsUseCase() }
    func makeCreateLabelUseCase() -> PCreateLabelUseCase { MockCreateLabelUseCase() }
    func makeSyncTagsUseCase() -> PSyncTagsUseCase { MockSyncTagsUseCase() }
    func makeAddTextToSpeechQueueUseCase() -> PAddTextToSpeechQueueUseCase { MockAddTextToSpeechQueueUseCase() }
    func makeOfflineBookmarkSyncUseCase() -> POfflineBookmarkSyncUseCase { MockOfflineBookmarkSyncUseCase() }
    func makeLoadCardLayoutUseCase() -> PLoadCardLayoutUseCase { MockLoadCardLayoutUseCase() }
    func makeSaveCardLayoutUseCase() -> PSaveCardLayoutUseCase { MockSaveCardLayoutUseCase() }
    func makeGetBookmarkAnnotationsUseCase() -> PGetBookmarkAnnotationsUseCase { MockGetBookmarkAnnotationsUseCase() }
    func makeDeleteAnnotationUseCase() -> PDeleteAnnotationUseCase { MockDeleteAnnotationUseCase() }
    func makeSettingsRepository() -> PSettingsRepository { mockSettingsRepository }
    func makeOfflineCacheSyncUseCase() -> POfflineCacheSyncUseCase { MockOfflineCacheSyncUseCase() }
    func makeNetworkMonitorUseCase() -> PNetworkMonitorUseCase { MockNetworkMonitorUseCase() }
    func makeGetCachedBookmarksUseCase() -> PGetCachedBookmarksUseCase { MockGetCachedBookmarksUseCase() }
    func makeGetCachedArticleUseCase() -> PGetCachedArticleUseCase { MockGetCachedArticleUseCase() }
    func makeCreateAnnotationUseCase() -> PCreateAnnotationUseCase { MockCreateAnnotationUseCase() }
    func makeGetCacheSizeUseCase() -> PGetCacheSizeUseCase { MockGetCacheSizeUseCase() }
    func makeGetMaxCacheSizeUseCase() -> PGetMaxCacheSizeUseCase { MockGetMaxCacheSizeUseCase() }
    func makeUpdateMaxCacheSizeUseCase() -> PUpdateMaxCacheSizeUseCase { MockUpdateMaxCacheSizeUseCase() }
    func makeClearCacheUseCase() -> PClearCacheUseCase { MockClearCacheUseCase() }
    func makeLoginWithOAuthUseCase() -> PLoginWithOAuthUseCase { MockLoginWithOAuthUseCase() }
    func makeAuthRepository() -> PAuthRepository { MockAuthRepository() }
}
```

**Note:** `TestUseCaseFactory` reuses the existing `Mock*UseCase` classes from `readeck/UI/Factory/MockUseCaseFactory.swift` for non-critical paths. The `MockUseCaseFactory.swift` is in the **main app target** and thus accessible from the test target via `@testable import readeck`. Only the critical-path use cases get configurable versions.

- [ ] **Step 3: Verify test infrastructure compiles**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:readeckTests 2>&1 | tail -5`
Expected: Build succeeds (tests run)

- [ ] **Step 4: Commit**

```bash
git add readeckTests/Helpers/ConfigurableMocks.swift readeckTests/Helpers/TestUseCaseFactory.swift
git commit -m "test: add configurable mock use cases and test factory"
```

---

## Task 2: BookmarksViewModel Tests

**Files:**
- Create: `readeckTests/ViewModels/BookmarksViewModelTests.swift`
- Reference: `readeck/UI/Bookmarks/BookmarksViewModel.swift`
- Reference: `readeckTests/Helpers/TestUseCaseFactory.swift`

- [ ] **Step 1: Write BookmarksViewModel test suite**

Create `readeckTests/ViewModels/BookmarksViewModelTests.swift`:

```swift
import Testing
import Foundation
@testable import readeck

@Suite("BookmarksViewModel Tests")
@MainActor
struct BookmarksViewModelTests {

    private func createSUT() -> (BookmarksViewModel, TestUseCaseFactory) {
        let factory = TestUseCaseFactory()
        let vm = BookmarksViewModel(factory)
        return (vm, factory)
    }

    @Test("Load bookmarks populates list")
    func loadBookmarks() async {
        let (vm, factory) = createSUT()
        let testBookmarks = [Bookmark.mock]
        factory.mockGetBookmarks.result = .success(
            BookmarksPage(bookmarks: testBookmarks, currentPage: 1, totalCount: 1, totalPages: 1, links: nil)
        )

        await vm.loadBookmarks()

        #expect(vm.bookmarks?.bookmarks.count == 1)
        #expect(vm.bookmarks?.bookmarks.first?.id == "123")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("Load bookmarks with empty result shows empty state")
    func loadBookmarksEmpty() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .success(
            BookmarksPage(bookmarks: [], currentPage: 1, totalCount: 0, totalPages: 1, links: nil)
        )

        await vm.loadBookmarks()

        #expect(vm.bookmarks?.bookmarks.isEmpty == true)
        #expect(vm.errorMessage == nil)
    }

    @Test("Load bookmarks failure sets error state")
    func loadBookmarksError() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarks.result = .failure(TestError.networkError)

        await vm.loadBookmarks()

        #expect(vm.errorMessage != nil)
    }

    @Test("Toggle archive calls update use case")
    func toggleArchive() async {
        let (vm, factory) = createSUT()
        let bookmark = Bookmark.mock

        await vm.toggleArchive(bookmark: bookmark)

        #expect(factory.mockUpdateBookmark.toggleArchiveCalled == true)
    }

    @Test("Toggle favorite calls update use case")
    func toggleFavorite() async {
        let (vm, factory) = createSUT()
        let bookmark = Bookmark.mock

        await vm.toggleFavorite(bookmark: bookmark)

        #expect(factory.mockUpdateBookmark.toggleFavoriteCalled == true)
    }

    @Test("Delete bookmark calls delete use case")
    func deleteBookmark() async throws {
        let (vm, factory) = createSUT()
        let bookmark = Bookmark.mock

        // deleteBookmarkWithUndo uses a timer, so we test the direct path
        vm.deleteBookmarkWithUndo(bookmark: bookmark)

        // The pending delete should be tracked
        #expect(vm.pendingDeletes[bookmark.id] != nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:readeckTests/BookmarksViewModelTests 2>&1 | tail -20`
Expected: All tests pass. If any fail, adjust the test to match actual ViewModel behavior.

- [ ] **Step 3: Commit**

```bash
git add readeckTests/ViewModels/BookmarksViewModelTests.swift
git commit -m "test: add BookmarksViewModel unit tests"
```

---

## Task 3: BookmarkDetailViewModel Tests

**Files:**
- Create: `readeckTests/ViewModels/BookmarkDetailViewModelTests.swift`
- Reference: `readeck/UI/BookmarkDetail/BookmarkDetailViewModel.swift`

- [ ] **Step 1: Write BookmarkDetailViewModel test suite**

Create `readeckTests/ViewModels/BookmarkDetailViewModelTests.swift`:

```swift
import Testing
import Foundation
@testable import readeck

@Suite("BookmarkDetailViewModel Tests")
@MainActor
struct BookmarkDetailViewModelTests {

    private func createSUT() -> (BookmarkDetailViewModel, TestUseCaseFactory) {
        let factory = TestUseCaseFactory()
        let vm = BookmarkDetailViewModel(factory)
        return (vm, factory)
    }

    @Test("Load bookmark detail populates state")
    func loadBookmarkDetail() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmark.result = .success(
            BookmarkDetail(id: "1", title: "Test Article", url: "https://example.com", description: "Desc", siteName: "Example", authors: ["Author"], created: "2025-01-01", updated: "2025-01-01", wordCount: 500, readingTime: 3, hasArticle: true, isMarked: false, isArchived: false, labels: ["swift"], thumbnailUrl: "", imageUrl: "", lang: "en", readProgress: 42)
        )

        await vm.loadBookmarkDetail(id: "1")

        #expect(vm.bookmarkDetail.title == "Test Article")
        #expect(vm.bookmarkDetail.id == "1")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("Load bookmark detail failure sets error")
    func loadBookmarkDetailError() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmark.result = .failure(TestError.networkError)

        await vm.loadBookmarkDetail(id: "1")

        #expect(vm.errorMessage != nil)
    }

    @Test("Load article content populates articleContent")
    func loadArticleContent() async {
        let (vm, factory) = createSUT()
        factory.mockGetBookmarkArticle.result = .success("<p>Article body</p>")

        await vm.loadArticleContent(id: "1")

        #expect(vm.articleContent.contains("Article body"))
        #expect(vm.isLoadingArticle == false)
    }

    @Test("Archive bookmark calls update use case")
    func archiveBookmark() async {
        let (vm, factory) = createSUT()

        await vm.archiveBookmark(id: "1", isArchive: true)

        #expect(factory.mockUpdateBookmark.toggleArchiveCalled == true)
    }

    @Test("Update read progress calls use case with correct value")
    func updateReadProgress() async {
        let (vm, factory) = createSUT()

        await vm.updateReadProgress(id: "1", progress: 75, anchor: nil)

        #expect(factory.mockUpdateBookmark.updateProgressCalled == true)
        #expect(factory.mockUpdateBookmark.lastProgressValue == 75)
    }
}
```

- [ ] **Step 2: Run tests**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:readeckTests/BookmarkDetailViewModelTests 2>&1 | tail -20`
Expected: All pass

- [ ] **Step 3: Commit**

```bash
git add readeckTests/ViewModels/BookmarkDetailViewModelTests.swift
git commit -m "test: add BookmarkDetailViewModel unit tests"
```

---

## Task 4: AppViewModel Auth Tests

**Files:**
- Create: `readeckTests/ViewModels/AppViewModelTests.swift`
- Reference: `readeck/UI/AppViewModel.swift`

**Note:** `AppViewModel.handleUnauthorizedResponse()` is private and triggered via NotificationCenter (`.unauthorizedAPIResponse`). `checkServerReachability()` is also private, called from `onAppResume()`. We test through the public/internal API.

- [ ] **Step 1: Write AppViewModel test suite**

Create `readeckTests/ViewModels/AppViewModelTests.swift`:

```swift
import Testing
import Foundation
@testable import readeck

@Suite("AppViewModel Tests")
@MainActor
struct AppViewModelTests {

    @Test("Initial state has finished setup true")
    func initialState() {
        let factory = TestUseCaseFactory()
        let vm = AppViewModel(factory: factory)

        #expect(vm.hasFinishedSetup == true)
    }

    @Test("On app resume checks server reachability")
    func onAppResume() async {
        let factory = TestUseCaseFactory()
        factory.mockCheckReachability.isReachable = true
        let vm = AppViewModel(factory: factory)

        await vm.onAppResume()

        #expect(vm.isServerReachable == true)
    }

    @Test("Server unreachable sets isServerReachable to false")
    func serverUnreachable() async {
        let factory = TestUseCaseFactory()
        factory.mockCheckReachability.isReachable = false
        let vm = AppViewModel(factory: factory)

        await vm.onAppResume()

        #expect(vm.isServerReachable == false)
    }

    @Test("Unauthorized notification triggers logout and reloads setup status")
    func unauthorizedResponse() async throws {
        let factory = TestUseCaseFactory()
        let vm = AppViewModel(factory: factory)

        // After the notification fires, handleUnauthorizedResponse() calls
        // logout (no-op mock) then loadSetupStatus() which reads
        // settingsRepository.hasFinishedSetup. We set it to false BEFORE
        // posting, so when loadSetupStatus() runs it picks up the new value.
        factory.mockSettingsRepository.hasFinishedSetup = false

        NotificationCenter.default.post(name: .unauthorizedAPIResponse, object: nil)

        // Give the async handler time to process
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(vm.hasFinishedSetup == false)
    }
}
```

- [ ] **Step 2: Run tests and adjust**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:readeckTests/AppViewModelTests 2>&1 | tail -20`
Expected: Pass. The notification test may need timing adjustments — check `handleUnauthorizedResponse` behavior and adapt.

- [ ] **Step 3: Commit**

```bash
git add readeckTests/ViewModels/AppViewModelTests.swift
git commit -m "test: add AppViewModel auth and reachability tests"
```

---

## Task 5: Mapper Tests

**Files:**
- Create: `readeckTests/Mappers/BookmarkMapperTests.swift`
- Create: `readeckTests/Mappers/AnnotationMapperTests.swift`
- Reference: `readeck/Data/Mappers/BookmarkMapper.swift`
- Reference: `readeck/Data/Mappers/DtoMapper.swift`
- Reference: `readeck/Data/API/DTOs/` (DTO structs)

- [ ] **Step 1: Write BookmarkMapper test suite**

Create `readeckTests/Mappers/BookmarkMapperTests.swift`. First read the `BookmarkDto` struct and `BookmarkMapper.swift` to understand the exact field names and types, then write tests:

```swift
import Testing
import Foundation
@testable import readeck

@Suite("BookmarkMapper Tests")
struct BookmarkMapperTests {

    @Test("BookmarkDto maps all fields to domain correctly")
    func fullMapping() {
        // Construct a BookmarkDto with all fields populated
        // Call .toDomain()
        // Verify each field matches
        // NOTE: Check BookmarkDto init signature in readeck/Data/API/DTOs/ before writing
    }

    @Test("BookmarkDto with nil optional fields maps to sensible defaults")
    func nilFieldsMapping() {
        // Construct BookmarkDto with nil optionals
        // Verify defaults (empty strings, empty arrays, etc.)
    }

    @Test("BookmarksPageDto maps page metadata correctly")
    func pageMapping() {
        // Verify currentPage, totalCount, totalPages pass through
    }

    @Test("BookmarkLabelDto maps name and count")
    func labelMapping() {
        // Verify label name and count
    }

    @Test("Date strings are preserved through mapping")
    func dateMapping() {
        // Verify created/updated/published date strings pass through
    }
}
```

**Important:** Before writing the actual test bodies, read the `BookmarkDto` struct definition in `readeck/Data/API/DTOs/` to get the exact init signature. The code snippets above are outlines — fill in the actual `BookmarkDto(...)` constructors matching the real struct.

- [ ] **Step 2: Write AnnotationMapper test suite**

Create `readeckTests/Mappers/AnnotationMapperTests.swift`:

```swift
import Testing
import Foundation
@testable import readeck

@Suite("AnnotationMapper Tests")
struct AnnotationMapperTests {

    @Test("AnnotationDto maps to Annotation domain model")
    func annotationMapping() {
        // Construct AnnotationDto, call .toDomain(), verify fields
        // Check AnnotationDto in readeck/Data/API/DTOs/ for init signature
    }
}
```

- [ ] **Step 3: Run mapper tests**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:readeckTests/BookmarkMapperTests -only-testing:readeckTests/AnnotationMapperTests 2>&1 | tail -20`

- [ ] **Step 4: Commit**

```bash
git add readeckTests/Mappers/
git commit -m "test: add BookmarkMapper and AnnotationMapper tests"
```

---

## Task 6: ShareBookmarkViewModel — Assess Testability

**Files:**
- Reference: `URLShare/ShareBookmarkViewModel.swift`

**Note:** `ShareBookmarkViewModel` has hardcoded dependencies (`SimpleAPI.addBookmark`, `ShareExtensionServerCheck.shared`, `OfflineBookmarkManager.shared`, `KeychainHelper.shared`). These are not injectable, making it untestable without refactoring production code.

- [ ] **Step 1: Document testability gap**

The Share Extension ViewModel cannot be unit tested without a refactoring step to inject its dependencies. This is **out of scope** for the current testing effort to avoid touching production code.

What would be needed for future testability:
1. Extract a `ShareBookmarkSaving` protocol wrapping `SimpleAPI.addBookmark` and `OfflineBookmarkManager`
2. Extract a `ServerReachabilityChecking` protocol wrapping `ShareExtensionServerCheck`
3. Extract a `KeychainReading` protocol wrapping `KeychainHelper`
4. Accept these in `ShareBookmarkViewModel.init` with defaults pointing to real implementations

**Skip to Task 7.** Create a GitHub issue or TODO for this refactoring if desired.

- [ ] **Step 2: Commit spec update (if changes were made to spec)**

---

## Task 7: XCTest → Swift Testing Migration

**Files:**
- Modify: `readeckTests/Domain/EndpointValidatorTests.swift`
- Modify: `readeckTests/Domain/ServerInfoTests.swift`
- Modify: `readeckTests/OAuth/PKCEGeneratorTests.swift`
- Modify: `readeckTests/StringExtensionsTests.swift`

### Migration Pattern

For each file, apply this transformation:

| XCTest | Swift Testing |
|--------|--------------|
| `import XCTest` | `import Testing` |
| `final class FooTests: XCTestCase` | `@Suite("Foo Tests") struct FooTests` |
| `func testSomething()` | `@Test("Something") func something()` |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertTrue(x)` | `#expect(x)` |
| `XCTAssertFalse(x)` | `#expect(!x)` |
| `XCTAssertNil(x)` | `#expect(x == nil)` |
| `XCTAssertNotNil(x)` | `#expect(x != nil)` |
| `XCTAssertEqual(a, b, "msg")` | `#expect(a == b, "msg")` |
| `XCTAssertThrowsError` | `#expect(throws:)` |

- [ ] **Step 1: Migrate EndpointValidatorTests.swift**

Replace `import XCTest` with `import Testing`. Convert class to `@Suite struct`. Convert all `XCTAssert*` to `#expect`. Remove `test` prefix from method names, add `@Test("description")`.

This file has ~52 test methods. They are all simple `XCTAssertEqual(EndpointValidator.normalize(...), "expected")` patterns — straightforward mechanical migration.

- [ ] **Step 2: Run migrated EndpointValidator tests**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:readeckTests/EndpointValidatorTests 2>&1 | tail -20`
Expected: All 52 tests pass

- [ ] **Step 3: Migrate ServerInfoTests.swift**

Same mechanical migration. ~13 tests, all simple `XCTAssertTrue`/`XCTAssertFalse`/`XCTAssertEqual` on `ServerInfo` properties.

- [ ] **Step 4: Run migrated ServerInfo tests**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:readeckTests/ServerInfoTests 2>&1 | tail -20`

- [ ] **Step 5: Migrate PKCEGeneratorTests.swift**

~12 tests. Some use `CharacterSet` checks and loop assertions — convert `XCTAssertTrue` inside loops to `#expect`.

- [ ] **Step 6: Run migrated PKCE tests**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:readeckTests/PKCEGeneratorTests 2>&1 | tail -20`

- [ ] **Step 7: Migrate StringExtensionsTests.swift**

~12 tests. All simple `XCTAssertEqual(html.stripHTML, expected)` patterns.

- [ ] **Step 8: Run migrated StringExtensions tests**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:readeckTests/StringExtensionsTests 2>&1 | tail -20`

- [ ] **Step 9: Run all tests to verify nothing is broken**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:readeckTests 2>&1 | tail -30`
Expected: All tests pass (old + new + migrated)

- [ ] **Step 10: Commit**

```bash
git add readeckTests/Domain/EndpointValidatorTests.swift readeckTests/Domain/ServerInfoTests.swift readeckTests/OAuth/PKCEGeneratorTests.swift readeckTests/StringExtensionsTests.swift
git commit -m "refactor: migrate XCTest tests to Swift Testing framework"
```

---

## Summary

| Task | Tests | Type |
|------|-------|------|
| 1. Test Infrastructure | — | Setup |
| 2. BookmarksViewModel | ~6 | New |
| 3. BookmarkDetailViewModel | ~5 | New |
| 4. AppViewModel | ~4 | New |
| 5. Mapper Tests | ~5 | New |
| 6. ShareBookmarkViewModel | — | Skipped (needs refactoring) |
| 7. XCTest Migration | ~89 | Migrated |

**Total: ~20 new test cases + ~89 migrated = ~109 tests on Swift Testing**
