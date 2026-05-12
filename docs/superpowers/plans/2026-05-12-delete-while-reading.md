# Delete option while reading — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a destructive "Delete" entry to the overflow menu of `ArticleReaderView` that, after confirmation, deletes the current bookmark via the existing `DeleteBookmarkUseCase` and returns the user to the bookmark list.

**Architecture:** Pure UI + ViewModel change. The `DeleteBookmarkUseCase`, repository, API method, and test mock all already exist (currently used by the swipe action in `BookmarksView`). We add a `deleteBookmark(id:)` method on `BookmarkDetailViewModel`, a confirmation dialog and menu entry in `ArticleReaderView` (gated by `AppSettings.isNetworkConnected`), a new `Notification.Name.bookmarkDeleted` so the bookmark list refreshes when the user lands back on it, and tests mirroring the existing `archiveBookmark` test patterns.

**Tech Stack:** Swift 5.9+, SwiftUI (iOS 26 deployment for this view), Swift Testing (`@Test`), `@Observable` view models.

**Worktree:** `/Users/ilyashallak/Privat/Projects/readeck-46`
**Branch:** `feat/46-delete-while-reading`
**Spec:** `docs/superpowers/specs/2026-05-12-delete-while-reading-design.md`

---

## File Structure

**Modify:**
- `readeck/UI/BookmarkDetail/BookmarkDetailViewModel.swift` — add `deleteBookmarkUseCase` dependency, `deleteBookmark(id:)` method.
- `readeck/UI/BookmarkDetail/ArticleReaderView.swift` — add menu entry, confirmation dialog, dismiss-on-success.
- `readeck/UI/Bookmarks/BookmarksViewModel.swift` — listen for new `.bookmarkDeleted` notification and refresh.
- `readeck/Utils/` or wherever `Notification.Name` extensions live — locate during Task 1 and add `bookmarkDeleted`.
- `readeck/Localizations/en.lproj/Localizable.strings` — add new keys.
- `readeck/Localizations/de.lproj/Localizable.strings` — add new keys.
- `readeck/Localizations/Base.lproj/Localizable.strings` — add new keys.
- `readeck/UI/Resources/RELEASE_NOTES.md` — append release note.

**Test:**
- `readeckTests/ViewModels/BookmarkDetailViewModelTests.swift` — add three tests.

No new files are created.

---

## Task 1: Locate Notification.Name extensions and confirm existing strings

This is reconnaissance; it produces no code commit but locks down two facts the later tasks depend on.

**Files:**
- Read: search for existing `Notification.Name` extensions

- [ ] **Step 1: Find the file that defines existing notification names**

Run:
```bash
cd /Users/ilyashallak/Privat/Projects/readeck-46
grep -rn "extension Notification.Name" readeck --include="*.swift"
```
Expected: at least one file listing names like `settingsChanged`, `addBookmarkFromShare`, `unauthorizedAPIResponse`. Note the file path — Task 5 will edit it.

- [ ] **Step 2: Confirm which localization keys already exist**

Run:
```bash
grep -nE '^"(Delete|Cancel|Delete this bookmark\?|This action cannot be undone\.)"' readeck/Localizations/en.lproj/Localizable.strings
```
Expected: `"Cancel"`, `"Delete"`, `"Delete Bookmark"` already present. `"Delete this bookmark?"` and `"This action cannot be undone."` are missing — Task 6 adds them. `"Delete"` and `"Cancel"` will be reused as-is.

No commit for this task.

---

## Task 2: Add a failing ViewModel test for the success path

**Files:**
- Modify: `readeckTests/ViewModels/BookmarkDetailViewModelTests.swift`

- [ ] **Step 1: Append the new test section at the end of the suite, before the closing brace**

Insert this block right after the existing `// MARK: - Archive Bookmark` test region (find the last `@Test` in the file, append after it, inside the `struct BookmarkDetailViewModelTests {` body):

```swift
    // MARK: - Delete Bookmark

    @Test("Delete bookmark calls use case and returns true on success")
    func deleteBookmarkSuccess() async {
        let (vm, factory) = createSUT()
        factory.mockDeleteBookmark.result = .success(())

        let success = await vm.deleteBookmark(id: "789")

        #expect(success == true)
        #expect(factory.mockDeleteBookmark.deleteCalled == true)
        #expect(factory.mockDeleteBookmark.lastDeletedId == "789")
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }
```

