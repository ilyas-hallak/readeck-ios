# Share Extension: Send Page Content — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow the Share Extension to capture and send the full HTML content of a web page alongside the bookmark URL, enabling paywalled article saving.

**Architecture:** A JavaScript Preprocessing file captures the page HTML in Safari's context before the Share Extension UI opens. The HTML is held in the ViewModel and sent to the API only when the user enables a toggle. Offline bookmarks also store the HTML via an extended CoreData model.

**Tech Stack:** Swift, SwiftUI, JavaScript (Safari Extension Preprocessing), CoreData, URLSession

**Spec:** `docs/superpowers/specs/2026-04-13-share-extension-html-design.md`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `URLShare/ShareExtension.js` | JavaScript Preprocessing — extracts URL, title, HTML from Safari page |
| Modify | `URLShare/Info.plist` | Register JS preprocessing file |
| Modify | `URLShare/ShareViewController.swift` | Extract HTML from `NSExtensionItem` via `kUTTypePropertyList` |
| Modify | `URLShare/ShareBookmarkViewModel.swift` | Add `pageHTML` and `includeHTML` properties, pass HTML through save flow |
| Modify | `URLShare/ShareBookmarkView.swift` | Add "Send page content" toggle |
| Modify | `URLShare/SimpleAPIDTOs.swift` | Add `html` field to `CreateBookmarkRequestDto` |
| Modify | `URLShare/SimpleAPI.swift` | Pass `html` parameter through `addBookmark()` |
| Modify | `URLShare/OfflineBookmarkManager.swift` | Accept and store `html` in offline bookmarks |
| Modify | `readeck/readeck.xcdatamodeld/readeck.xcdatamodel/contents` | Add `html` attribute to `ArticleURLEntity` |
| Modify | `readeck/Data/API/DTOs/CreateBookmarkRequestDto.swift` | Add `html` field (main app DTO) |
| Modify | `readeck/Data/Repository/OfflineSyncManager.swift` | Include `html` when syncing offline bookmarks |

---

### Task 1: JavaScript Preprocessing File

**Files:**
- Create: `URLShare/ShareExtension.js`
- Modify: `URLShare/Info.plist`

- [ ] **Step 1: Create the JavaScript preprocessing file**

Create `URLShare/ShareExtension.js`:

```javascript
var ExtensionPreprocessingJS = new Object();

ExtensionPreprocessingJS.run = function(arguments) {
    arguments.completionFunction({
        "url": document.URL,
        "title": document.title,
        "html": document.documentElement.outerHTML
    });
};
```

- [ ] **Step 2: Register the JS file in Info.plist**

Modify `URLShare/Info.plist` — add `NSExtensionJavaScriptPreprocessingFile` inside the `NSExtensionAttributes` dict:

```xml
<key>NSExtensionAttributes</key>
<dict>
    <key>NSExtensionActivationRule</key>
    <dict>
        <key>NSExtensionActivationSupportsText</key>
        <true/>
        <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
        <integer>1</integer>
    </dict>
    <key>NSExtensionJavaScriptPreprocessingFile</key>
    <string>ShareExtension</string>
</dict>
```

- [ ] **Step 3: Add ShareExtension.js to the URLShare target in Xcode**

Ensure `ShareExtension.js` is included in the URLShare target's "Copy Bundle Resources" build phase. This must be verified in `readeck.xcodeproj/project.pbxproj`.

- [ ] **Step 4: Commit**

```bash
git add URLShare/ShareExtension.js URLShare/Info.plist readeck.xcodeproj/project.pbxproj
git commit -m "feat: add JavaScript preprocessing to capture page HTML in share extension"
```

---

### Task 2: Extract HTML in ShareViewController

**Files:**
- Modify: `URLShare/ShareViewController.swift`

The `ShareViewController` needs to pass the page HTML to the ViewModel. Currently the ViewModel extracts content itself from `extensionContext`. We'll change the ViewModel init to also accept an optional `pageHTML` string, and extract it in the ViewController where we have access to `kUTTypePropertyList`.

- [ ] **Step 1: Add HTML extraction to ShareViewController**

