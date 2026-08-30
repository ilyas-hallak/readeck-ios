import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import CoreData

@Observable
final class ShareBookmarkViewModel {
    var url: String?
    var title = ""
    var selectedLabels: Set<String> = []
    var statusMessage: (text: String, isError: Bool, emoji: String)?
    var isSaving = false
    var searchText = ""
    var isServerReachable = true
    var isConfigured = true
    var sessionExpired = false
    var pageHTML: String?
    var includeHTML = false
    /// Set once the bookmark is saved online and the server returned its id. Needed to
    /// deep-link into the app; nil after a local save or an older server that doesn't
    /// return the id.
    var savedBookmarkId: String?
    /// When on, a successful online save deep-links into the app instead of just
    /// closing the sheet. Deliberately not remembered: saving and moving on is the
    /// common case, so opening the app stays an explicit per-share choice.
    var openAfterSave = false
    let tagSortOrder: TagSortOrder
    let extensionContext: NSExtensionContext?
    /// A view from the hosting controller, used as the entry point into the responder
    /// chain when opening the host app (see `openInApp`). Set by `ShareViewController`.
    weak var hostResponder: UIResponder?

    private let logger = Logger.viewModel
    private let serverCheck = ShareExtensionServerCheck.shared
    private let tagRepository = TagRepository()
    private var notificationObserver: Any?
    private var autoCloseTask: Task<Void, Never>?

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
        self.tagSortOrder = Self.loadTagSortOrder()
        logger.info("ShareBookmarkViewModel initialized with extension context: \(extensionContext != nil)")

        // Check if app is configured by verifying token exists
        checkConfiguration()

        // Setup notification observer for 401 errors
        setupNotificationObservers()