- [ ] **Step 2: Run the test to verify it fails to compile**

Run:
```bash
cd /Users/ilyashallak/Privat/Projects/readeck-46
xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:readeckTests/BookmarkDetailViewModelTests/deleteBookmarkSuccess 2>&1 | tail -40
```
Expected: BUILD FAILED, error: `value of type 'BookmarkDetailViewModel' has no member 'deleteBookmark'`.

No commit yet — failing tests are committed together with the implementation in Task 4.

---

## Task 3: Add failing ViewModel tests for failure and call-count

**Files:**
- Modify: `readeckTests/ViewModels/BookmarkDetailViewModelTests.swift`

- [ ] **Step 1: Append two more tests below the one added in Task 2**

```swift
    @Test("Delete bookmark returns false and sets error on failure")
    func deleteBookmarkFailure() async {
        let (vm, factory) = createSUT()
        factory.mockDeleteBookmark.result = .failure(TestError.networkError)

        let success = await vm.deleteBookmark(id: "789")

        #expect(success == false)
        #expect(vm.errorMessage == "Error deleting bookmark")
        #expect(vm.isLoading == false)
    }

    @Test("Delete bookmark posts bookmarkDeleted notification on success")
    func deleteBookmarkPostsNotification() async {
        let (vm, factory) = createSUT()
        factory.mockDeleteBookmark.result = .success(())

        var receivedId: String?
        let observer = NotificationCenter.default.addObserver(
            forName: .bookmarkDeleted,
            object: nil,
            queue: .main
        ) { notification in
            receivedId = notification.userInfo?["id"] as? String
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        _ = await vm.deleteBookmark(id: "789")

        // Give the main queue a tick to deliver the notification
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(receivedId == "789")
    }
```

- [ ] **Step 2: Confirm the build still fails the same way**

Run:
```bash
xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:readeckTests/BookmarkDetailViewModelTests 2>&1 | tail -20
```
Expected: BUILD FAILED, errors about `deleteBookmark` member and `bookmarkDeleted` notification name. Both will be resolved in Tasks 4 and 5.

No commit yet.

---

## Task 4: Implement `deleteBookmark` on `BookmarkDetailViewModel`

**Files:**
- Modify: `readeck/UI/BookmarkDetail/BookmarkDetailViewModel.swift`

- [ ] **Step 1: Add the use case property in the dependency list**

In `BookmarkDetailViewModel.swift`, find the private dependency declarations near the top of the class (around line 6-13). Add a new line after `getBookmarkAnnotationsUseCase`:

```swift
    private let deleteBookmarkUseCase: PDeleteBookmarkUseCase
```

- [ ] **Step 2: Wire it up in `init`**

In the `init(_ factory:)` body (around line 48), add this line after `getBookmarkAnnotationsUseCase` assignment and before `self.factory = factory`:

```swift
        self.deleteBookmarkUseCase = factory.makeDeleteBookmarkUseCase()
```

- [ ] **Step 3: Add the `deleteBookmark` method**

Insert this method after the existing `archiveBookmark(id:isArchive:)` method (around line 203):

```swift
    @MainActor
    func deleteBookmark(id: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            try await deleteBookmarkUseCase.execute(bookmarkId: id)
            isLoading = false
            NotificationCenter.default.post(
                name: .bookmarkDeleted,
                object: nil,
                userInfo: ["id": id]
            )
            return true
        } catch {
            errorMessage = "Error deleting bookmark"
            isLoading = false
            return false
        }
    }
```

- [ ] **Step 4: Build will still fail — `bookmarkDeleted` is undefined**

Run:
```bash
xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1 | tail -10
```
Expected: error `type 'Notification.Name' has no member 'bookmarkDeleted'`. Task 5 fixes this.

No commit yet.

---

## Task 5: Add the `bookmarkDeleted` notification name and make the bookmarks list listen

**Files:**
- Modify: file located in Task 1 that extends `Notification.Name`
- Modify: `readeck/UI/Bookmarks/BookmarksViewModel.swift`

