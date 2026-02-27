

Übermittelt: 30. Jan. 2026 um 21:03 Uhr
http (no tls) should be allowed for domains ending in .home.arpa as they are local network addresses under DNS propagation rules. These should be handled similarly to .local addresses. see rfc 8375 for details.

> **Analyse:** Sollte bereits funktionieren - `NSAllowsArbitraryLoads` und `NSAllowsLocalNetworking` sind in Info.plist aktiviert. Falls nicht: explizite Exception für `home.arpa` in NSExceptionDomains hinzufügen.

---------------

Übermittelt: 24. Dez. 2025 um 10:19 Uhr
Hi, First: thanks for making the app. I haven't played around with it extensively yet, but it looks and feels great, such an improvement over the web app! Thank you! I've installed the app on macOS Tahoe (macOS 26.2), and while it opens and connects without any issue, selecting any article from the list, the app will crash immediately (you can still catch a glimpse of the article appearing on the right hand side). TestFlight doesn't allow me to add crashdumps though. If you'd like to receve them, just let me know and I'll send them by mail.

> **Analyse:** 6 Crashes von einem User auf macOS 26.2. `#available(iOS 26.0, *)` gibt auch auf macOS 26 `true` zurück, aber NativeWebView crasht dort.
>
> **Fix:** `!ProcessInfo.processInfo.isiOSAppOnMac` zu den Checks hinzufügen:
> - `BookmarkDetailView.swift:11` → `if #available(iOS 26.0, *), !ProcessInfo.processInfo.isiOSAppOnMac {`
> - `BookmarkDetailLegacyView.swift:228` → gleicher Check (Toggle-Button verstecken)

---------------


Übermittelt: 23. Dez. 2025 um 19:11 Uhr
First of all, thanks for the amazing app. I was trying the text-to-speech in English articles, but for some reason it is reading in German, and if I change articles and try the text-to-speech, it just reads the first article again, and always in German. I was connected to a VPN in Germany the first time I tried, but after that I tried to close the app, refresh the cached offline articles but nothing seems to fix the issue.

> **Analyse:** Drei Probleme:
> 1. Hard-coded `"de-DE"` Default in `TTSManager.speak()` - Default-Parameter entfernen
> 2. `VoiceManager.getVoice()` hat auch `"de-DE"` Default - entfernen
> 3. `selectedVoice` überschreibt Spracherkennung auch wenn Sprache nicht passt - nur nutzen wenn Sprache-Prefix übereinstimmt
>
> **Fix in VoiceManager.swift:**
> ```swift
> func getVoice(for language: String) -> AVSpeechSynthesisVoice {
>     if let cachedVoice = cachedVoices[language] { return cachedVoice }
>     let langPrefix = String(language.prefix(2))
>     if let selected = selectedVoice, selected.language.hasPrefix(langPrefix) {
>         cachedVoices[language] = selected
>         return selected
>     }
>     // Beste Stimme für Sprache suchen...
> }
> ```

---------------

