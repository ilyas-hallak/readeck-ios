# Font System Erweiterung - Konzept & Implementierungsplan

**Datum:** 5. Dezember 2025
**Status:** Geplant
**Ziel:** Erweiterte Font-Auswahl mit 10 hochwertigen Schriftarten für bessere Lesbarkeit

---

## 📋 Übersicht

### Aktuelle Situation (4 Fonts)
- ❌ **System:** SF Pro (Apple)
- ❌ **Serif:** Times New Roman (veraltet)
- ❌ **Sans Serif:** Helvetica Neue (Standard)
- ❌ **Monospace:** Menlo (Apple)

### Neue Situation (10 Fonts)
- ✅ **4 Apple System Fonts** (bereits in iOS enthalten, 0 KB)
- ✅ **6 Google Fonts** (OFL 1.1 lizenziert, ~1.5 MB)

---

## 🎯 Ziele

1. **Bessere Lesbarkeit**: Moderne, für Langform-Texte optimierte Schriftarten
2. **Konsistenz**: Matching mit Readeck Web-UI (Literata, Source Serif, etc.)
3. **Sprachunterstützung**: Exzellenter Support für internationale Zeichen
4. **100% Legal**: Alle Fonts sind frei verwendbar (Apple proprietär für iOS, Google OFL 1.1)

---

## 📚 Font-Übersicht (10 Fonts Total)

### Serif Fonts (4 Schriftarten)

#### 1. **New York** (Apple System Font) ⭐
- **Quelle:** In iOS 13+ enthalten
- **Lizenz:** Apple proprietär (frei für iOS Apps)
- **Eigenschaften:**
  - 6 Gewichte
  - Variable optische Größen
  - Unterstützt Latin, Greek, Cyrillic
  - Wird in Apple Books und News verwendet
- **Verwendung:** Premium Serif für Apple-native Ästhetik
- **App-Größe:** 0 KB (bereits in iOS)