- [ ] **Step 1: Add the new notification name**

In the file located in Task 1 (the `extension Notification.Name { … }` block), add:

```swift
    static let bookmarkDeleted = Notification.Name("bookmarkDeleted")
```

Place it alphabetically or with the other bookmark-related names — match the surrounding style.

- [ ] **Step 2: Make BookmarksViewModel refresh on delete**

In `readeck/UI/Bookmarks/BookmarksViewModel.swift`, find the existing `NotificationCenter.default.publisher(for: .settingsChanged)` block around line 78. Right after that `.store(in: &cancellables)` line (around line 85), add:

```swift
        // Refresh when a bookmark is deleted from the reading view
        NotificationCenter.default
            .publisher(for: .bookmarkDeleted)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshBookmarks()
                }
            }
            .store(in: &cancellables)
```

- [ ] **Step 3: Build and run the new tests**

Run:
```bash
cd /Users/ilyashallak/Privat/Projects/readeck-46
xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:readeckTests/BookmarkDetailViewModelTests 2>&1 | tail -30
```
Expected: all three new tests (`deleteBookmarkSuccess`, `deleteBookmarkFailure`, `deleteBookmarkPostsNotification`) pass, and existing tests still pass.

- [ ] **Step 4: Commit the ViewModel + notification + tests**

```bash
git add readeck/UI/BookmarkDetail/BookmarkDetailViewModel.swift \
        readeck/UI/Bookmarks/BookmarksViewModel.swift \
        readeckTests/ViewModels/BookmarkDetailViewModelTests.swift
# also add the file from Task 1 where Notification.Name was extended
git add <notification-names-file-from-task-1>
git commit -m "feat(reader): add deleteBookmark to BookmarkDetailViewModel (#46)"
```

---

## Task 6: Add localization strings

**Files:**
- Modify: `readeck/Localizations/en.lproj/Localizable.strings`
- Modify: `readeck/Localizations/de.lproj/Localizable.strings`
- Modify: `readeck/Localizations/Base.lproj/Localizable.strings`

- [ ] **Step 1: Append to `en.lproj/Localizable.strings`**

