# Custom CSS Help View — Design Spec

**Issue:** #27 (Better and more granular custom theming/styling)
**Scope:** Custom CSS Hilfeseite mit kopierbaren Snippets
**Branch:** `feature/granular-reader-styling` (bestehendes Feature erweitern)

## Zusammenfassung

Die bestehende Custom CSS Section in den Reader Settings bekommt eine In-App Hilfeseite. Über einen "?" Button neben der Section-Überschrift öffnet sich ein Sheet mit einer kompakten, kategorisierten Liste von CSS-Snippets. Jedes Snippet hat zwei Buttons: "Anhängen" (ans Ende des bestehenden CSS) und "Ersetzen" (überschreibt das gesamte CSS-Feld).

## Datenmodell

```swift
struct CSSSnippet: Identifiable {
    let id = UUID()
    let titleKey: String          // Localization key
    let descriptionKey: String    // Localization key
    let code: String              // CSS code (nicht lokalisiert)
    let category: CSSSnippetCategory
}

enum CSSSnippetCategory: String, CaseIterable {
    case typography
    case colors
    case layout
    case visibility

    var titleKey: String { ... }  // Localization key
    var iconName: String { ... }  // SF Symbol
}
```

Snippets werden als statische Liste in einer Extension auf `CSSSnippet` definiert.

## Snippet-Katalog

### Typografie
| Snippet | CSS |
|---------|-----|
| Schriftgröße | `body { font-size: 20px; }` |
| Zeilenabstand | `body { line-height: 2.0; }` |
| Überschriften kleiner | `h1, h2, h3 { font-size: calc(var(--base-font-size) * 1.1); }` |
| Fettdruck für Absätze | `p { font-weight: 500; }` |

### Farben
| Snippet | CSS |
|---------|-----|
| Hintergrundfarbe (Sepia) | `:root { --background-color: #f4ecd8; --text-color: #5b4636; }` |
| Linkfarbe ändern | `:root { --link-color: #e74c3c; }` |
| Überschriftenfarbe | `:root { --heading-color: #2c3e50; }` |
| Zitat-Farbe | `:root { --quote-color: #888888; --quote-border: #cccccc; }` |

### Layout
| Snippet | CSS |
|---------|-----|
| Seitenränder verkleinern | `body { padding-left: 8px; padding-right: 8px; }` |
| Seitenränder vergrößern | `body { padding-left: 32px; padding-right: 32px; }` |
| Bilder kleiner | `img { max-width: 60%; margin: 8px auto; display: block; }` |
| Absatzabstand verkleinern | `p { margin-bottom: 8px; }` |

### Elemente ausblenden
| Snippet | CSS |
|---------|-----|
| Bilder ausblenden | `img { display: none; }` |
| Horizontale Linien ausblenden | `hr { display: none; }` |
| Links ohne Unterstrich | `a { text-decoration: none !important; }` |
| Blockquotes schlicht | `blockquote { border: none; background: none; padding: 0; font-style: normal; }` |

## UI-Struktur

### FontSettingsView — Custom CSS Section (angepasst)

```
Custom CSS    [? Button]        ← ? öffnet Sheet
┌─────────────────────────┐
│ TextEditor (monospace)  │
└─────────────────────────┘
"Custom CSS wird nach den Standard-Styles angehängt."
```

Der "?" Button ist ein `Button` mit `Image(systemName: "questionmark.circle")` in der Section Header HStack.

### CustomCSSHelpView (Sheet)

```
╔══════════════════════════════════╗
║  CSS Hilfe                       ║
╠══════════════════════════════════╣
║                                  ║
║  Aa TYPOGRAFIE                   ║
║  ┌────────────────────────────┐  ║
║  │ Schriftgröße               │  ║
║  │ Ändert die Textgröße       │  ║
║  │ ┌────────────────────────┐ │  ║
║  │ │ body { font-size: 20px │ │  ║
║  │ │ }                      │ │  ║
║  │ └────────────────────────┘ │  ║
║  │  [Anhängen]   [Ersetzen]  │  ║
║  └────────────────────────────┘  ║
║  ┌────────────────────────────┐  ║
║  │ Zeilenabstand              │  ║
║  │ ...                        │  ║
║  └────────────────────────────┘  ║
║                                  ║
║  🎨 FARBEN                       ║
║  ...                             ║
╚══════════════════════════════════╝
```

Jede Snippet-Karte:
- **Titel** (bold)
- **Beschreibung** (caption, secondary color)
- **Code-Block** (monospaced, grauer Hintergrund, abgerundete Ecken)
- **Zwei Buttons** in einem HStack: "Anhängen" (.bordered) und "Ersetzen" (.bordered, .destructive-ish Tint)

### Datenfluss

1. `CustomCSSHelpView` erhält `Binding<String>` auf `viewModel.customCSS`
2. "Anhängen" → `customCSS += "\n" + snippet.code`
3. "Ersetzen" → `customCSS = snippet.code`
4. Sheet bleibt offen für weitere Snippets
5. Bestehender `onChange(of: viewModel.customCSS)` speichert automatisch

## Lokalisierung

Alle UI-Strings (Titel, Beschreibungen, Kategorie-Labels, Button-Texte) werden über `Localizable.strings` in DE und EN bereitgestellt. CSS-Code bleibt unübersetzt.

Keys folgen dem Schema:
- `css.help.title` → "CSS Help" / "CSS Hilfe"
- `css.help.category.typography` → "Typography" / "Typografie"
- `css.snippet.fontSize.title` → "Font size" / "Schriftgröße"
- `css.snippet.fontSize.description` → "Change the text size" / "Ändert die Textgröße"
- `css.help.button.append` → "Append" / "Anhängen"
- `css.help.button.replace` → "Replace" / "Ersetzen"

## Neue Dateien

| Datei | Beschreibung |
|-------|-------------|
| `readeck/UI/Settings/CustomCSSHelpView.swift` | Sheet View mit Snippet-Liste |
| `readeck/Domain/Model/CSSSnippet.swift` | Datenmodell + statischer Snippet-Katalog |

## Geänderte Dateien

| Datei | Änderung |
|-------|---------|
| `readeck/UI/Settings/FontSettingsView.swift` | "?" Button in Custom CSS Section Header, Sheet-Binding |
| `Localizable.strings` (EN) | Neue Keys für Hilfe-View |
| `Localizable.strings` (DE) | Neue Keys für Hilfe-View |

## Nicht im Scope

- Kein Live-Preview der Snippets vor dem Übernehmen
- Keine Suchfunktion in der Hilfe-View
- Keine benutzerdefinierten Snippets (nur vordefinierte)
- Keine Änderungen an der CSS-Injection-Logik in WebView.swift
