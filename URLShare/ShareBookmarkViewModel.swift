import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CoreData

class ShareBookmarkViewModel: ObservableObject {
    @Published var url: String?
    @Published var title: String = ""
    @Published var labels: [BookmarkLabelDto] = []
    @Published var selectedLabels: Set<String> = []
    @Published var statusMessage: (text: String, isError: Bool, emoji: String)? = nil
    @Published var isSaving: Bool = false
    @Published var searchText: String = ""
    @Published var isServerReachable: Bool = true
    let extensionContext: NSExtensionContext?
    
    private let logger = Logger.viewModel
        
    var availableLabels: [BookmarkLabelDto] {
        return labels.filter { !selectedLabels.contains($0.name) }
    }
    
    // filtered labels based on search text
    var filteredLabels: [BookmarkLabelDto] {
        if searchText.isEmpty {
            return availableLabels
        } else {
            return availableLabels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var availableLabelPages: [[BookmarkLabelDto]] {
        let pageSize = 12 // Extension can't access Constants.Labels.pageSize
        let labelsToShow = searchText.isEmpty ? availableLabels : filteredLabels
        
        if labelsToShow.count <= pageSize {
            return [labelsToShow]
        } else {
            return stride(from: 0, to: labelsToShow.count, by: pageSize).map {
                Array(labelsToShow[$0..<min($0 + pageSize, labelsToShow.count)])
            }
        }
    }
    
    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
        logger.info("ShareBookmarkViewModel initialized with extension context: \(extensionContext != nil)")
        extractSharedContent()
    }
    
    func onAppear() {
        logger.debug("ShareBookmarkViewModel appeared")
        checkServerReachability()
        loadLabels()
    }
    
    private func checkServerReachability() {
        let measurement = PerformanceMeasurement(operation: "checkServerReachability", logger: logger)
        isServerReachable = ServerConnectivity.isServerReachableSync()
        logger.info("Server reachability checked: \(isServerReachable)")
        measurement.end()
    }
    
    private func extractSharedContent() {
        logger.debug("Starting to extract shared content")
        guard let extensionContext = extensionContext else { 
            logger.warning("No extension context available for content extraction")
            return 
        }
        for item in extensionContext.inputItems {
            guard let inputItem = item as? NSExtensionItem else { continue }
            for attachment in inputItem.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
                        DispatchQueue.main.async {
                            if let url = url as? URL {
                                self?.url = url.absoluteString
                                self?.logger.info("Extracted URL from shared content: \(url.absoluteString)")
                            } else if let error = error {
                                self?.logger.error("Failed to extract URL: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (text, error) in
                        DispatchQueue.main.async {
                            if let text = text as? String, let url = URL(string: text) {
                                self?.url = url.absoluteString
                                self?.logger.info("Extracted URL from shared text: \(url.absoluteString)")
                            } else if let error = error {
                                self?.logger.error("Failed to extract text: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadLabels() {
        let measurement = PerformanceMeasurement(operation: "loadLabels", logger: logger)
        logger.debug("Starting to load labels")
        Task {
            let serverReachable = ServerConnectivity.isServerReachableSync()
            logger.debug("Server reachable for labels: \(serverReachable)")
            
            if serverReachable {
                let loaded = await SimpleAPI.getBookmarkLabels { [weak self] message, error in
                    self?.statusMessage = (message, error, error ? "❌" : "✅")
                } ?? []
                let sorted = loaded.sorted { $0.count > $1.count }
                await MainActor.run {
                    self.labels = Array(sorted)
                    self.logger.info("Loaded \(loaded.count) labels from API")
                    measurement.end()
                }
            } else {
                let localTags = OfflineBookmarkManager.shared.getTags()
                let localLabels = localTags.enumerated().map { index, tagName in 
                    BookmarkLabelDto(name: tagName, count: 0, href: "local://\(index)")
                }
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                await MainActor.run {
                    self.labels = localLabels
                    self.logger.info("Loaded \(localLabels.count) labels from local database")
                    measurement.end()
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
        let serverReachable = ServerConnectivity.isServerReachableSync()
        logger.debug("Server connectivity for save: \(serverReachable)")
        if serverReachable {
            // Online - try to save via API
            logger.info("Attempting to save bookmark via API")
            Task {
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
            
            DispatchQueue.main.async {
                self.isSaving = false
                if success {
                    self.logger.info("Bookmark saved locally successfully")
                    self.statusMessage = ("Server not reachable. Saved locally and will sync later.", false, "🏠")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.completeExtensionRequest()
                    }
                } else {
                    self.logger.error("Failed to save bookmark locally")
                    self.statusMessage = ("Failed to save locally.", true, "❌")
                }
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
} 