In `ShareViewController.swift`, replace the `viewDidLoad` method. After creating the ViewModel, extract the HTML from the extension item's JavaScript results and pass it to the ViewModel:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    let viewModel = ShareBookmarkViewModel(extensionContext: extensionContext)

    // Extract HTML from JavaScript preprocessing results
    extractPageHTML { html in
        viewModel.pageHTML = html
    }

    let swiftUIView = ShareBookmarkView(viewModel: viewModel)
        .environment(\.managedObjectContext, CoreDataManager.shared.context)
    let hostingController = UIHostingController(rootView: AnyView(swiftUIView))
    addChild(hostingController)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hostingController.view)
    NSLayoutConstraint.activate([
        hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
        hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
    hostingController.didMove(toParent: self)
    self.hostingController = hostingController

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(dismissKeyboard),
        name: .dismissKeyboard,
        object: nil
    )
}
```

- [ ] **Step 2: Add the extractPageHTML helper method**

Add this method to `ShareViewController`:

```swift
private func extractPageHTML(completion: @escaping (String?) -> Void) {
    guard let extensionContext else {
        completion(nil)
        return
    }

    for item in extensionContext.inputItems {
        guard let inputItem = item as? NSExtensionItem else { continue }
        for attachment in inputItem.attachments ?? [] {
            if attachment.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { result, _ in
                    guard let dictionary = result as? NSDictionary,
                          let jsResults = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary,
                          let html = jsResults["html"] as? String else {
                        completion(nil)
                        return
                    }
                    DispatchQueue.main.async {
                        completion(html)
                    }
                }
                return
            }
        }
    }
    completion(nil)
}
```

- [ ] **Step 3: Commit**

```bash
git add URLShare/ShareViewController.swift
git commit -m "feat: extract page HTML from JavaScript preprocessing in share extension"
```

---

### Task 3: ViewModel — Add pageHTML and includeHTML properties

**Files:**
- Modify: `URLShare/ShareBookmarkViewModel.swift`

- [ ] **Step 1: Add published properties**

Add these two properties to `ShareBookmarkViewModel`, after the existing `@Published` properties:

```swift
@Published var pageHTML: String?
@Published var includeHTML = false
```

- [ ] **Step 2: Update the save() method — online path**

In the `save()` method, change the `SimpleAPI.addBookmark` call to pass `html`:

```swift
let htmlToSend = includeHTML ? pageHTML : nil
await SimpleAPI.addBookmark(title: title, url: url, labels: Array(selectedLabels), html: htmlToSend) { [weak self] message, error in
    self?.logger.info("API save completed - Success: \(!error), Message: \(message)")
    if !error && self?.includeHTML == true {
        self?.statusMessage = ("Saved with page content", false, "✅")
    } else {
        self?.statusMessage = (message, error, error ? "❌" : "✅")
    }
    self?.isSaving = false
    if !error {
        self?.logger.debug("Bookmark saved successfully, completing extension request")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self?.completeExtensionRequest()
        }
    } else {
        self?.logger.error("Failed to save bookmark via API: \(message)")
    }
}
```

- [ ] **Step 3: Update the save() method — offline path**

In the offline branch, change the `saveOfflineBookmark` call:

```swift
let htmlToSend = includeHTML ? pageHTML : nil
let success = OfflineBookmarkManager.shared.saveOfflineBookmark(
    url: url,
    title: title,
    tags: Array(selectedLabels),
    html: htmlToSend
)
```

- [ ] **Step 4: Commit**

```bash
git add URLShare/ShareBookmarkViewModel.swift
git commit -m "feat: add pageHTML and includeHTML properties to share extension ViewModel"
```

---

### Task 4: UI — Add Toggle to ShareBookmarkView

**Files:**
- Modify: `URLShare/ShareBookmarkView.swift`

- [ ] **Step 1: Add the sendPageContent toggle section**

Add this computed property to `ShareBookmarkView`, after the `titleSection`:

```swift
@ViewBuilder
private var sendPageContentSection: some View {
    if viewModel.pageHTML != nil {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Send page content")
                    .font(.system(size: 15, weight: .medium))
                Text("Useful for paywalled articles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $viewModel.includeHTML)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}
```

- [ ] **Step 2: Insert the section into the body**

In the `VStack(spacing: 0)` inside the `ScrollView`, add `sendPageContentSection` after `titleSection`:

```swift
VStack(spacing: 0) {
    logoSection
    serverStatusSection
    urlSection
    tagManagementSection
        .id(AddBookmarkFieldFocus.labels)
    titleSection
        .id(AddBookmarkFieldFocus.title)
    sendPageContentSection
    statusSection
    Spacer(minLength: 100)
}
```

- [ ] **Step 3: Commit**

```bash
git add URLShare/ShareBookmarkView.swift
git commit -m "feat: add 'Send page content' toggle to share extension UI"
```

---

### Task 5: DTOs — Add html field

**Files:**
- Modify: `URLShare/SimpleAPIDTOs.swift`
- Modify: `readeck/Data/API/DTOs/CreateBookmarkRequestDto.swift`

- [ ] **Step 1: Update the URLShare DTO**

In `URLShare/SimpleAPIDTOs.swift`, replace `CreateBookmarkRequestDto`:

```swift
public struct CreateBookmarkRequestDto: Codable {
    // swiftlint:disable:next discouraged_optional_collection
    public let labels: [String]?
    public let title: String?
    public let url: String
    public let html: String?

    // swiftlint:disable:next discouraged_optional_collection
    public init(url: String, title: String? = nil, labels: [String]? = nil, html: String? = nil) {
        self.url = url
        self.title = title
        self.labels = labels
        self.html = html
    }
}
```

- [ ] **Step 2: Update the main app DTO**

In `readeck/Data/API/DTOs/CreateBookmarkRequestDto.swift`, replace the struct:

```swift
struct CreateBookmarkRequestDto: Codable {
    // swiftlint:disable:next discouraged_optional_collection
    let labels: [String]?
    let title: String?
    let url: String
    let html: String?

    // swiftlint:disable:next discouraged_optional_collection
    init(url: String, title: String? = nil, labels: [String]? = nil, html: String? = nil) {
        self.url = url
        self.title = title
        self.labels = labels
        self.html = html
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add URLShare/SimpleAPIDTOs.swift readeck/Data/API/DTOs/CreateBookmarkRequestDto.swift
git commit -m "feat: add optional html field to CreateBookmarkRequestDto"
```

---

### Task 6: SimpleAPI — Pass html parameter

**Files:**
- Modify: `URLShare/SimpleAPI.swift`

- [ ] **Step 1: Update addBookmark signature and body**

Change the `addBookmark` method signature to accept an optional `html` parameter. Replace line 126 onwards:

```swift
// swiftlint:disable:next discouraged_optional_collection
static func addBookmark(title: String, url: String, labels: [String]? = nil, html: String? = nil, showStatus: @escaping (String, Bool) -> Void) async {
    logger.info("Adding bookmark: \(url)")
    guard let token = await getValidToken() else {
        showStatus("No token found. Please log in via the main app.", true)
        return
    }
    guard let endpoint = KeychainHelper.shared.loadEndpoint(), !endpoint.isEmpty else {
        showStatus("No server endpoint found.", true)
        return
    }
    let requestDto = CreateBookmarkRequestDto(url: url, title: title, labels: labels, html: html)
    guard let requestData = try? JSONEncoder().encode(requestDto) else {
        showStatus("Failed to encode request.", true)
        return
    }
```

The rest of the method stays unchanged. Only the signature and the `CreateBookmarkRequestDto` init call change.

- [ ] **Step 2: Commit**

```bash
git add URLShare/SimpleAPI.swift
git commit -m "feat: pass optional html to bookmark creation API"
```

---

### Task 7: CoreData — Add html attribute to ArticleURLEntity

**Files:**
- Modify: `readeck/readeck.xcdatamodeld/readeck.xcdatamodel/contents`

- [ ] **Step 1: Add html attribute to ArticleURLEntity**

In the CoreData model XML, add the `html` attribute to `ArticleURLEntity`:

```xml
<entity name="ArticleURLEntity" representedClassName="ArticleURLEntity" syncable="YES" codeGenerationType="class">
    <attribute name="html" optional="YES" attributeType="String"/>
    <attribute name="id" optional="YES" attributeType="UUID" usesScalarValueType="NO"/>
    <attribute name="tags" optional="YES" attributeType="String"/>
    <attribute name="title" optional="YES" attributeType="String"/>
    <attribute name="url" optional="YES" attributeType="String"/>
</entity>
```

Note: Since the model uses lightweight migration (`automaticallyMergesChangesFromParent`) and the new attribute is optional, no migration mapping is needed.

- [ ] **Step 2: Commit**

```bash
git add readeck/readeck.xcdatamodeld/readeck.xcdatamodel/contents
git commit -m "feat: add html attribute to ArticleURLEntity for offline storage"
```

---

### Task 8: OfflineBookmarkManager — Store HTML

**Files:**
- Modify: `URLShare/OfflineBookmarkManager.swift`

- [ ] **Step 1: Update saveOfflineBookmark signature and implementation**

Change the `saveOfflineBookmark` method to accept an optional `html` parameter:

```swift
func saveOfflineBookmark(url: String, title: String = "", tags: [String] = [], html: String? = nil) -> Bool {
    let tagsString = tags.joined(separator: ",")

    do {
        try context.safePerform { [weak self] in
            guard let self else { return }

            let fetchRequest: NSFetchRequest<ArticleURLEntity> = ArticleURLEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "url == %@", url)

            let existingEntities = try self.context.fetch(fetchRequest)
            if let existingEntity = existingEntities.first {
                existingEntity.tags = tagsString
                existingEntity.title = title
                existingEntity.html = html
            } else {
                let entity = ArticleURLEntity(context: self.context)
                entity.id = UUID()
                entity.url = url
                entity.title = title
                entity.tags = tagsString
                entity.html = html
            }

            try self.context.save()
            print("Bookmark saved offline: \(url)")
        }
        return true
    } catch {
        print("Failed to save offline bookmark: \(error)")
        return false
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add URLShare/OfflineBookmarkManager.swift
git commit -m "feat: store HTML in offline bookmarks"
```

---

### Task 9: OfflineSyncManager — Sync HTML

**Files:**
- Modify: `readeck/Data/Repository/OfflineSyncManager.swift`

- [ ] **Step 1: Update syncOfflineBookmarks to include html**

In the `syncOfflineBookmarks()` method, change the DTO creation inside the `for bookmark in offlineBookmarks` loop (around line 59):

```swift
let dto = CreateBookmarkRequestDto(url: url, title: title, labels: tags.isEmpty ? nil : tags, html: bookmark.html)
```

This is a single-line change. When `bookmark.html` is `nil` (bookmarks saved without content), the field is omitted from the JSON. When it has content, it's included in the sync request.

- [ ] **Step 2: Commit**

```bash
git add readeck/Data/Repository/OfflineSyncManager.swift
git commit -m "feat: include HTML when syncing offline bookmarks"
```

---

### Task 10: Build & Manual Test

- [ ] **Step 1: Build the project**

Open Xcode and build both targets (main app + URLShare extension). Fix any compile errors.

```bash
xcodebuild -project readeck.xcodeproj -scheme URLShare -destination 'platform=iOS Simulator,name=iPhone 16' build
```

- [ ] **Step 2: Manual test — Share without HTML**

1. Run the app on a simulator or device
2. Open Safari, navigate to any page
3. Tap Share → Readeck
4. Verify the toggle "Send page content" is visible
5. Leave toggle OFF, save bookmark
6. Verify success message shows the normal "Saved: ..." text

- [ ] **Step 3: Manual test — Share with HTML**

1. Open Safari, navigate to any page
2. Tap Share → Readeck
3. Enable "Send page content" toggle
4. Save bookmark
5. Verify success message shows "Saved with page content"
6. Verify on the Readeck server that the bookmark has article content

- [ ] **Step 4: Manual test — Offline with HTML**

1. Disconnect from network / put server offline
2. Share a page with toggle ON
3. Verify "Saved locally" message
4. Reconnect and sync
5. Verify bookmark appears on server with content

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: share extension sends page content for paywalled articles"
```
