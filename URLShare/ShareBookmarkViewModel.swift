import Foundation
import SwiftUI
import UniformTypeIdentifiers

class ShareBookmarkViewModel: ObservableObject {
    @Published var url: String?
    @Published var title: String = ""
    @Published var labels: [BookmarkLabelDto] = []
    @Published var selectedLabels: Set<String> = []
    @Published var statusMessage: (text: String, isError: Bool, emoji: String)? = nil
    @Published var isSaving: Bool = false
    private weak var extensionContext: NSExtensionContext?
    
    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
        extractSharedContent()
    }
    
    func onAppear() {
        loadLabels()
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
            let loaded = await SimpleAPI.getBookmarkLabels { [weak self] message, error in
                self?.statusMessage = (message, error, error ? "❌" : "✅")
            } ?? []
            let sorted = loaded.prefix(10).sorted { $0.count > $1.count }
            await MainActor.run {
                self.labels = Array(sorted)
            }
        }
    }
    
    func save() {
        guard let url = url, !url.isEmpty else {
            statusMessage = ("No URL found.", true, "❌")
            return
        }
        isSaving = true
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
    }
} 
