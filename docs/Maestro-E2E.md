# Maestro E2E suite

A smoke suite that clicks through the main flows before a release, against the same demo Readeck server Apple's reviewers use (`https://readeck.mnk.any64.de`).

## Running it

```
scripts/e2e.sh
```

It builds the app, logs into the demo server, seeds a couple of throwaway bookmarks, runs every flow in `maestro/`, and deletes what it created again, even if a flow fails.

Requirements: Xcode command line tools, the [Maestro](https://github.com/mobile-dev-inc/maestro) CLI, a JDK (`brew install openjdk` if `java -version` fails), and the `asc` CLI configured with the `readeck` profile for credentials.

Override the demo credentials instead of going through `asc`:

```
READECK_E2E_USER=... READECK_E2E_PASSWORD=... scripts/e2e.sh
```

## How login works

The demo server only supports OAuth, and Maestro can't reliably drive the system web sheet `ASWebAuthenticationSession` opens.
`scripts/e2e.sh` runs the OAuth authorization code flow itself with `curl` (register a client, submit the login form, approve the consent screen, exchange the code), the same steps a human would go through, then launches the app with the resulting token as a Debug-only launch argument.
`E2ETestSupport` (in the app, compiled out of Release builds) picks it up before the first render and writes straight to the keychain, so every flow starts already logged in.
The OAuth login screen itself stays a manual device check, same as the Local Network prompt.
The access token never expires on its own (Readeck doesn't send `expires_in`), so `scripts/e2e.sh` revokes it via `/api/oauth/revoke` when it exits, even on failure.
The dynamically-registered OAuth client isn't revoked separately: Readeck only keeps client registrations in a 10-minute cache, not persisted storage, so they expire on their own.

## Test data

Every bookmark the suite creates, directly via the API or through the add-bookmark UI flow, is tagged with a label unique to that run (`e2e-<timestamp>-<pid>`), never the literal `e2e`.
This demo server is shared with other sessions and the App Store review team, so a fixed label would let two runs step on each other's cleanup.
The suite only ever touches bookmarks under its own label and deletes all of them when it exits.

## Flows

- `01_load_list` — a pre-authenticated launch lands on the bookmark list.
- `02_add_bookmark` — adds a bookmark through the UI, tags it for cleanup.
- `03_archive_does_not_drop_other_unread` — regression test for cb#39: archiving one unread bookmark used to make other unread bookmarks disappear until you left the tab and came back.
- `04_offline_article` — regression test for cb#45: enables offline reading, syncs, flips the debug-only "simulate offline" toggle, and opens whatever Preview Cached Articles lists, not a specific seeded bookmark, since the sync's own cap decides what gets cached on a server with this much existing content.
- `05_share_sheet` — opens the reader's share sheet and checks the options render. Doesn't follow through on an option, since that hands off to system UI Maestro can't drive.

Cancelling the share extension (cb#50) isn't covered yet: the fix for it hadn't merged when this suite was written.
Add a flow once it has.

## Notes for the next change

- A fresh install always shows a "What's New" sheet (`VersionManager`), so every flow dismisses it first via `releaseNotes.doneButton`.
- Tapping a `Toggle`'s accessibility identifier dead-center lands on its label text, not the switch: use `point: "90%,50%"` to hit the switch.
- The new iOS 26 tab bar's "Search" tab replaces the whole tab bar with a search field while active; the other tabs aren't reachable from there without leaving through a regular list screen first.
