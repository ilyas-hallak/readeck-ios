import Foundation
import UIKit

@Observable
class AddBookmarkViewModel {
    
    // MARK: - Dependencies

    private let createBookmarkUseCase = DefaultUseCaseFactory.shared.makeCreateBookmarkUseCase()
    private let getLabelsUseCase = DefaultUseCaseFactory.shared.makeGetLabelsUseCase()
    
    // MARK: - Form Data
    var url: String = ""
    var title: String = ""
    var labelsText: String = ""
    
    // MARK: - Labels/Tags Management

    var allLabels: [BookmarkLabel] = []
    var selectedLabels: Set<String> = []
    var searchText: String = ""
    var isLabelsLoading: Bool = false
    
    // MARK: - UI State

    var isLoading: Bool = false
    var errorMessage: String?
    var showErrorAlert: Bool = false
    var hasCreated: Bool = false
    
    // MARK: - Clipboard Management
    
    var clipboardURL: String?
    var showClipboardButton: Bool = false
    
    // MARK: - Computed Properties
    
    var isValid: Bool {
        !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }
    
    var parsedLabels: [String] {
        labelsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var availableLabels: [BookmarkLabel] {
        return allLabels.filter { !selectedLabels.contains($0.name) }
    }
    
    var filteredLabels: [BookmarkLabel] {
        if searchText.isEmpty {
            return availableLabels
        } else {
            return availableLabels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: - Labels Management
    
    @MainActor
    func loadAllLabels() async {
        isLabelsLoading = true
        defer { isLabelsLoading = false }
        
        do {
            let labels = try await getLabelsUseCase.execute()
            allLabels = labels.sorted { $0.count > $1.count }
        } catch {
            errorMessage = "Failed to load labels"
            showErrorAlert = true
        }
    }
    
    @MainActor
    func addCustomTag() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let lowercased = trimmed.lowercased()
        let allExisting = Set(allLabels.map { $0.name.lowercased() })
        let allSelected = Set(selectedLabels.map { $0.lowercased() })
        
        if allExisting.contains(lowercased) || allSelected.contains(lowercased) {
            // Tag already exists, don't add
            return
        } else {
            selectedLabels.insert(trimmed)
            searchText = ""
        }
    }
    
    @MainActor
    func toggleLabel(_ label: String) {
        if selectedLabels.contains(label) {
            selectedLabels.remove(label)
        } else {
            selectedLabels.insert(label)
        }
        searchText = ""
    }
    
    @MainActor
    func removeLabel(_ label: String) {
        selectedLabels.remove(label)
    }
    
    // MARK: - Bookmark Creation
    
    @MainActor
    func createBookmark() async {
        guard isValid else { return }
        
        isLoading = true
        errorMessage = nil
        hasCreated = false
        
        do {
            let cleanURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let labels = Array(selectedLabels)
            
            let request = CreateBookmarkRequest(
                url: cleanURL,
                title: cleanTitle.isEmpty ? nil : cleanTitle,
                labels: labels.isEmpty ? nil : labels
            )
            
            let message = try await createBookmarkUseCase.execute(createRequest: request)
            
            // Optional: Show the server message
            print("Server response: \(message)")
            
            clearForm()
            hasCreated = true
        } catch let error as CreateBookmarkError {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        } catch {
            errorMessage = "Error creating bookmark"
            showErrorAlert = true
        }
        
        isLoading = false
    }
    
    // MARK: - Clipboard Management
    
    func checkClipboard() {
        guard let clipboardString = UIPasteboard.general.string,
              URL(string: clipboardString) != nil else {
            clipboardURL = nil
            showClipboardButton = false
            return
        }
        
        // Only show clipboard button if the URL is different from current URL
        let currentURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if clipboardString != currentURL {
            clipboardURL = clipboardString
            showClipboardButton = true
        } else {
            showClipboardButton = false
        }
    }
    
    func pasteFromClipboard() {
        guard let clipboardURL = clipboardURL else { return }
        url = clipboardURL
        showClipboardButton = false
    }
    
    func dismissClipboard() {
        showClipboardButton = false
    }
    
    // MARK: - Form Management
    
    func clearForm() {
        url = ""
        title = ""
        labelsText = ""
        selectedLabels.removeAll()
        searchText = ""
        clipboardURL = nil
        showClipboardButton = false
    }
}