Add at an appropriate alphabetical location (or at the end if the file is not alphabetized — match the file's existing convention):

```
"Delete this bookmark?" = "Delete this bookmark?";
"This action cannot be undone." = "This action cannot be undone.";
```

- [ ] **Step 2: Append to `de.lproj/Localizable.strings`**

```
"Delete this bookmark?" = "Dieses Lesezeichen löschen?";
"This action cannot be undone." = "Diese Aktion kann nicht rückgängig gemacht werden.";
```

- [ ] **Step 3: Append to `Base.lproj/Localizable.strings`**

```
"Delete this bookmark?" = "Delete this bookmark?";
"This action cannot be undone." = "This action cannot be undone.";
```

- [ ] **Step 4: Commit**

```bash
git add readeck/Localizations/en.lproj/Localizable.strings \
        readeck/Localizations/de.lproj/Localizable.strings \
        readeck/Localizations/Base.lproj/Localizable.strings
git commit -m "i18n: add delete confirmation strings (#46)"
```

---

## Task 7: Add the Delete entry and confirmation dialog to `ArticleReaderView`

**Files:**
- Modify: `readeck/UI/BookmarkDetail/ArticleReaderView.swift`

- [ ] **Step 1: Add new state for the confirmation dialog**

In the `// MARK: - States` block of `ArticleReaderView` (around lines 11-23), add this line after `@State private var showingImageViewer = false`:

```swift
    @State private var showingDeleteConfirmation = false
```

- [ ] **Step 2: Add the destructive menu entry**

In the `toolbarContent` computed property (around line 218-249), find the `Menu { … }` block. After the final `Button { showingFontSettings = true }` (the "Font Settings" entry, ending around line 244), add:

```swift
                Divider()

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete".localized, systemImage: "trash")
                }
                .disabled(!appSettings.isNetworkConnected)
```

The `Divider()` visually separates the destructive action from the regular ones.

- [ ] **Step 3: Attach the confirmation dialog to `mainView`**

In `mainView` (around lines 43-?), the chain currently ends with several `.sheet(...)` modifiers and `.toolbar(...)`. Find the last modifier before `.background(...)` is applied in `body` and append (still inside `mainView`'s modifier chain, after the existing `.sheet` modifiers):

```swift
            .confirmationDialog(
                "Delete this bookmark?".localized,
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete".localized, role: .destructive) {
                    Task {
                        let success = await viewModel.deleteBookmark(id: bookmarkId)
                        if success {
                            dismiss()
                        }
                    }
                }
                Button("Cancel".localized, role: .cancel) {}
            } message: {
                Text("This action cannot be undone.".localized)
            }
```

- [ ] **Step 4: Verify the build**

Run:
```bash
xcodebuild build -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1 | tail -10
```
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Run the full test suite to catch regressions**

Run:
```bash
xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1 | tail -20
```
Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add readeck/UI/BookmarkDetail/ArticleReaderView.swift
git commit -m "feat(reader): add delete option with confirmation to reading view (#46)"
```

---

## Task 8: Add release note

**Files:**
- Modify: `readeck/UI/Resources/RELEASE_NOTES.md`

- [ ] **Step 1: Read the current top of the release notes to match style**

Run:
```bash
head -30 /Users/ilyashallak/Privat/Projects/readeck-46/readeck/UI/Resources/RELEASE_NOTES.md
```
Note the format (version heading style, bullet style).

- [ ] **Step 2: Add an entry under the next unreleased / current version section**

Match the existing bullet style. Use this content:

```
- Added a Delete option to the article reading view's menu, so you can remove the current article without going back to the list.
```

If the file has no "unreleased" section, create one at the top following the existing version-heading convention (look at the most recent version block as a template).

- [ ] **Step 3: Commit**

```bash
git add readeck/UI/Resources/RELEASE_NOTES.md
git commit -m "docs: add release note for delete-while-reading (#46)"
```

---

## Task 9: Manual verification on the simulator

This task does not change code; it confirms the feature works end-to-end before handing off to the user for review.

- [ ] **Step 1: Run the app on the iOS 26 simulator**

Open Xcode, select an iOS 26 simulator, run the app, log into a test Readeck instance.

- [ ] **Step 2: Online — happy path**

Open any bookmark in the reader → tap the `…` menu → confirm "Delete" appears in red at the bottom with a trash icon → tap it → confirmation dialog appears → tap "Cancel" → reader stays open, nothing changes.

- [ ] **Step 3: Online — actual delete**

Repeat the menu open → tap Delete → tap "Delete" in the dialog → reader closes → bookmark list is shown and the deleted bookmark is gone.

- [ ] **Step 4: Offline**

Enable airplane mode in the simulator (or stop the Readeck server) so `appSettings.isNetworkConnected` becomes false. Open a cached article → open the menu → confirm "Delete" entry is greyed out and not tappable.

- [ ] **Step 5: Server-side error**

If feasible (e.g., delete the bookmark on the server first via the web UI, then try to delete it from the reader), confirm: confirmation dialog → Delete → reader stays open, `errorMessage` is set. The exact surfacing depends on the existing error pattern; document any rough edges to discuss in the user review.

- [ ] **Step 6: Notes**

Note anything that needs polish (alignment, copy, animation) — bring these to the user review step rather than fixing speculatively.

No commit.

---

## Self-Review Result

- **Spec coverage:** menu placement ✓ (Task 7), confirmation dialog ✓ (Task 7), disabled when offline ✓ (Task 7), dismiss on success ✓ (Task 7), list refresh after delete ✓ (Tasks 4-5 via notification), localization ✓ (Task 6), ViewModel method ✓ (Task 4), tests ✓ (Tasks 2-3), release note ✓ (Task 8), manual checklist ✓ (Task 9).
- **Placeholder scan:** the only deferred decision is the exact filename of the `Notification.Name` extension (resolved in Task 1, used in Task 5). No TBDs.
- **Type consistency:** `deleteBookmark(id:) -> Bool` is the signature used in both the test (Task 2-3) and the implementation (Task 4) and is invoked the same way from the view (Task 7). `Notification.Name.bookmarkDeleted` is declared in Task 5 and used in Tasks 4 and 5.
