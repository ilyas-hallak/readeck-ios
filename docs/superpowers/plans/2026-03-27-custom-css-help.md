# Custom CSS Help View — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an in-app help sheet to the Custom CSS section in Reader Settings, showing categorized CSS snippets users can append or replace into their custom CSS field.

**Architecture:** A static `CSSSnippet` model defines the snippet catalog. A new `CustomCSSHelpView` presents them as a sheet, receiving a `Binding<String>` to the custom CSS field. The existing `FontSettingsView` gets a "?" button that triggers the sheet.

**Tech Stack:** SwiftUI, Localization via `Localizable.strings` (EN + DE)

**Base Branch:** `feature/granular-reader-styling`

---

### Task 1: Create CSSSnippet Data Model

**Files:**
- Create: `readeck/Domain/Model/CSSSnippet.swift`

- [ ] **Step 1: Create the CSSSnippet model and category enum**

```swift
//
//  CSSSnippet.swift
//  readeck
//

import Foundation

enum CSSSnippetCategory: String, CaseIterable {
    case typography
    case colors
    case layout
    case visibility

    var titleKey: String {
        switch self {
        case .typography: return "css.help.category.typography"
        case .colors: return "css.help.category.colors"
        case .layout: return "css.help.category.layout"
        case .visibility: return "css.help.category.visibility"
        }
    }

    var iconName: String {
        switch self {
        case .typography: return "textformat.size"
        case .colors: return "paintpalette"
        case .layout: return "rectangle.split.3x1"
        case .visibility: return "eye.slash"
        }
    }
}

struct CSSSnippet: Identifiable {
    let id = UUID()
    let titleKey: String
    let descriptionKey: String
    let code: String
    let category: CSSSnippetCategory
}
```

- [ ] **Step 2: Add the static snippet catalog**

```swift
extension CSSSnippet {
    static let all: [CSSSnippet] = [
        // MARK: - Typography
        CSSSnippet(
            titleKey: "css.snippet.fontSize.title",
            descriptionKey: "css.snippet.fontSize.description",
            code: "body { font-size: 20px; }",
            category: .typography
        ),
        CSSSnippet(
            titleKey: "css.snippet.lineHeight.title",
            descriptionKey: "css.snippet.lineHeight.description",
            code: "body { line-height: 2.0; }",
            category: .typography
        ),
        CSSSnippet(
            titleKey: "css.snippet.headingsSmaller.title",
            descriptionKey: "css.snippet.headingsSmaller.description",
            code: "h1, h2, h3 { font-size: calc(var(--base-font-size) * 1.1); }",
            category: .typography
        ),
        CSSSnippet(
            titleKey: "css.snippet.boldParagraphs.title",
            descriptionKey: "css.snippet.boldParagraphs.description",
            code: "p { font-weight: 500; }",
            category: .typography
        ),

        // MARK: - Colors
        CSSSnippet(
            titleKey: "css.snippet.sepia.title",
            descriptionKey: "css.snippet.sepia.description",
            code: ":root { --background-color: #f4ecd8; --text-color: #5b4636; }",
            category: .colors
        ),
        CSSSnippet(
            titleKey: "css.snippet.linkColor.title",
            descriptionKey: "css.snippet.linkColor.description",
            code: ":root { --link-color: #e74c3c; }",
            category: .colors
        ),
        CSSSnippet(
            titleKey: "css.snippet.headingColor.title",
            descriptionKey: "css.snippet.headingColor.description",
            code: ":root { --heading-color: #2c3e50; }",
            category: .colors
        ),
        CSSSnippet(
            titleKey: "css.snippet.quoteColor.title",
            descriptionKey: "css.snippet.quoteColor.description",
            code: ":root { --quote-color: #888888; --quote-border: #cccccc; }",
            category: .colors
        ),

        // MARK: - Layout
        CSSSnippet(
            titleKey: "css.snippet.marginsSmall.title",
            descriptionKey: "css.snippet.marginsSmall.description",
            code: "body { padding-left: 8px; padding-right: 8px; }",
            category: .layout
        ),
        CSSSnippet(
            titleKey: "css.snippet.marginsLarge.title",
            descriptionKey: "css.snippet.marginsLarge.description",
            code: "body { padding-left: 32px; padding-right: 32px; }",
            category: .layout
        ),
        CSSSnippet(
            titleKey: "css.snippet.imagesSmaller.title",
            descriptionKey: "css.snippet.imagesSmaller.description",
            code: "img { max-width: 60%; margin: 8px auto; display: block; }",
            category: .layout
        ),
        CSSSnippet(
            titleKey: "css.snippet.paragraphSpacing.title",
            descriptionKey: "css.snippet.paragraphSpacing.description",
            code: "p { margin-bottom: 8px; }",
            category: .layout
        ),

        // MARK: - Visibility
        CSSSnippet(
            titleKey: "css.snippet.hideImages.title",
            descriptionKey: "css.snippet.hideImages.description",
            code: "img { display: none; }",
            category: .visibility
        ),
        CSSSnippet(
            titleKey: "css.snippet.hideHR.title",
            descriptionKey: "css.snippet.hideHR.description",
            code: "hr { display: none; }",
            category: .visibility
        ),
        CSSSnippet(
            titleKey: "css.snippet.linksPlain.title",
            descriptionKey: "css.snippet.linksPlain.description",
            code: "a { text-decoration: none !important; }",
            category: .visibility
        ),
        CSSSnippet(
            titleKey: "css.snippet.blockquotePlain.title",
            descriptionKey: "css.snippet.blockquotePlain.description",
            code: "blockquote { border: none; background: none; padding: 0; font-style: normal; }",
            category: .visibility
        ),
    ]

    static func snippets(for category: CSSSnippetCategory) -> [CSSSnippet] {
        all.filter { $0.category == category }
    }
}
```