#### 2. **Literata** (Google Font) ⭐
- **Quelle:** [GitHub - googlefonts/literata](https://github.com/googlefonts/literata)
- **Google Fonts:** [fonts.google.com/specimen/Literata](https://fonts.google.com/specimen/Literata)
- **Lizenz:** SIL Open Font License 1.1
- **Designer:** TypeTogether (für Google)
- **Eigenschaften:**
  - Standard-Font von Google Play Books
  - Speziell für digitales Lesen entwickelt
  - Variable Font mit optischen Größen
- **Verwendung:** **Readeck Web-UI Match** - Hauptschrift für Artikel
- **App-Größe:** ~250-350 KB

#### 3. **Merriweather** (Google Font)
- **Quelle:** [GitHub - SorkinType/Merriweather](https://github.com/SorkinType/Merriweather)
- **Google Fonts:** [fonts.google.com/specimen/Merriweather](https://fonts.google.com/specimen/Merriweather)
- **Lizenz:** SIL Open Font License 1.1
- **Designer:** Sorkin Type Co
- **Eigenschaften:**
  - Designed für Bildschirme
  - 8 Gewichte (Light bis Black)
  - Sehr gute Lesbarkeit bei kleinen Größen
- **Verwendung:** **Readeck Web-UI Match** - Alternative Serif
- **App-Größe:** ~200-300 KB

#### 4. **Source Serif** (Adobe/Google Font)
- **Quelle:** [GitHub - adobe-fonts/source-serif](https://github.com/adobe-fonts/source-serif)
- **Google Fonts:** [fonts.google.com/specimen/Source+Serif+4](https://fonts.google.com/specimen/Source+Serif+4)
- **Lizenz:** SIL Open Font License 1.1
- **Designer:** Adobe (Frank Grießhammer)
- **Eigenschaften:**
  - Adobe's drittes Open-Source-Projekt
  - Companion zu Source Sans
  - Variable Font (Source Serif 4)
  - Professionelle, klare Serif
- **Verwendung:** **Readeck Web-UI Match** - Adobe-Qualität
- **App-Größe:** ~250-350 KB

---

### Sans Serif Fonts (5 Schriftarten)

#### 5. **SF Pro** (San Francisco - Apple System Font) ⭐
- **Quelle:** In iOS enthalten
- **Lizenz:** Apple proprietär (frei für iOS Apps)
- **Eigenschaften:**
  - iOS Standard System Font
  - 9 Gewichte
  - Variable Widths (Condensed, Compressed, Expanded)
  - Unterstützt 150+ Sprachen
  - Dynamic optical sizes
- **Verwendung:** Standard UI Font
- **App-Größe:** 0 KB (bereits in iOS)

#### 6. **Avenir Next** (Apple System Font) ⭐
- **Quelle:** In iOS enthalten
- **Lizenz:** Apple proprietär (frei für iOS Apps)
- **Eigenschaften:**
  - Moderne geometrische Sans
  - 12 Gewichte
  - Sehr beliebt (Apple Marketing)
  - Optimiert für Lesbarkeit
- **Verwendung:** Premium Sans für moderne Ästhetik
- **App-Größe:** 0 KB (bereits in iOS)

#### 7. **Lato** (Google Font)
- **Quelle:** [GitHub - latofonts/lato-source](https://github.com/latofonts/lato-source)
- **Google Fonts:** [fonts.google.com/specimen/Lato](https://fonts.google.com/specimen/Lato)
- **Lizenz:** SIL Open Font License 1.1
- **Designer:** Łukasz Dziedzic
- **Eigenschaften:**
  - Eine der beliebtesten Google Fonts
  - 9 Gewichte (Thin bis Black)
  - "Lato" = Polnisch für "Sommer"
  - Warm, freundlich, stabil
- **Verwendung:** Beliebte, universelle Sans
- **App-Größe:** ~200-300 KB

#### 8. **Montserrat** (Google Font)
- **Quelle:** [GitHub - JulietaUla/Montserrat](https://github.com/JulietaUla/Montserrat)
- **Google Fonts:** [fonts.google.com/specimen/Montserrat](https://fonts.google.com/specimen/Montserrat)
- **Lizenz:** SIL Open Font License 1.1
- **Designer:** Julieta Ulanovsky
- **Eigenschaften:**
  - Inspiriert von urbaner Typografie Buenos Aires
  - 18 Styles (9 Gewichte × 2)
  - Variable Font verfügbar
  - Geometric Sans
- **Verwendung:** Moderne, geometrische Sans
- **App-Größe:** ~200-300 KB

#### 9. **Nunito Sans** (Google Font)
- **Quelle:** [GitHub - googlefonts/nunito](https://github.com/googlefonts/nunito)
- **Google Fonts:** [fonts.google.com/specimen/Nunito+Sans](https://fonts.google.com/specimen/Nunito+Sans)
- **Lizenz:** SIL Open Font License 1.1
- **Designer:** Vernon Adams, Cyreal, Jacques Le Bailly
- **Eigenschaften:**
  - Balanced, humanistische Sans
  - Variable Font
  - 14 Styles
  - Freundlich, gut lesbar
- **Verwendung:** Humanistische Alternative
- **App-Größe:** ~200-300 KB

#### 10. **Source Sans** (Adobe/Google Font)
- **Quelle:** [GitHub - adobe-fonts/source-sans](https://github.com/adobe-fonts/source-sans)
- **Google Fonts:** [fonts.google.com/specimen/Source+Sans+3](https://fonts.google.com/specimen/Source+Sans+3)
- **Lizenz:** SIL Open Font License 1.1
- **Designer:** Adobe (Paul D. Hunt)
- **Eigenschaften:**
  - Adobe's **erstes** Open-Source-Projekt
  - Variable Font (Source Sans 3)
  - 12 Gewichte
  - Professionelle UI-Font
- **Verwendung:** **Readeck Web-UI Match** - Adobe-Qualität
- **App-Größe:** ~250-350 KB

---

### Monospace Font (1 Schriftart)

#### 11. **SF Mono** (Apple System Font)
- **Quelle:** In iOS enthalten
- **Lizenz:** Apple proprietär (frei für iOS Apps)
- **Eigenschaften:**
  - Xcode Standard-Font
  - 6 Gewichte
  - Optimiert für Code
  - Unterstützt Latin, Greek, Cyrillic
- **Verwendung:** Code-Darstellung, technische Inhalte
- **App-Größe:** 0 KB (bereits in iOS)

---

## 📥 Download & Installation

### Schritt 1: Google Fonts herunterladen

**Empfohlene Quelle: Google Fonts Website**
1. Besuche [fonts.google.com](https://fonts.google.com)
2. Suche nach jedem Font
3. Klicke "Download family"
4. Entpacke die `.ttf` oder `.otf` Dateien

**Alternative: GitHub Repos (für neueste Versionen)**
```bash
# Lora
git clone https://github.com/cyrealtype/Lora-Cyrillic.git

# Literata
git clone https://github.com/googlefonts/literata.git

# Merriweather
git clone https://github.com/SorkinType/Merriweather.git

# Source Serif
git clone https://github.com/adobe-fonts/source-serif.git

# Lato
git clone https://github.com/latofonts/lato-source.git

# Montserrat
git clone https://github.com/JulietaUla/Montserrat.git

# Nunito Sans
git clone https://github.com/googlefonts/nunito.git

# Source Sans
git clone https://github.com/adobe-fonts/source-sans.git
```

### Schritt 2: Fonts zu Xcode hinzufügen

1. Erstelle Ordner in Xcode: `readeck/Resources/Fonts/`
2. Füge `.ttf` oder `.otf` Dateien hinzu (Drag & Drop)
3. Stelle sicher: **"Add to targets: readeck"** ist aktiviert
4. Wähle für jeden Font nur **1-2 Gewichte** (Regular + Bold), um App-Größe zu minimieren

**Empfohlene Gewichte:**
- **Regular** (400): Fließtext
- **Bold** (700): Überschriften, Hervorhebungen

### Schritt 3: Info.plist konfigurieren

Füge zu `Info.plist` hinzu:
```xml
<key>UIAppFonts</key>
<array>
    <!-- Lora -->
    <string>Lora-Regular.ttf</string>
    <string>Lora-Bold.ttf</string>

    <!-- Literata -->
    <string>Literata-Regular.ttf</string>
    <string>Literata-Bold.ttf</string>

    <!-- Merriweather -->
    <string>Merriweather-Regular.ttf</string>
    <string>Merriweather-Bold.ttf</string>

    <!-- Source Serif -->
    <string>SourceSerif4-Regular.ttf</string>
    <string>SourceSerif4-Bold.ttf</string>

    <!-- Lato -->
    <string>Lato-Regular.ttf</string>
    <string>Lato-Bold.ttf</string>

    <!-- Montserrat -->
    <string>Montserrat-Regular.ttf</string>
    <string>Montserrat-Bold.ttf</string>

    <!-- Nunito Sans -->
    <string>NunitoSans-Regular.ttf</string>
    <string>NunitoSans-Bold.ttf</string>

    <!-- Source Sans -->
    <string>SourceSans3-Regular.ttf</string>
    <string>SourceSans3-Bold.ttf</string>
</array>
```

**Hinweis:** Exakte Dateinamen können variieren - prüfe nach Download!

---

## 💻 Code-Implementierung

### Schritt 4: FontFamily.swift erweitern

**Aktuell:**
```swift
enum FontFamily: String, CaseIterable {
    case system = "system"
    case serif = "serif"
    case sansSerif = "sansSerif"
    case monospace = "monospace"
}
```

**Neu:**
```swift
enum FontFamily: String, CaseIterable {
    // Apple System Fonts
    case system = "system"           // SF Pro
    case newYork = "newYork"         // New York
    case monospace = "monospace"     // SF Mono

    // Google Serif Fonts
    case lora = "lora"
    case literata = "literata"
    case merriweather = "merriweather"
    case sourceSerif = "sourceSerif"

    // Google Sans Serif Fonts
    case lato = "lato"
    case montserrat = "montserrat"
    case nunitoSans = "nunitoSans"
    case sourceSans = "sourceSans"

    var displayName: String {
        switch self {
        // Apple
        case .system: return "SF Pro"
        case .newYork: return "New York"
        case .monospace: return "SF Mono"

        // Serif
        case .lora: return "Lora"
        case .literata: return "Literata"
        case .merriweather: return "Merriweather"
        case .sourceSerif: return "Source Serif"

        // Sans Serif
        case .lato: return "Lato"
        case .montserrat: return "Montserrat"
        case .nunitoSans: return "Nunito Sans"
        case .sourceSans: return "Source Sans"
        }
    }

    var category: FontCategory {
        switch self {
        case .system, .lato, .montserrat, .nunitoSans, .sourceSans:
            return .sansSerif
        case .newYork, .lora, .literata, .merriweather, .sourceSerif:
            return .serif
        case .monospace:
            return .monospace
        }
    }
}

enum FontCategory {
    case serif
    case sansSerif
    case monospace
}
```

### Schritt 5: FontSettingsViewModel.swift erweitern

```swift
var previewTitleFont: Font {
    let size = selectedFontSize.size

    switch selectedFontFamily {
    // Apple System Fonts
    case .system:
        return Font.system(size: size).weight(.semibold)
    case .newYork:
        return Font.system(size: size, design: .serif).weight(.semibold)
    case .monospace:
        return Font.system(size: size, design: .monospaced).weight(.semibold)

    // Google Serif Fonts
    case .lora:
        return Font.custom("Lora-Bold", size: size)
    case .literata:
        return Font.custom("Literata-Bold", size: size)
    case .merriweather:
        return Font.custom("Merriweather-Bold", size: size)
    case .sourceSerif:
        return Font.custom("SourceSerif4-Bold", size: size)

    // Google Sans Serif Fonts
    case .lato:
        return Font.custom("Lato-Bold", size: size)
    case .montserrat:
        return Font.custom("Montserrat-Bold", size: size)
    case .nunitoSans:
        return Font.custom("NunitoSans-Bold", size: size)
    case .sourceSans:
        return Font.custom("SourceSans3-Bold", size: size)
    }
}

var previewBodyFont: Font {
    let size = selectedFontSize.size

    switch selectedFontFamily {
    // Apple System Fonts
    case .system:
        return Font.system(size: size)
    case .newYork:
        return Font.system(size: size, design: .serif)
    case .monospace:
        return Font.system(size: size, design: .monospaced)

    // Google Serif Fonts
    case .lora:
        return Font.custom("Lora-Regular", size: size)
    case .literata:
        return Font.custom("Literata-Regular", size: size)
    case .merriweather:
        return Font.custom("Merriweather-Regular", size: size)
    case .sourceSerif:
        return Font.custom("SourceSerif4-Regular", size: size)

    // Google Sans Serif Fonts
    case .lato:
        return Font.custom("Lato-Regular", size: size)
    case .montserrat:
        return Font.custom("Montserrat-Regular", size: size)
    case .nunitoSans:
        return Font.custom("NunitoSans-Regular", size: size)
    case .sourceSans:
        return Font.custom("SourceSans3-Regular", size: size)
    }
}
```

**Wichtig:** Font-Namen müssen **exakt** mit PostScript-Namen übereinstimmen!

### Schritt 6: PostScript Font-Namen ermitteln

Nach dem Import der Fonts, teste mit:
```swift
// In einer View, temporär hinzufügen:
let _ = print("Available fonts:")
for family in UIFont.familyNames.sorted() {
    let names = UIFont.fontNames(forFamilyName: family)
    print("Family: \(family) - Names: \(names)")
}
```

Suche nach den exakten Namen wie `Lora-Regular`, `Literata-Bold`, etc.

### Schritt 7: FontSelectionView.swift optimieren (Optional)

Gruppiere Fonts nach Kategorie:
```swift
Section {
    Picker("Font family", selection: $viewModel.selectedFontFamily) {
        // Apple System Fonts
        Text("SF Pro").tag(FontFamily.system)
        Text("New York").tag(FontFamily.newYork)

        Divider()

        // Serif Fonts
        ForEach([FontFamily.lora, .literata, .merriweather, .sourceSerif], id: \.self) { font in
            Text(font.displayName).tag(font)
        }

        Divider()

        // Sans Serif Fonts
        ForEach([FontFamily.lato, .montserrat, .nunitoSans, .sourceSans], id: \.self) { font in
            Text(font.displayName).tag(font)
        }

        Divider()

        // Monospace
        Text("SF Mono").tag(FontFamily.monospace)
    }
}
```

---

## 📊 App-Größen-Kalkulation

### Font-Datei-Größen (Schätzung)

| Font | Regular | Bold | Total |
|------|---------|------|-------|
| Lora | 150 KB | 150 KB | 300 KB |
| Literata | 180 KB | 180 KB | 360 KB |
| Merriweather | 140 KB | 140 KB | 280 KB |
| Source Serif | 160 KB | 160 KB | 320 KB |
| Lato | 130 KB | 130 KB | 260 KB |
| Montserrat | 140 KB | 140 KB | 280 KB |
| Nunito Sans | 150 KB | 150 KB | 300 KB |
| Source Sans | 150 KB | 150 KB | 300 KB |
| **TOTAL** | | | **~2.4 MB** |

**Optimierung:**
- Verwende **Variable Fonts** (1 Datei statt 2): ~40% Ersparnis
- Oder nur **Regular** Gewicht: ~50% Ersparnis (aber weniger Flexibilität)

**Empfohlene Konfiguration:**
- Variable Fonts wo verfügbar → **~1.5 MB**
- Oder Regular + Bold → **~2.4 MB**

---

## ✅ Implementierungs-Checkliste

### Phase 1: Vorbereitung
- [ ] Google Fonts von fonts.google.com oder GitHub herunterladen
- [ ] Font-Dateien organisieren (1 Ordner pro Font-Familie)
- [ ] Gewichte auswählen (Regular + Bold empfohlen)

### Phase 2: Xcode Integration
- [ ] Ordner `readeck/Resources/Fonts/` erstellen
- [ ] Font-Dateien zu Xcode hinzufügen (Target: readeck)
- [ ] `Info.plist` mit `UIAppFonts` aktualisieren
- [ ] Build testen (Fonts müssen kopiert werden)

### Phase 3: Code-Änderungen
- [ ] `FontFamily.swift` erweitern (11 cases)
- [ ] `FontCategory` enum hinzufügen
- [ ] `displayName` und `category` Properties implementieren
- [ ] `FontSettingsViewModel.swift` aktualisieren:
  - [ ] `previewTitleFont` erweitern
  - [ ] `previewBodyFont` erweitern
  - [ ] `previewCaptionFont` erweitern

### Phase 4: Testing & Validierung
- [ ] PostScript Font-Namen validieren (mit UIFont.familyNames)
- [ ] Alle 11 Fonts in Preview testen
- [ ] Font-Wechsel in Settings testen
- [ ] Font-Persistenz testen (nach App-Neustart)
- [ ] Prüfen: Werden Fonts korrekt in Bookmark-Detail angezeigt?

### Phase 5: UI-Verbesserungen (Optional)
- [ ] `FontSelectionView.swift` mit Gruppierung erweitern
- [ ] Font-Preview für jede Schrift hinzufügen
- [ ] "Readeck Web Match" Badge für Literata, Merriweather, Source Sans

### Phase 6: Dokumentation
- [ ] App Store Release Notes aktualisieren
- [ ] `RELEASE_NOTES.md` erweitern
- [ ] User-facing Font-Namen auf Deutsch übersetzen (optional)

---

## 🔍 PostScript Font-Namen (Nach Installation zu prüfen)

**Diese Namen können variieren!** Nach Import prüfen mit `UIFont.familyNames`:

| Font | Family Name | Regular | Bold |
|------|-------------|---------|------|
| Lora | Lora | Lora-Regular | Lora-Bold |
| Literata | Literata | Literata-Regular | Literata-Bold |
| Merriweather | Merriweather | Merriweather-Regular | Merriweather-Bold |
| Source Serif | Source Serif 4 | SourceSerif4-Regular | SourceSerif4-Bold |
| Lato | Lato | Lato-Regular | Lato-Bold |
| Montserrat | Montserrat | Montserrat-Regular | Montserrat-Bold |
| Nunito Sans | Nunito Sans | NunitoSans-Regular | NunitoSans-Bold |
| Source Sans | Source Sans 3 | SourceSans3-Regular | SourceSans3-Bold |

---

## 📝 Lizenz-Compliance

### SIL Open Font License 1.1 - Zusammenfassung

**Erlaubt:**
✅ Privater Gebrauch
✅ Kommerzieller Gebrauch
✅ Modifikation
✅ Distribution (embedded in App)
✅ Verkauf der App im AppStore

**Verboten:**
❌ Verkauf der Fonts als standalone Produkt

**Pflichten:**
- Copyright-Notice beibehalten (in Font-Dateien bereits enthalten)
- Lizenz-Text beifügen (optional in App, aber empfohlen)

### Attribution (Optional, aber empfohlen)

Füge zu "Settings → About → Licenses" oder ähnlich hinzu:

```
This app uses the following open-source fonts:

- Lora by Cyreal (SIL OFL 1.1)
- Literata by TypeTogether for Google (SIL OFL 1.1)
- Merriweather by Sorkin Type (SIL OFL 1.1)
- Source Serif by Adobe (SIL OFL 1.1)
- Lato by Łukasz Dziedzic (SIL OFL 1.1)
- Montserrat by Julieta Ulanovsky (SIL OFL 1.1)
- Nunito Sans by Vernon Adams, Cyreal (SIL OFL 1.1)
- Source Sans by Adobe (SIL OFL 1.1)

Full license: https://scripts.sil.org/OFL
```

---

## 🎨 Design-Empfehlungen

### Font-Pairings für Readeck

**Für Artikel (Reading Mode):**
- **Primär:** Literata (matches Readeck Web)
- **Alternativ:** Merriweather, Lora, Source Serif

**Für UI-Elemente:**
- **Primär:** SF Pro (nativer iOS Look)
- **Alternativ:** Source Sans (matches Readeck Web)

**Für Code/Technisch:**
- **Monospace:** SF Mono

### Default-Font-Einstellung

Vorschlag für neue Nutzer:
```swift
// In Settings Model
var defaultFontFamily: FontFamily = .literata  // Matches Readeck Web
var defaultFontSize: FontSize = .medium
```

---

## 🚀 Migration & Rollout

### Bestehende Nutzer

**Problem:** User haben aktuell `.serif` (Times New Roman) gesetzt

**Lösung:** Migration in `SettingsRepository`:
```swift
func migrateOldFontSettings() async throws {
    guard let settings = try await loadSettings() else { return }

    // Alte Fonts auf neue mapping
    var newFontFamily = settings.fontFamily
    switch settings.fontFamily {
    case .serif:
        newFontFamily = .literata  // Upgrade zu besserer Serif
    case .sansSerif:
        newFontFamily = .sourceSans  // Upgrade zu besserer Sans
    default:
        break  // .system, .monospace bleiben
    }

    if newFontFamily != settings.fontFamily {
        try await saveSettings(fontFamily: newFontFamily, fontSize: settings.fontSize)
    }
}
```

### Release Notes

```markdown
## Font System Upgrade 🎨

- **11 hochwertige Schriftarten** für besseres Lesen
- **Konsistenz** mit Readeck Web-UI
- **Serif-Fonts:** New York, Lora, Literata, Merriweather, Source Serif
- **Sans-Serif-Fonts:** SF Pro, Lato, Montserrat, Nunito Sans, Source Sans
- **Monospace:** SF Mono

Alle Fonts sind optimiert für digitales Lesen und unterstützen
internationale Zeichen.
```

---

## 📚 Referenzen

### Offizielle Font-Repositories

**Google Fonts:**
- Alle Fonts: https://fonts.google.com

**Adobe Open Source:**
- Source Serif: https://github.com/adobe-fonts/source-serif
- Source Sans: https://github.com/adobe-fonts/source-sans

**Apple Developer:**
- SF Fonts: https://developer.apple.com/fonts/
- Typography Guidelines: https://developer.apple.com/design/human-interface-guidelines/typography

### SIL Open Font License
- Lizenz-Text: https://scripts.sil.org/OFL
- FAQ: https://scripts.sil.org/OFL-FAQ_web

### SwiftUI Font-Dokumentation
- Custom Fonts: https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text
- Font Design: https://developer.apple.com/documentation/swiftui/font/design

---

## 🎯 Nächste Schritte

1. **Download Google Fonts** (von fonts.google.com)
2. **Font-Dateien auswählen** (Regular + Bold empfohlen)
3. **Zu Xcode hinzufügen** (readeck/Resources/Fonts/)
4. **Info.plist konfigurieren** (UIAppFonts)
5. **Code implementieren** (siehe oben)
6. **Testen & Validieren**
7. **Release**

---

**Geschätzte Implementierungszeit:** 2-3 Stunden
**App-Größen-Erhöhung:** ~1.5-2.4 MB
**User-Benefit:** Deutlich bessere Lesbarkeit & Readeck-Konsistenz ✨
