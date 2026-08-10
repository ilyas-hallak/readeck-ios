# readeck-ios — Ticket- & PR-Stand

_Stand: 2026-07-18 · Remotes: GitHub `ilyas-hallak/readeck-ios` (`hub`), Codeberg `readeck/readeck-ios` (`origin`)_

## 🔀 Pull Requests

- [ ] **GitHub #56** — OAuth-Fix (client re-registration + `client_uri`) + archive-to-next-article Navigation
  - Autor: bakerboy448 · mergeable · 13 Dateien (+231/-39)
  - ⚠️ „untested proof-of-concept" — nur CI, nie auf Gerät/Simulator gelaufen → vor Merge auf Device testen

## 🐛 Issues — GitHub

- [ ] **#57** App Store Build: server URL not properly updating
- [ ] **#55** Feature: Next item after archiving/deleting _(≈ Codeberg #41, adressiert von PR #56)_
- [ ] **#52** 2.1 not connecting to Readeck 0.22.3
- [ ] **#49** Very Long Articles Fail to Render in Reader View
- [ ] **#30** Option to disable rubberband scrolling
- [ ] **#20** Offline Sync fails on iPad `bug`
- [ ] **#17** Feature: Automated tagging `Feature`
- [ ] **#9** Feature: iCloud sync of server settings `Feature`
- [ ] **#3** Feature: select multiple articles for further operations `Feature`

## 🐛 Issues — Codeberg

- [ ] **#41** Feature: close reader & return to list after archiving _(≈ GitHub #55)_
- [ ] **#40** Feature: App-icon badge mit Unread-Count _(3 Kommentare)_
- [ ] **#39** Unread articles disappear when archiving unread article _(1 Kommentar)_
- [ ] **#38** Support larger font sizes / iOS dynamic text _(2 Kommentare)_
- [ ] **#1** French translation _(4 Kommentare)_

## 🔎 Cluster / Zusammenhänge

- [ ] **Verbindung & Auth:** GH #57 (server URL), GH #52 (2.1 ↔ 0.22.3), PR #56 (OAuth) — evtl. gemeinsame Ursache
- [ ] **Archivieren-Verhalten:** GH #55 ≈ CB #41 (nächster Artikel), CB #39 / GH #20 (unread/Sync) — verwandt
- [ ] 🔐 GitHub-Token in Remote-URL rotieren + Remote ohne eingebetteten Token neu setzen