        extractSharedContent()
    }

    private func extractSharedContent() {
        logger.debug("Starting to extract shared content")
        guard let extensionContext else {
            logger.warning("No extension context available for content extraction")
            return
        }

        var extractedUrl: String?
        var extractedTitle: String?

        for item in extensionContext.inputItems {
            guard let inputItem = item as? NSExtensionItem else { continue }

            // Use the inputItem's attributedTitle or attributedContentText as potential title
            if let attributedTitle = inputItem.attributedTitle?.string, !attributedTitle.isEmpty {
                extractedTitle = attributedTitle
                logger.info("Extracted title from input item: \(attributedTitle)")
            } else if let attributedContent = inputItem.attributedContentText?.string, !attributedContent.isEmpty {
                extractedTitle = attributedContent
                logger.info("Extracted title from content text: \(attributedContent)")
            }

            for attachment in inputItem.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] url, error in
                        DispatchQueue.main.async {
                            if let url = url as? URL {
                                self?.url = url.absoluteString
                                self?.logger.info("Extracted URL from shared content: \(url.absoluteString)")

                                // Set title if we extracted one and current title is empty
                                if let title = extractedTitle, self?.title.isEmpty == true {
                                    self?.title = title
                                    self?.logger.info("Set title from shared content: \(title)")
                                }
                            } else if let error {
                                self?.logger.error("Failed to extract URL: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] text, error in
                        DispatchQueue.main.async {
                            if let text = text as? String {
                                // Only treat as URL if it's a valid URL and we don't have one yet
                                if self?.url == nil, let url = URL(string: text), url.scheme != nil {
                                    self?.url = url.absoluteString
                                    self?.logger.info("Extracted URL from shared text: \(url.absoluteString)")
                                } else {
                                    // If not a valid URL or we already have a URL, treat as potential title
                                    if self?.title.isEmpty == true {
                                        self?.title = text
                                        self?.logger.info("Set title from shared text: \(text)")
                                    }
                                }
                            } else if let error {
                                self?.logger.error("Failed to extract text: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }

    func save() {
        logger.info("Starting to save bookmark with title: '\(title)', URL: '\(url ?? "nil")', labels: \(selectedLabels.count)")
        guard let url, !url.isEmpty else {
            logger.warning("Save attempted without valid URL")
            statusMessage = ("No URL found.", true, "❌")
            return
        }
        isSaving = true
        logger.debug("Set saving state to true")

        // Check server connectivity
        Task {
            let serverInfo = await serverCheck.checkServerReachability()
            logger.debug("Server connectivity for save: \(serverInfo != nil), version: \(serverInfo?.version.canonical ?? "unknown")")
            if let serverInfo {
                // Online - try to save via API
                logger.info("Attempting to save bookmark via API")
                let htmlToSend = includeHTML && serverInfo.supportsHTMLBookmarks ? pageHTML : nil
                if includeHTML && !serverInfo.supportsHTMLBookmarks {
                    logger.info("Server version \(serverInfo.version.canonical) does not support HTML bookmarks (requires >= 0.22), sending without HTML")
                }
                await SimpleAPI.addBookmark(title: title, url: url, labels: Array(selectedLabels), html: htmlToSend) { [weak self] message, error, bookmarkId in
                    guard let self else { return }
                    self.logger.info("API save completed - Success: \(!error), Message: \(message), id: \(bookmarkId ?? "unknown")")
                    if !error && self.includeHTML == true {
                        self.statusMessage = ("Saved with page content", false, "✅")
                    } else {
                        self.statusMessage = (message, error, error ? "❌" : "✅")
                    }
                    self.isSaving = false
                    if !error {
                        self.savedBookmarkId = bookmarkId
                        self.logger.debug("Bookmark saved successfully, id available: \(bookmarkId != nil)")
                        if self.openAfterSave, bookmarkId != nil {
                            self.openInApp()
                        } else {
                            // Saving and getting out of the way is the common case, so
                            // close as soon as the success state has been shown.
                            self.scheduleAutoClose(after: 0.5)
                        }
                    } else {
                        self.logger.error("Failed to save bookmark via API: \(message)")
                    }
                }
            } else {
                // Server not reachable - save locally
                logger.info("Server not reachable, attempting local save")
                let htmlToSend = includeHTML ? pageHTML : nil
                let success = OfflineBookmarkManager.shared.saveOfflineBookmark(
                    url: url,
                    title: title,
                    tags: Array(selectedLabels),
                    html: htmlToSend
                )
                logger.info("Local save result: \(success)")

                await MainActor.run {
                    self.isSaving = false
                    if success {
                        self.logger.info("Bookmark saved locally successfully")
                        self.statusMessage = ("Server not reachable. Saved locally and will sync later.", false, "🏠")
                    } else {
                        self.logger.error("Failed to save bookmark locally")
                        self.statusMessage = ("Failed to save locally.", true, "❌")
                    }
                }

                if success {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        self.completeExtensionRequest()
                    }
                }
            }
        }
    }

    func addCustomTag(context: NSManagedObjectContext) {
        let splitLabels = LabelUtils.splitLabelsFromInput(searchText)

        // Fetch available labels from Core Data
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        let availableLabels = (try? context.fetch(fetchRequest))?.compactMap(\.name) ?? []

        let currentLabels = Array(selectedLabels)
        let uniqueLabels = LabelUtils.filterUniqueLabels(splitLabels, currentLabels: currentLabels, availableLabels: availableLabels)

        for label in uniqueLabels {
            selectedLabels.insert(label)
            // Save new label to Core Data so it's available next time
            tagRepository.saveNewLabel(name: label, context: context)
        }

        // Force refresh of @FetchRequest in CoreDataTagManagementView
        // This ensures newly created labels appear immediately in the search results
        context.refreshAllObjects()

        searchText = ""
    }

    private func checkConfiguration() {
        let endpoint = KeychainHelper.shared.loadEndpoint()

        // Check if endpoint exists first
        guard let endpoint, !endpoint.isEmpty else {
            logger.warning("Share extension opened but app is not configured (missing endpoint)")
            isConfigured = false
            return
        }

        // Check authentication method and corresponding token
        let authMethod = KeychainHelper.shared.loadAuthMethod()

        if authMethod == .oauth {
            // OAuth authentication - check OAuth token
            let oauthToken = KeychainHelper.shared.loadOAuthToken()
            if oauthToken == nil {
                logger.warning("Share extension opened but OAuth token is missing")
                isConfigured = false
            } else {
                logger.info("Share extension opened with valid OAuth configuration")
                isConfigured = true
            }
        } else {
            // Classic authentication (API token) or no auth method set
            let token = KeychainHelper.shared.loadToken()
            if token == nil || token?.isEmpty == true {
                logger.warning("Share extension opened but app is not configured (missing API token)")
                isConfigured = false
            } else {
                logger.info("Share extension opened with valid classic authentication")
                isConfigured = true
            }
        }
    }

    private func setupNotificationObservers() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .unauthorizedAPIResponse,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.warning("Received 401 Unauthorized - session expired")
            self?.sessionExpired = true
        }
    }

    /// Opens the freshly saved bookmark in the main app via the `readeck://` deep link
    /// and then closes the extension. Cancels the pending auto-close first.
    func openInApp() {
        guard let id = savedBookmarkId,
              let url = URL(string: "readeck://bookmark/\(id)") else {
            logger.warning("Open in app requested but no saved bookmark id available")
            return
        }
        autoCloseTask?.cancel()
        logger.info("Opening saved bookmark in app: \(url.absoluteString)")

        // `extensionContext.open` is unreliable from a share extension, so we walk the
        // responder chain to reach the host `UIApplication` and open the URL there. If
        // no application is found, fall back to `extensionContext.open`.
        if openViaResponderChain(url) {
            logger.info("Opened host app via responder chain")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.completeExtensionRequest()
            }
            return
        }

        logger.info("Responder chain could not open the URL, falling back to extensionContext.open")
        extensionContext?.open(url) { [weak self] success in
            self?.logger.info("extensionContext.open returned success: \(success)")
            DispatchQueue.main.async {
                self?.completeExtensionRequest()
            }
        }
    }

    /// Walks up the responder chain from the hosting view to the host `UIApplication`
    /// and asks it to open the URL. The `as? UIApplication` cast matches only the real
    /// application, so SwiftUI's hosting view (which also handles `openURL:` via the
    /// OpenURLAction and would otherwise swallow the call) is skipped. We use the
    /// non-deprecated `open(_:options:completionHandler:)` — on iOS 18 the old
    /// `openURL:` is forced to no-op.
    private func openViaResponderChain(_ url: URL) -> Bool {
        var responder: UIResponder? = hostResponder
        while let current = responder {
            if let application = current as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return true
            }
            responder = current.next
        }
        return false
    }

    /// Auto-closes the extension after the given delay unless cancelled (e.g. the user
    /// tapped "Open in Readeck" first).
    private func scheduleAutoClose(after seconds: Double) {
        autoCloseTask?.cancel()
        autoCloseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.completeExtensionRequest()
            }
        }
    }

    private func completeExtensionRequest() {
        logger.debug("Completing extension request")
        guard let context = extensionContext else {
            logger.warning("Extension context not available for completion")
            return
        }

        context.completeRequest(returningItems: []) { [weak self] error in
            if error {
                self?.logger.error("Extension completion failed: \(error)")
            } else {
                self?.logger.info("Extension request completed successfully")
            }
        }
    }

    deinit {
        autoCloseTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    private static func loadTagSortOrder() -> TagSortOrder {
        let context = CoreDataManager.shared.context
        var result: TagSortOrder = .byCount
        context.performAndWait {
            let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
            fetchRequest.fetchLimit = 1
            if let entity = try? context.fetch(fetchRequest).first,
               let raw = entity.tagSortOrder,
               let parsed = TagSortOrder(rawValue: raw) {
                result = parsed
            }
        }
        return result
    }
}
