# Delete option while reading — Design

**Issue:** [#46](https://github.com/ilyas-hallak/readeck-ios/issues/46) — Feature request: Delete option while reading
**Branch:** `feat/46-delete-while-reading`
**Date:** 2026-05-12

## Goal

Add a way to delete the currently open bookmark from inside the Reading View, so the user does not need to leave the article and use the list's swipe action.

## Scope

In scope:
- New "Delete" entry in the existing overflow menu (`ellipsis.circle`) of `ArticleReaderView`.
- Confirmation dialog before deletion.
- Disable the entry while offline.
- Navigate back to the bookmark list after a successful delete.
- Localization (en, de, Base).
- ViewModel unit tests.

Out of scope:
- Undo / soft delete.
- Offline queue for deletions.
- Bulk delete.
- Adding delete to the Floating Action Buttons.
- Changes to the list-side swipe action.

## UI

### Menu entry

`ArticleReaderView.toolbarContent` — append a new `Button(role: .destructive)` at the bottom of the existing `Menu`, after "Font Settings":

```
Button(role: .destructive) {
    showingDeleteConfirmation = true
} label: {
    Label("Delete".localized, systemImage: "trash")
}
.disabled(!isOnline)
```

- Placed last so accidental taps are unlikely.
- `.destructive` role renders red text on iOS.
- `isOnline` reuses whatever signal Archive/Favorite already use to gate online-only actions. If no such signal exists yet on this view, derive it from the existing reachability source used elsewhere in the app (verify during implementation; do not introduce a new mechanism).

### Confirmation dialog

Attached to `ArticleReaderView` via `.confirmationDialog`:

- Title: `"Delete this bookmark?"`
- Message: `"This action cannot be undone."`
- Destructive button: `"Delete"` → triggers `viewModel.deleteBookmark(id:)`
- Cancel button: `"Cancel"` (system default)

State: `@State private var showingDeleteConfirmation = false`

### After successful delete

- `@Environment(\.dismiss) private var dismiss` is called.
- The list refreshes via the same mechanism already used after archive/favorite changes (verify which one — likely a shared store/notification — during implementation; do not add a new refresh path).

### After failed delete

- ViewModel surfaces an error via its existing error-presentation pattern (verify how `archiveBookmark` reports errors and follow the same approach).
- The reader stays open so the user can retry.

## ViewModel

`BookmarkDetailViewModel` — add:

```
func deleteBookmark(id: String) async -> Bool
```

- Sets `isLoading = true` while running.
- Calls the existing `DeleteBookmarkUseCase` (already wired through `DefaultUseCaseFactory` and `MockUseCaseFactory`).
- Returns `true` on success so the view can `dismiss()`.
- On failure, sets the existing error state and returns `false`.

No new use case, repository method, or API call is needed — `DeleteBookmarkUseCase` and `BookmarksRepository.deleteBookmark` already exist and are used by the list swipe action.

## Localization

Add to `en.lproj`, `de.lproj`, `Base.lproj` `Localizable.strings` — only the keys that are not already present (verify first):

| Key | en | de |
|---|---|---|
| `Delete` | Delete | Löschen |
| `Delete this bookmark?` | Delete this bookmark? | Dieses Lesezeichen löschen? |
| `This action cannot be undone.` | This action cannot be undone. | Diese Aktion kann nicht rückgängig gemacht werden. |

`Cancel` is already localized app-wide — reuse it.

## Tests

Add to the existing `BookmarkDetailViewModel` test target (mirror the structure used for `BookmarksViewModelTests` delete tests):

1. `deleteBookmark` calls `DeleteBookmarkUseCase.execute` exactly once with the given id.
2. `deleteBookmark` returns `true` when the use case succeeds.
3. `deleteBookmark` returns `false` and sets the error state when the use case throws.

Use `MockUseCaseFactory` / `TestUseCaseFactory` as the rest of the suite does.

## Manual test checklist

- Online, tap Delete in menu → dialog appears → Cancel → reader stays open, nothing deleted.
- Online, Delete → Confirm → reader closes → bookmark is gone from list.
- Offline → Delete entry is greyed out / disabled, no tap action.
- Server returns error → reader stays open, error shown, bookmark still present.
- RTL / Dynamic Type: dialog and menu entry render correctly.

## Release notes

Append to `readeck/UI/Resources/RELEASE_NOTES.md` under the next version:

> Added a Delete option to the article reading view's menu, so you can remove the current article without going back to the list.
