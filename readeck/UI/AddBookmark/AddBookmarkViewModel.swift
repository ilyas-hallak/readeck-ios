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
    var showSuccessAlert: Bool = false
    var clipboardURL: String?
    
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
            
            // Optional: Zeige die Server-Nachricht an
            print("Server response: \(message)")
            
            showSuccessAlert = true
            
        } catch let error as CreateBookmarkError {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        } catch {
            errorMessage = "Fehler beim Erstellen des Bookmarks"
            showErrorAlert = true
        }
        
        isLoading = false
    }
    
    func checkClipboard() {
        guard let clipboardString = UIPasteboard.general.string,
              URL(string: clipboardString) != nil else {
            clipboardURL = nil
            return
        }
        
        clipboardURL = clipboardString
    }
    
    func pasteFromClipboard() {
        guard let clipboardURL = clipboardURL else { return }
        url = clipboardURL
    }
}