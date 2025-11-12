import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CoreData

class ShareBookmarkViewModel: ObservableObject {
    @Published var url: String?
    @Published var title: String = ""
    @Published var selectedLabels: Set<String> = []
    @Published var statusMessage: (text: String, isError: Bool, emoji: String)? = nil
    @Published var isSaving: Bool = false
    @Published var searchText: String = ""
    @Published var isServerReachable: Bool = true
    let tagSortOrder: TagSortOrder = .byCount  // Share Extension always uses byCount
    let extensionContext: NSExtensionContext?

    private let logger = Logger.viewModel
    private let serverCheck = ShareExtensionServerCheck.shared
    private let tagRepository = TagRepository()

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
        logger.info("ShareBookmarkViewModel initialized with extension context: \(extensionContext != nil)")
        extractSharedContent()
    }
    
    private func extractSharedContent() {
        logger.debug("Starting to extract shared content")
        guard let extensionContext = extensionContext else { 
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
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
                        DispatchQueue.main.async {
                            if let url = url as? URL {
                                self?.url = url.absoluteString
                                self?.logger.info("Extracted URL from shared content: \(url.absoluteString)")
                                
                                // Set title if we extracted one and current title is empty
                                if let title = extractedTitle, self?.title.isEmpty == true {
                                    self?.title = title
                                    self?.logger.info("Set title from shared content: \(title)")
                                }
                            } else if let error = error {
                                self?.logger.error("Failed to extract URL: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (text, error) in
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
                            } else if let error = error {
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
        guard let url = url, !url.isEmpty else {
            logger.warning("Save attempted without valid URL")
            statusMessage = ("No URL found.", true, "❌")
            return
        }
        isSaving = true
        logger.debug("Set saving state to true")

        // Check server connectivity
        Task {
            let serverReachable = await serverCheck.checkServerReachability()
            logger.debug("Server connectivity for save: \(serverReachable)")
            if serverReachable {
                // Online - try to save via API
                logger.info("Attempting to save bookmark via API")
                await SimpleAPI.addBookmark(title: title, url: url, labels: Array(selectedLabels)) { [weak self] message, error in
                    self?.logger.info("API save completed - Success: \(!error), Message: \(message)")
                    self?.statusMessage = (message, error, error ? "❌" : "✅")
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
            } else {
                // Server not reachable - save locally
                logger.info("Server not reachable, attempting local save")
                let success = OfflineBookmarkManager.shared.saveOfflineBookmark(
                    url: url,
                    title: title,
                    tags: Array(selectedLabels)
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
        let availableLabels = (try? context.fetch(fetchRequest))?.compactMap { $0.name } ?? []

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
} 
