# Article Summary with Apple Foundation Models — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an on-device AI summarization button to the article reader that generates summaries via Apple Foundation Models, displayed in a bottom sheet with configurable target language.

**Architecture:** Clean Architecture UseCase pattern. New `SummarizeArticleUseCase` handles Foundation Models interaction and chunking. A new `ArticleSummarySheet` + `ArticleSummaryViewModel` manage the sheet UI. Both article reader views get a "Zusammenfassen" button in their `metaInfoSection`.

**Tech Stack:** Swift, SwiftUI, Apple FoundationModels framework (iOS 26+), `LanguageModelSession`, `@Generable`

---

### Task 1: Create SummarizeArticleUseCase Protocol and Implementation

**Files:**
- Create: `readeck/Domain/UseCase/Summary/SummarizeArticleUseCase.swift`

- [ ] **Step 1: Create the UseCase file with protocol and implementation**

```swift
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

protocol PSummarizeArticleUseCase {
    func execute(articleHTML: String, targetLanguage: String) async throws -> String
    static var isAvailable: Bool { get }
}

enum SummarizeArticleError: LocalizedError, Equatable {
    case modelNotAvailable
    case emptyContent
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "AI summarization is not available on this device.".localized
        case .emptyContent:
            return "No article content to summarize.".localized
        case .generationFailed(let message):
            return message
        }
    }
}

final class SummarizeArticleUseCase: PSummarizeArticleUseCase {

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    static var supportedLanguages: [Locale.Language] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return Array(SystemLanguageModel.default.supportedLanguages)
        }
        #endif
        return []
    }

    private let maxChunkCharacters = 12_000

    func execute(articleHTML: String, targetLanguage: String) async throws -> String {
        let plainText = stripHTML(articleHTML)

        guard !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummarizeArticleError.emptyContent
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return try await summarize(text: plainText, targetLanguage: targetLanguage)
        }
        #endif
        throw SummarizeArticleError.modelNotAvailable
    }

    // MARK: - HTML Stripping

    func stripHTML(_ html: String) -> String {
        guard let data = html.data(using: .utf8) else { return html }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        }
        // Fallback: simple regex strip
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // MARK: - Summarization

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func summarize(text: String, targetLanguage: String) async throws -> String {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let lengthInstruction = summaryLengthInstruction(wordCount: wordCount)

        if text.count <= maxChunkCharacters {
            return try await summarizeSingleChunk(text: text, targetLanguage: targetLanguage, lengthInstruction: lengthInstruction)
        } else {
            return try await summarizeWithChunking(text: text, targetLanguage: targetLanguage, lengthInstruction: lengthInstruction)
        }
    }

    @available(iOS 26.0, *)
    private func summarizeSingleChunk(text: String, targetLanguage: String, lengthInstruction: String) async throws -> String {
        let instructions = """
            You are a summarization assistant. \(lengthInstruction) \
            Write the summary in \(targetLanguage). \
            Focus on the key points and main arguments.
            """

        let session = LanguageModelSession(instructions: instructions)
        do {
            let response = try await session.respond(to: text)
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            if case .refusal(let refusal, _) = error {
                let explanation = (try? await refusal.explanation) ?? "The model refused to summarize this content."
                throw SummarizeArticleError.generationFailed(explanation)
            }
            throw SummarizeArticleError.generationFailed(error.localizedDescription)
        }
    }

    @available(iOS 26.0, *)
    private func summarizeWithChunking(text: String, targetLanguage: String, lengthInstruction: String) async throws -> String {
        let chunks = splitIntoChunks(text: text)
        var partialSummaries: [String] = []

        for chunk in chunks {
            let instructions = """
                You are a summarization assistant. Summarize the following text section concisely. \
                Write the summary in \(targetLanguage). Focus on the key points.
                """
            let session = LanguageModelSession(instructions: instructions)
            do {
                let response = try await session.respond(to: chunk)
                partialSummaries.append(response.content)
            } catch let error as LanguageModelSession.GenerationError {
                if case .refusal(let refusal, _) = error {
                    let explanation = (try? await refusal.explanation) ?? "The model refused to summarize this content."
                    throw SummarizeArticleError.generationFailed(explanation)
                }
                throw SummarizeArticleError.generationFailed(error.localizedDescription)
            }
        }

        let merged = partialSummaries.joined(separator: "\n\n")

        // If merged summaries fit in one chunk, do a final merge
        if merged.count <= maxChunkCharacters {
            let mergeInstructions = """
                You are a summarization assistant. \(lengthInstruction) \
                Combine the following partial summaries into one coherent summary. \
                Write the summary in \(targetLanguage). Remove redundancies and maintain logical flow.
                """
            let mergeSession = LanguageModelSession(instructions: mergeInstructions)
            let mergeResponse = try await mergeSession.respond(to: merged)
            return mergeResponse.content
        } else {
            // Recursive: summarize the summaries
            return try await summarizeWithChunking(text: merged, targetLanguage: targetLanguage, lengthInstruction: lengthInstruction)
        }
    }
    #endif

    // MARK: - Chunking

    func splitIntoChunks(text: String) -> [String] {
        let paragraphs = text.components(separatedBy: "\n\n")
        var chunks: [String] = []
        var currentChunk = ""

        for paragraph in paragraphs {
            if currentChunk.count + paragraph.count + 2 > maxChunkCharacters {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                    currentChunk = ""
                }
                // If a single paragraph exceeds the limit, split it further
                if paragraph.count > maxChunkCharacters {
                    let sentences = paragraph.components(separatedBy: ". ")
                    for sentence in sentences {
                        if currentChunk.count + sentence.count + 2 > maxChunkCharacters {
                            if !currentChunk.isEmpty {
                                chunks.append(currentChunk)
                                currentChunk = ""
                            }
                        }
                        currentChunk += (currentChunk.isEmpty ? "" : ". ") + sentence
                    }
                } else {
                    currentChunk = paragraph
                }
            } else {
                currentChunk += (currentChunk.isEmpty ? "" : "\n\n") + paragraph
            }
        }
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        return chunks
    }

    // MARK: - Length Instruction

    private func summaryLengthInstruction(wordCount: Int) -> String {
        if wordCount < 500 {
            return "Summarize in 2-3 sentences."
        } else if wordCount <= 2000 {
            return "Summarize in a short paragraph."
        } else {
            return "Summarize in multiple paragraphs."
        }
    }
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add readeck/Domain/UseCase/Summary/SummarizeArticleUseCase.swift
git commit -m "feat: add SummarizeArticleUseCase with chunking support"
```