- [ ] **Step 3: Verify it compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add readeck/Domain/Model/CSSSnippet.swift
git commit -m "feat: add CSSSnippet data model with snippet catalog"
```

---

### Task 2: Create CustomCSSHelpView

**Files:**
- Create: `readeck/UI/Settings/CustomCSSHelpView.swift`

- [ ] **Step 1: Create the help view**

```swift
//
//  CustomCSSHelpView.swift
//  readeck
//

import SwiftUI

struct CustomCSSHelpView: View {
    @Binding var customCSS: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(CSSSnippetCategory.allCases, id: \.self) { category in
                    Section {
                        ForEach(CSSSnippet.snippets(for: category)) { snippet in
                            snippetCard(snippet)
                        }
                    } header: {
                        Label(category.titleKey.localized, systemImage: category.iconName)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("css.help.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func snippetCard(_ snippet: CSSSnippet) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(snippet.titleKey.localized)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(snippet.descriptionKey.localized)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(snippet.code)
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(6)

            HStack(spacing: 12) {
                Button {
                    if customCSS.isEmpty {
                        customCSS = snippet.code
                    } else {
                        customCSS += "\n" + snippet.code
                    }
                } label: {
                    Label("css.help.button.append".localized, systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)

                Button {
                    customCSS = snippet.code
                } label: {
                    Label("css.help.button.replace".localized, systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add readeck/UI/Settings/CustomCSSHelpView.swift
git commit -m "feat: add CustomCSSHelpView with snippet cards"
```

---

### Task 3: Add "?" Button to FontSettingsView

**Files:**
- Modify: `readeck/UI/Settings/FontSettingsView.swift` (Custom CSS Section, approx. lines 125-140)

- [ ] **Step 1: Add sheet state and modify the Custom CSS section header**

Add a `@State private var showCSSHelp = false` property to `FontSettingsView`.

Replace the existing Custom CSS section:

```swift
// BEFORE:
Section {
    TextEditor(text: $viewModel.customCSS)
        .font(.system(.caption, design: .monospaced))
        .frame(minHeight: 100)
        .onChange(of: viewModel.customCSS) {
            Task { await viewModel.saveCustomCSS() }
        }
    Text("Custom CSS rules appended after all default styles. Use at your own risk.")
        .font(.caption)
        .foregroundColor(.secondary)
} header: {
    Text("Custom CSS")
}

// AFTER:
Section {
    TextEditor(text: $viewModel.customCSS)
        .font(.system(.caption, design: .monospaced))
        .frame(minHeight: 100)
        .onChange(of: viewModel.customCSS) {
            Task { await viewModel.saveCustomCSS() }
        }
    Text("css.help.hint".localized)
        .font(.caption)
        .foregroundColor(.secondary)
} header: {
    HStack {
        Text("Custom CSS")
        Spacer()
        Button {
            showCSSHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.subheadline)
        }
    }
}
.sheet(isPresented: $showCSSHelp) {
    CustomCSSHelpView(customCSS: $viewModel.customCSS)
}
```

- [ ] **Step 2: Verify it compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add readeck/UI/Settings/FontSettingsView.swift
git commit -m "feat: add help button to Custom CSS section"
```

---

### Task 4: Add Localization Strings (EN + DE)

**Files:**
- Modify: `readeck/Localizations/en.lproj/Localizable.strings`
- Modify: `readeck/Localizations/de.lproj/Localizable.strings`

- [ ] **Step 1: Add English localization strings**

Append to `readeck/Localizations/en.lproj/Localizable.strings`:

```
/* Custom CSS Help */
"css.help.title" = "CSS Help";
"css.help.hint" = "Custom CSS rules are appended after all default styles.";
"css.help.button.append" = "Append";
"css.help.button.replace" = "Replace";

/* CSS Help Categories */
"css.help.category.typography" = "Typography";
"css.help.category.colors" = "Colors";
"css.help.category.layout" = "Layout";
"css.help.category.visibility" = "Visibility";

/* CSS Snippets - Typography */
"css.snippet.fontSize.title" = "Font Size";
"css.snippet.fontSize.description" = "Change the base text size";
"css.snippet.lineHeight.title" = "Line Height";
"css.snippet.lineHeight.description" = "Adjust spacing between lines";
"css.snippet.headingsSmaller.title" = "Smaller Headings";
"css.snippet.headingsSmaller.description" = "Reduce heading sizes";
"css.snippet.boldParagraphs.title" = "Bolder Text";
"css.snippet.boldParagraphs.description" = "Increase paragraph font weight";

/* CSS Snippets - Colors */
"css.snippet.sepia.title" = "Sepia Theme";
"css.snippet.sepia.description" = "Warm, paper-like background with dark brown text";
"css.snippet.linkColor.title" = "Link Color";
"css.snippet.linkColor.description" = "Change the color of links";
"css.snippet.headingColor.title" = "Heading Color";
"css.snippet.headingColor.description" = "Change the color of headings";
"css.snippet.quoteColor.title" = "Quote Style";
"css.snippet.quoteColor.description" = "Change blockquote text and border color";

/* CSS Snippets - Layout */
"css.snippet.marginsSmall.title" = "Narrow Margins";
"css.snippet.marginsSmall.description" = "Reduce side margins for more text space";
"css.snippet.marginsLarge.title" = "Wide Margins";
"css.snippet.marginsLarge.description" = "Increase side margins for a focused column";
"css.snippet.imagesSmaller.title" = "Smaller Images";
"css.snippet.imagesSmaller.description" = "Reduce image size and center them";
"css.snippet.paragraphSpacing.title" = "Compact Paragraphs";
"css.snippet.paragraphSpacing.description" = "Reduce spacing between paragraphs";

/* CSS Snippets - Visibility */
"css.snippet.hideImages.title" = "Hide Images";
"css.snippet.hideImages.description" = "Remove all images from the article";
"css.snippet.hideHR.title" = "Hide Dividers";
"css.snippet.hideHR.description" = "Remove horizontal rule separators";
"css.snippet.linksPlain.title" = "Plain Links";
"css.snippet.linksPlain.description" = "Remove underline decoration from links";
"css.snippet.blockquotePlain.title" = "Plain Blockquotes";
"css.snippet.blockquotePlain.description" = "Remove border, background and italic from quotes";
```

- [ ] **Step 2: Add German localization strings**

Append to `readeck/Localizations/de.lproj/Localizable.strings`:

```
/* Custom CSS Hilfe */
"css.help.title" = "CSS Hilfe";
"css.help.hint" = "Eigenes CSS wird nach den Standard-Styles angehängt.";
"css.help.button.append" = "Anhängen";
"css.help.button.replace" = "Ersetzen";

/* CSS Hilfe Kategorien */
"css.help.category.typography" = "Typografie";
"css.help.category.colors" = "Farben";
"css.help.category.layout" = "Layout";
"css.help.category.visibility" = "Sichtbarkeit";

/* CSS Snippets - Typografie */
"css.snippet.fontSize.title" = "Schriftgröße";
"css.snippet.fontSize.description" = "Ändert die Textgröße";
"css.snippet.lineHeight.title" = "Zeilenabstand";
"css.snippet.lineHeight.description" = "Abstand zwischen Zeilen anpassen";
"css.snippet.headingsSmaller.title" = "Kleinere Überschriften";
"css.snippet.headingsSmaller.description" = "Überschriften verkleinern";
"css.snippet.boldParagraphs.title" = "Fetterer Text";
"css.snippet.boldParagraphs.description" = "Schriftstärke der Absätze erhöhen";

/* CSS Snippets - Farben */
"css.snippet.sepia.title" = "Sepia-Thema";
"css.snippet.sepia.description" = "Warmer, papierartiger Hintergrund mit dunkelbraunem Text";
"css.snippet.linkColor.title" = "Linkfarbe";
"css.snippet.linkColor.description" = "Farbe der Links ändern";
"css.snippet.headingColor.title" = "Überschriftenfarbe";
"css.snippet.headingColor.description" = "Farbe der Überschriften ändern";
"css.snippet.quoteColor.title" = "Zitat-Stil";
"css.snippet.quoteColor.description" = "Text- und Rahmenfarbe von Zitaten ändern";

/* CSS Snippets - Layout */
"css.snippet.marginsSmall.title" = "Schmale Ränder";
"css.snippet.marginsSmall.description" = "Seitenränder verkleinern für mehr Textfläche";
"css.snippet.marginsLarge.title" = "Breite Ränder";
"css.snippet.marginsLarge.description" = "Seitenränder vergrößern für eine fokussierte Spalte";
"css.snippet.imagesSmaller.title" = "Kleinere Bilder";
"css.snippet.imagesSmaller.description" = "Bilder verkleinern und zentrieren";
"css.snippet.paragraphSpacing.title" = "Kompakte Absätze";
"css.snippet.paragraphSpacing.description" = "Abstand zwischen Absätzen verringern";

/* CSS Snippets - Sichtbarkeit */
"css.snippet.hideImages.title" = "Bilder ausblenden";
"css.snippet.hideImages.description" = "Alle Bilder aus dem Artikel entfernen";
"css.snippet.hideHR.title" = "Trennlinien ausblenden";
"css.snippet.hideHR.description" = "Horizontale Trennlinien entfernen";
"css.snippet.linksPlain.title" = "Schlichte Links";
"css.snippet.linksPlain.description" = "Unterstreichung von Links entfernen";
"css.snippet.blockquotePlain.title" = "Schlichte Zitate";
"css.snippet.blockquotePlain.description" = "Rahmen, Hintergrund und Kursivschrift von Zitaten entfernen";
```

- [ ] **Step 3: Verify it compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add readeck/Localizations/en.lproj/Localizable.strings readeck/Localizations/de.lproj/Localizable.strings
git commit -m "feat: add EN and DE localization for CSS help view"
```

---

### Task 5: Add Files to Xcode Project

**Files:**
- Modify: `readeck.xcodeproj/project.pbxproj`

Note: The new Swift files (`CSSSnippet.swift`, `CustomCSSHelpView.swift`) need to be added to the Xcode project. Since the project uses Xcode's file references, the simplest approach is:

- [ ] **Step 1: Add new files to Xcode project**

Run the following to add the files to the project's build sources. If the project uses automatic file discovery (folder references), this step may not be needed — verify by building first:

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10`

If build fails with "no such module" or missing file errors, open the project in Xcode and add the two new files (`CSSSnippet.swift`, `CustomCSSHelpView.swift`) to the appropriate groups manually, then commit the changed `project.pbxproj`.

- [ ] **Step 2: Full build verification**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit if project file changed**

```bash
git add readeck.xcodeproj/project.pbxproj
git commit -m "chore: add new files to Xcode project"
```

---

### Task 6: Final Verification & PR

- [ ] **Step 1: Run tests**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`
Expected: All tests pass

- [ ] **Step 2: Create branch and push**

```bash
git checkout -b feat/issue-27-css-help
git push -u origin feat/issue-27-css-help
```

- [ ] **Step 3: Open draft PR**

```bash
gh pr create --draft --title "feat: Custom CSS help view with snippet catalog" --body "$(cat <<'EOF'
## Summary
- Adds an in-app CSS help sheet to the Custom CSS section in Reader Settings
- Categorized snippet catalog (Typography, Colors, Layout, Visibility)
- Each snippet has "Append" and "Replace" buttons
- Fully localized in English and German

Closes #27 (partial — custom CSS help)

## Test plan
- [ ] Open Reader Settings → Font Settings → Custom CSS section
- [ ] Tap "?" button → help sheet opens
- [ ] Verify all 4 categories with snippets are shown
- [ ] Tap "Append" on a snippet → CSS is added to the text field
- [ ] Tap "Replace" on a snippet → CSS replaces existing text field content
- [ ] Switch device language to German → all strings are localized
- [ ] Open an article → custom CSS is applied correctly
EOF
)"
```
