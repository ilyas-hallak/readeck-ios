# Article Summary with Apple Foundation Models — Design Spec

## Overview

Add an on-device AI summarization feature to the Article Reader View using Apple's Foundation Models framework. A "Zusammenfassen" button in the meta section opens a bottom sheet with a generated summary. The feature is only available on devices that support Foundation Models (iPhone 15+).

## User Flow

1. User opens an article in the reader
2. If device supports Foundation Models and article has content: "Zusammenfassen" button is visible in meta section (after Safari link, before TTS)
3. User taps button -> bottom sheet opens
4. Sheet shows a language picker (pre-selected: device language) and starts generating the summary automatically
5. Summary appears as scrollable text below the picker
6. User can change language -> new summary is generated
7. On error: error message with retry button

## Architecture

### Domain Layer

**Protocol:**
```swift
protocol PSummarizeArticleUseCase {
    func execute(articleHTML: String, targetLanguage: Locale.Language?) async throws -> String
}
```

**UseCase: `SummarizeArticleUseCase`**
- Strips HTML tags to plain text
- Checks text length against token limit
- Short articles: single `LanguageModelSession.respond()` call
- Long articles: chunk at paragraph boundaries, summarize per chunk, then merge summaries
- Target language defaults to `Locale.current.language` if nil
- Instructions include target language explicitly (e.g., "Fasse den folgenden Text auf Deutsch zusammen")

**Availability check:**
- Static function `isAvailable` checking `SystemLanguageModel.default.availability == .available`

### UI Layer

**ArticleSummarySheet (new file):**
- Presented as `.sheet` from BookmarkDetailView
- Language picker at top (populated from `SystemLanguageModel.supportedLanguages`)
- States: Loading (ProgressView), Success (scrollable text), Error (message + retry button)
- Summary generation starts automatically on appear
- Language change triggers new summary

**Button in metaInfoSection:**
- Icon: `sparkles`, Text: "Zusammenfassen" (localized)
- Only shown when `SummarizeArticleUseCase.isAvailable` returns true AND article content is not empty
- Placement: after Safari link, before TTS button
- Tap sets `showSummarySheet = true`

**BookmarkDetailViewModel:**
- New property: `showSummarySheet: Bool`

**ArticleSummaryViewModel (new file):**
- Injected with `articleContent: String` and `PSummarizeArticleUseCase`
- Properties: `summary: String`, `isLoading: Bool`, `error: Error?`, `selectedLanguage: Locale.Language`
- Method `summarize()` calls the use case

## Chunking Strategy

**Token limit:** ~4096 tokens context window. Conservative estimate: ~3000 tokens for input. Heuristic: 1 token ≈ 4 chars -> ~12,000 chars per chunk max.

**Process:**
1. Strip HTML to plain text
2. If text ≤ 12,000 chars: single summary
3. If text > 12,000 chars: split at paragraph boundaries into ~10,000-12,000 char chunks
4. Generate summary per chunk
5. Merge all partial summaries with prompt: "Fasse die folgenden Teil-Zusammenfassungen zu einer kohärenten Gesamtzusammenfassung zusammen"
6. If merged summaries exceed limit: recurse

**Summary length scales with article length:**
- < 500 words: "Fasse in 2-3 Sätzen zusammen"
- 500-2000 words: "Fasse in einem kurzen Absatz zusammen"
- \> 2000 words: "Fasse in mehreren Absätzen zusammen"

Controlled via model instructions, not output token limits.

## Error Handling

- **Model not available** (download pending): button not shown
- **Refusal:** catch `GenerationError.refusal`, show `refusal.explanation` to user
- **Empty article content:** button not shown
- **Chunk failure:** error propagated, user can retry
- **Network independent:** Foundation Models runs fully on-device

## No Caching

Summaries are not persisted. Each tap regenerates the summary.

## Device Compatibility

- Requires iPhone 15+ (devices with Apple Foundation Model support)
- Button is simply not shown on unsupported devices
- Check via `SystemLanguageModel.default.availability`

## Files

### New Files
- `readeck/Domain/UseCase/SummarizeArticleUseCase.swift`
- `readeck/UI/BookmarkDetail/ArticleSummarySheet.swift`
- `readeck/UI/BookmarkDetail/ArticleSummaryViewModel.swift`

### Modified Files
- `readeck/UI/BookmarkDetail/BookmarkDetailLegacyView.swift` — button in metaInfoSection
- `readeck/UI/BookmarkDetail/BookmarkDetailView2.swift` — button in metaInfoSection
- `readeck/UI/BookmarkDetail/BookmarkDetailViewModel.swift` — `showSummarySheet` property
- `readeck/UI/Factory/DefaultUseCaseFactory.swift` — register use case
- `readeck/UI/Factory/MockUseCaseFactory.swift` — mock for tests
- `readeck/Localizations/Base.lproj/Localizable.strings`
- `readeck/Localizations/en.lproj/Localizable.strings`
- `readeck/Localizations/de.lproj/Localizable.strings`

## GitHub Issue

### Title
feat: AI article summarization with Apple Foundation Models

### Body

**Description:**
Add a "Zusammenfassen" button in the article reader meta section that generates an on-device AI summary using Apple's Foundation Models framework. Summary is displayed in a bottom sheet with configurable target language.

**Requirements:**
- Button with `sparkles` icon in meta section (after Safari link, before TTS)
- Bottom sheet with language picker and generated summary
- Default language: device language, changeable via picker
- Summary length scales with article length
- Long articles: chunk-based summarization with merge step
- Only available on iPhone 15+ (Foundation Model support)
- Button hidden on unsupported devices or empty articles
- Error handling with retry capability
- Localized (DE/EN)

**Acceptance Criteria:**
- [ ] "Zusammenfassen" button appears only on supported devices
- [ ] Bottom sheet opens and generates summary automatically
- [ ] Language selection works and triggers new summary
- [ ] Long articles are correctly chunked and summarized
- [ ] Loading, success, and error states display correctly
- [ ] Retry after error works
- [ ] Button hidden when article content is empty
- [ ] Localization (DE/EN) present