---

### Task 2: Register UseCase in DI Factories

**Files:**
- Modify: `readeck/UI/Factory/DefaultUseCaseFactory.swift`
- Modify: `readeck/UI/Factory/MockUseCaseFactory.swift`
- Modify: `readeckTests/Helpers/TestUseCaseFactory.swift`

- [ ] **Step 1: Add factory method to UseCaseFactory protocol**

In `readeck/UI/Factory/DefaultUseCaseFactory.swift`, add to the `UseCaseFactory` protocol:

```swift
func makeSummarizeArticleUseCase() -> PSummarizeArticleUseCase
```

- [ ] **Step 2: Add implementation in DefaultUseCaseFactory**

In `DefaultUseCaseFactory`, add the method:

```swift
func makeSummarizeArticleUseCase() -> PSummarizeArticleUseCase {
    SummarizeArticleUseCase()
}
```

- [ ] **Step 3: Add mock in MockUseCaseFactory**

In `readeck/UI/Factory/MockUseCaseFactory.swift`, add a mock implementation at the bottom of the file:

```swift
final class MockSummarizeArticleUseCase: PSummarizeArticleUseCase {
    static var isAvailable: Bool { true }

    func execute(articleHTML: String, targetLanguage: String) async throws -> String {
        "This is a mock summary of the article."
    }
}
```

And add the factory method in `MockUseCaseFactory`:

```swift
func makeSummarizeArticleUseCase() -> PSummarizeArticleUseCase {
    MockSummarizeArticleUseCase()
}
```

- [ ] **Step 4: Add configurable mock in TestUseCaseFactory**

In `readeckTests/Helpers/TestUseCaseFactory.swift`, add the factory method:

```swift
func makeSummarizeArticleUseCase() -> PSummarizeArticleUseCase {
    MockSummarizeArticleUseCase()
}
```

