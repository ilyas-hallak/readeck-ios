import Foundation

@Observable
class BookmarkLabelsViewModel {
    private let addLabelsUseCase = DefaultUseCaseFactory.shared.makeAddLabelsToBookmarkUseCase()
    private let removeLabelsUseCase = DefaultUseCaseFactory.shared.makeRemoveLabelsFromBookmarkUseCase()
    
    var isLoading = false
    var errorMessage: String?
    var showErrorAlert = false
    var currentLabels: [String] = []
    var newLabelText = ""
    
    init(initialLabels: [String] = []) {
        self.currentLabels = initialLabels
    }
    
    @MainActor
    func addLabels(to bookmarkId: String, labels: [String]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await addLabelsUseCase.execute(bookmarkId: bookmarkId, labels: labels)
            // Update local labels
            currentLabels.append(contentsOf: labels)
            currentLabels = Array(Set(currentLabels)) // Remove duplicates
        } catch let error as BookmarkUpdateError {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        } catch {
            errorMessage = "Fehler beim Hinzufügen der Labels"
            showErrorAlert = true
        }
        
        isLoading = false
    }
    
    @MainActor
    func addLabel(to bookmarkId: String, label: String) async {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty else { return }
        
        await addLabels(to: bookmarkId, labels: [trimmedLabel])
        newLabelText = ""
    }
    
    @MainActor
    func removeLabels(from bookmarkId: String, labels: [String]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await removeLabelsUseCase.execute(bookmarkId: bookmarkId, labels: labels)
            // Update local labels
            currentLabels.removeAll { labels.contains($0) }
        } catch let error as BookmarkUpdateError {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        } catch {
            errorMessage = "Fehler beim Entfernen der Labels"
            showErrorAlert = true
        }
        
        isLoading = false
    }
    
    @MainActor
    func removeLabel(from bookmarkId: String, label: String) async {
        await removeLabels(from: bookmarkId, labels: [label])
    }
    
    // Convenience method für das Umschalten eines Labels (hinzufügen wenn nicht vorhanden, entfernen wenn vorhanden)
    @MainActor
    func toggleLabel(for bookmarkId: String, label: String) async {
        if currentLabels.contains(label) {
            await removeLabel(from: bookmarkId, label: label)
        } else {
            await addLabel(to: bookmarkId, label: label)
        }
    }
    
    func updateLabels(_ labels: [String]) {
        currentLabels = labels
    }
} 