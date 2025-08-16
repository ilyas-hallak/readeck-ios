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
    
    // Computed properties for pagination
    var availableLabels: [BookmarkLabelDto] {
        return labels.filter { !selectedLabels.contains($0.name) }
    }
    
    // Computed property for filtered labels based on search text
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
        extractSharedContent()
    }
    
    func onAppear() {
        checkServerReachability()
        loadLabels()
    }
    
    private func checkServerReachability() {
        isServerReachable = ServerConnectivity.isServerReachableSync()
    }
    
    private func extractSharedContent() {
        guard let extensionContext = extensionContext else { return }
        for item in extensionContext.inputItems {
            guard let inputItem = item as? NSExtensionItem else { continue }
            for attachment in inputItem.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (url, error) in
                        DispatchQueue.main.async {
                            if let url = url as? URL {
                                self?.url = url.absoluteString
                            }
                        }
                    }
                }
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (text, error) in
                        DispatchQueue.main.async {
                            if let text = text as? String, let url = URL(string: text) {
                                self?.url = url.absoluteString
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadLabels() {
        Task {
            // Check if server is reachable
            let serverReachable = ServerConnectivity.isServerReachableSync()
            print("DEBUG: Server reachable: \(serverReachable)")
            
            if serverReachable {
                // Load from API
                let loaded = await SimpleAPI.getBookmarkLabels { [weak self] message, error in
                    self?.statusMessage = (message, error, error ? "❌" : "✅")
                } ?? []
                let sorted = loaded.sorted { $0.count > $1.count }
                await MainActor.run {
                    self.labels = Array(sorted)
                    print("DEBUG: Loaded \(loaded.count) labels from API")
                }
            } else {
                // Load from local database
                let localTags = OfflineBookmarkManager.shared.getTags()
                let localLabels = localTags.enumerated().map { index, tagName in 
                    BookmarkLabelDto(name: tagName, count: 0, href: "local://\(index)")
                }
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                await MainActor.run {
                    self.labels = localLabels
                }
            }
        }
    }
    
    func save() {
        guard let url = url, !url.isEmpty else {
            statusMessage = ("No URL found.", true, "❌")
            return
        }
        isSaving = true
        
        // Check server connectivity
        if ServerConnectivity.isServerReachableSync() {
            // Online - try to save via API
            Task {
                await SimpleAPI.addBookmark(title: title, url: url, labels: Array(selectedLabels)) { [weak self] message, error in
                    self?.statusMessage = (message, error, error ? "❌" : "✅")
                    self?.isSaving = false
                    if !error {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                        }
                    }
                }
            }
        } else {
            // Server not reachable - save locally
            let success = OfflineBookmarkManager.shared.saveOfflineBookmark(
                url: url,
                title: title,
                tags: Array(selectedLabels)
            )
            
            DispatchQueue.main.async {
                self.isSaving = false
                if success {
                    self.statusMessage = ("Server not reachable. Saved locally and will sync later.", false, "🏠")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    }
                } else {
                    self.statusMessage = ("Failed to save locally.", true, "❌")
                }
            }
        }
    }
} 