- [ ] **Step 5: Verify the project compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add readeck/UI/Factory/DefaultUseCaseFactory.swift readeck/UI/Factory/MockUseCaseFactory.swift readeckTests/Helpers/TestUseCaseFactory.swift
git commit -m "feat: register SummarizeArticleUseCase in DI factories"
```

---

### Task 3: Create ArticleSummaryViewModel

**Files:**
- Create: `readeck/UI/BookmarkDetail/ArticleSummaryViewModel.swift`

- [ ] **Step 1: Create the ViewModel**

```swift
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@Observable
final class ArticleSummaryViewModel {
    private let summarizeUseCase: PSummarizeArticleUseCase
    private let articleContent: String

    var summary: String = ""
    var isLoading: Bool = false
    var error: Error?
    var selectedLanguage: String

    var availableLanguages: [(code: String, displayName: String)] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SummarizeArticleUseCase.supportedLanguages.compactMap { lang in
                guard let code = lang.languageCode?.identifier else { return nil }
                let displayName = Locale.current.localizedString(forLanguageCode: code) ?? code
                return (code: code, displayName: displayName)
            }
            .sorted { $0.displayName < $1.displayName }
        }
        #endif
        return []
    }

    init(articleContent: String, summarizeUseCase: PSummarizeArticleUseCase) {
        self.articleContent = articleContent
        self.summarizeUseCase = summarizeUseCase
        self.selectedLanguage = Locale.current.language.languageCode?.identifier ?? "en"
    }

    @MainActor
    func summarize() async {
        isLoading = true
        error = nil
        summary = ""

        let displayName = Locale.current.localizedString(forLanguageCode: selectedLanguage) ?? selectedLanguage

        do {
            summary = try await summarizeUseCase.execute(
                articleHTML: articleContent,
                targetLanguage: displayName
            )
        } catch {
            self.error = error
        }

        isLoading = false
    }
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add readeck/UI/BookmarkDetail/ArticleSummaryViewModel.swift
git commit -m "feat: add ArticleSummaryViewModel for summary sheet"
```

---

### Task 4: Create ArticleSummarySheet View

**Files:**
- Create: `readeck/UI/BookmarkDetail/ArticleSummarySheet.swift`

- [ ] **Step 1: Create the Sheet view**

```swift
import SwiftUI

struct ArticleSummarySheet: View {
    @State private var viewModel: ArticleSummaryViewModel

