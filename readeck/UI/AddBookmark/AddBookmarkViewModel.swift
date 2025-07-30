import Foundation
import UIKit

@Observable
class AddBookmarkViewModel {
    private let createBookmarkUseCase = DefaultUseCaseFactory.shared.makeCreateBookmarkUseCase()
    
    var url: String = ""
    var title: String = ""
    var labelsText: String = ""
    
    var isLoading: Bool = false
    var errorMessage: String?
    var showErrorAlert: Bool = false
    var hasCreated: Bool = false
    var clipboardURL: String?
    var showClipboardButton: Bool = false
    
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
    
    @MainActor
    func createBookmark() async {
        guard isValid else { return }
        
        isLoading = true
        errorMessage = nil
        hasCreated = false
        
        do {
            let cleanURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let labels = parsedLabels
            
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
    
    func clearForm() {
        url = ""
        title = ""
        labelsText = ""
        clipboardURL = nil
        showClipboardButton = false
    }
}