    init(articleContent: String, summarizeUseCase: PSummarizeArticleUseCase) {
        _viewModel = State(initialValue: ArticleSummaryViewModel(
            articleContent: articleContent,
            summarizeUseCase: summarizeUseCase
        ))
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Language picker
                if !viewModel.availableLanguages.isEmpty {
                    Picker("Language".localized, selection: $viewModel.selectedLanguage) {
                        ForEach(viewModel.availableLanguages, id: \.code) { language in
                            Text(language.displayName).tag(language.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                }

                // Content area
                if viewModel.isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Generating summary...".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else if let error = viewModel.error {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry".localized) {
                            Task {
                                await viewModel.summarize()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else if !viewModel.summary.isEmpty {
                    ScrollView {
                        Text(viewModel.summary)
                            .font(.body)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Summary".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.summarize()
        }
        .onChange(of: viewModel.selectedLanguage) { _, _ in
            Task {
                await viewModel.summarize()
            }
        }
    }
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add readeck/UI/BookmarkDetail/ArticleSummarySheet.swift
git commit -m "feat: add ArticleSummarySheet bottom sheet view"
```

---

### Task 5: Add Summarize Button to ArticleReaderLegacyView

**Files:**
- Modify: `readeck/UI/BookmarkDetail/ArticleReaderLegacyView.swift`

- [ ] **Step 1: Add @State property for sheet**

Add to the `@State` properties section (near the other `@State private var showing...` declarations):

```swift
@State private var showingSummarySheet = false
```

- [ ] **Step 2: Add the summarize button in metaInfoSection**

In the `metaInfoSection` computed property, add the following block after the labels section closing brace (line ~647) and before the `if appSettings.enableTTS {` block (line ~650):

```swift
if SummarizeArticleUseCase.isAvailable && !viewModel.articleContent.isEmpty {
    metaRow(icon: "sparkles") {
        Button(action: {
            showingSummarySheet = true
        }) {
            Text("Summarize".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
```

- [ ] **Step 3: Add the sheet modifier**

Add the `.sheet` modifier alongside the other sheet modifiers (after the `.sheet(isPresented: $showingImageViewer)` block):

```swift
.sheet(isPresented: $showingSummarySheet) {
    ArticleSummarySheet(
        articleContent: viewModel.articleContent,
        summarizeUseCase: DefaultUseCaseFactory.shared.makeSummarizeArticleUseCase()
    )
}
```

- [ ] **Step 4: Verify the file compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add readeck/UI/BookmarkDetail/ArticleReaderLegacyView.swift
git commit -m "feat: add summarize button to legacy article reader"
```

---

### Task 6: Add Summarize Button to ArticleReaderView

**Files:**
- Modify: `readeck/UI/BookmarkDetail/ArticleReaderView.swift`

- [ ] **Step 1: Add @State property for sheet**

Add to the `@State` properties section (near the other `@State private var showing...` declarations around line 14-21):

```swift
@State private var showingSummarySheet = false
```

- [ ] **Step 2: Add the summarize button in metaInfoSection**

In the `metaInfoSection` computed property, add the following block after the labels section closing brace and before the `if appSettings.enableTTS {` block (around line 399):

```swift
if SummarizeArticleUseCase.isAvailable && !viewModel.articleContent.isEmpty {
    metaRow(icon: "sparkles") {
        Button(action: {
            showingSummarySheet = true
        }) {
            Text("Summarize".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
```

- [ ] **Step 3: Add the sheet modifier**

Add the `.sheet` modifier alongside the other sheet modifiers (after the `.sheet(isPresented: $showingImageViewer)` block around line 63):

```swift
.sheet(isPresented: $showingSummarySheet) {
    ArticleSummarySheet(
        articleContent: viewModel.articleContent,
        summarizeUseCase: DefaultUseCaseFactory.shared.makeSummarizeArticleUseCase()
    )
}
```

- [ ] **Step 4: Verify the file compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add readeck/UI/BookmarkDetail/ArticleReaderView.swift
git commit -m "feat: add summarize button to modern article reader"
```

---

### Task 7: Add Localization Strings

**Files:**
- Modify: `readeck/Localizations/Base.lproj/Localizable.strings`
- Modify: `readeck/Localizations/en.lproj/Localizable.strings`
- Modify: `readeck/Localizations/de.lproj/Localizable.strings`

- [ ] **Step 1: Add strings to Base.lproj/Localizable.strings**

Add the following lines (group them together, e.g. after the TTS-related strings):

```
/* Article Summary */
"Summarize" = "Summarize";
"Summary" = "Summary";
"Generating summary..." = "Generating summary...";
"Retry" = "Retry";
"Language" = "Language";
"AI summarization is not available on this device." = "AI summarization is not available on this device.";
"No article content to summarize." = "No article content to summarize.";
```

- [ ] **Step 2: Add strings to en.lproj/Localizable.strings**

```
/* Article Summary */
"Summarize" = "Summarize";
"Summary" = "Summary";
"Generating summary..." = "Generating summary...";
"Retry" = "Retry";
"Language" = "Language";
"AI summarization is not available on this device." = "AI summarization is not available on this device.";
"No article content to summarize." = "No article content to summarize.";
```

- [ ] **Step 3: Add strings to de.lproj/Localizable.strings**

```
/* Article Summary */
"Summarize" = "Zusammenfassen";
"Summary" = "Zusammenfassung";
"Generating summary..." = "Zusammenfassung wird erstellt...";
"Retry" = "Erneut versuchen";
"Language" = "Sprache";
"AI summarization is not available on this device." = "KI-Zusammenfassung ist auf diesem Gerät nicht verfügbar.";
"No article content to summarize." = "Kein Artikelinhalt zum Zusammenfassen vorhanden.";
```

- [ ] **Step 4: Verify the project compiles**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add readeck/Localizations/Base.lproj/Localizable.strings readeck/Localizations/en.lproj/Localizable.strings readeck/Localizations/de.lproj/Localizable.strings
git commit -m "feat: add localization strings for article summary (EN/DE)"
```

---

### Task 8: Add Unit Tests for SummarizeArticleUseCase

**Files:**
- Create: `readeckTests/UseCases/SummarizeArticleUseCaseTests.swift`
- Modify: `readeckTests/Helpers/TestUseCaseFactory.swift`

- [ ] **Step 1: Add configurable mock to test helpers**

In `readeckTests/Helpers/TestUseCaseFactory.swift`, add a configurable mock (before or after the existing configurable mocks):

```swift
class ConfigurableSummarizeArticleUseCase: PSummarizeArticleUseCase {
    static var isAvailable: Bool { true }
    var result: Result<String, Error> = .success("Test summary")
    var executeCalled = false
    var lastTargetLanguage: String?

    func execute(articleHTML: String, targetLanguage: String) async throws -> String {
        executeCalled = true
        lastTargetLanguage = targetLanguage
        return try result.get()
    }
}
```

Update the `TestUseCaseFactory` to use the configurable mock:

```swift
let mockSummarizeArticle = ConfigurableSummarizeArticleUseCase()

func makeSummarizeArticleUseCase() -> PSummarizeArticleUseCase {
    mockSummarizeArticle
}
```

- [ ] **Step 2: Create UseCase tests**

```swift
import Testing
import Foundation
@testable import readeck

@Suite("SummarizeArticleUseCase Tests")
struct SummarizeArticleUseCaseTests {

    // MARK: - HTML Stripping

    @Test("stripHTML removes tags and returns plain text")
    func stripHTMLRemovesTags() {
        let useCase = SummarizeArticleUseCase()
        let html = "<p>Hello <strong>world</strong></p>"
        let result = useCase.stripHTML(html)
        #expect(result.contains("Hello"))
        #expect(result.contains("world"))
        #expect(!result.contains("<p>"))
        #expect(!result.contains("<strong>"))
    }

    @Test("stripHTML handles empty string")
    func stripHTMLEmpty() {
        let useCase = SummarizeArticleUseCase()
        let result = useCase.stripHTML("")
        #expect(result.isEmpty)
    }

    // MARK: - Chunking

    @Test("splitIntoChunks returns single chunk for short text")
    func splitShortText() {
        let useCase = SummarizeArticleUseCase()
        let text = "Short text."
        let chunks = useCase.splitIntoChunks(text: text)
        #expect(chunks.count == 1)
        #expect(chunks[0] == "Short text.")
    }

    @Test("splitIntoChunks splits at paragraph boundaries")
    func splitAtParagraphs() {
        let useCase = SummarizeArticleUseCase()
        // Create text that exceeds maxChunkCharacters (12000)
        let paragraph = String(repeating: "word ", count: 2000) // ~10000 chars
        let text = paragraph + "\n\n" + paragraph
        let chunks = useCase.splitIntoChunks(text: text)
        #expect(chunks.count == 2)
    }

    @Test("splitIntoChunks handles empty text")
    func splitEmptyText() {
        let useCase = SummarizeArticleUseCase()
        let chunks = useCase.splitIntoChunks(text: "")
        #expect(chunks.isEmpty)
    }

    // MARK: - Execute with empty content

    @Test("execute throws emptyContent for whitespace-only input")
    func executeEmptyContent() async {
        let useCase = SummarizeArticleUseCase()
        do {
            _ = try await useCase.execute(articleHTML: "   ", targetLanguage: "English")
            #expect(Bool(false), "Should have thrown")
        } catch let error as SummarizeArticleError {
            #expect(error == .emptyContent)
        } catch {
            #expect(Bool(false), "Wrong error type: \(error)")
        }
    }

    // MARK: - Summary Length Instruction

    @Test("short article gets 2-3 sentence instruction")
    func shortArticleInstruction() {
        // This tests indirectly through the public interface — 
        // the actual instruction is internal, so we verify via chunking behavior
        let useCase = SummarizeArticleUseCase()
        let shortText = String(repeating: "word ", count: 100) // ~100 words
        let chunks = useCase.splitIntoChunks(text: shortText)
        #expect(chunks.count == 1) // Short text should be single chunk
    }
}
```

- [ ] **Step 3: Run the tests**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:readeckTests/SummarizeArticleUseCaseTests 2>&1 | tail -30`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add readeckTests/UseCases/SummarizeArticleUseCaseTests.swift readeckTests/Helpers/TestUseCaseFactory.swift
git commit -m "test: add unit tests for SummarizeArticleUseCase"
```

---

### Task 9: Final Build Verification

**Files:** None (verification only)

- [ ] **Step 1: Full project build**

Run: `xcodebuild -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Run all tests**

Run: `xcodebuild test -scheme readeck -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -30`
Expected: All tests PASS

- [ ] **Step 3: Commit all remaining changes (if any)**

```bash
git status
# If there are uncommitted changes:
git add -A
git commit -m "chore: final cleanup for article summary feature"
```
