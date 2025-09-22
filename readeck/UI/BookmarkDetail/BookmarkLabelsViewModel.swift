import Foundation

@Observable
class BookmarkLabelsViewModel {
    private let addLabelsUseCase: PAddLabelsToBookmarkUseCase
    private let removeLabelsUseCase: PRemoveLabelsFromBookmarkUseCase
    private let getLabelsUseCase: PGetLabelsUseCase
    
    var isLoading = false
    var isInitialLoading = false
    var errorMessage: String?
    var showErrorAlert = false
    var currentLabels: [String] = []
    var newLabelText = ""
    var searchText = ""
    
    var allLabels: [BookmarkLabel] = []
    
    var availableLabels: [BookmarkLabel] {
        return allLabels.filter { !currentLabels.contains($0.name) }
    }
    
    var filteredLabels: [BookmarkLabel] {
        if searchText.isEmpty {
            return availableLabels
        } else {
            return availableLabels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared, initialLabels: [String] = []) {
        self.currentLabels = initialLabels
        
        self.addLabelsUseCase = factory.makeAddLabelsToBookmarkUseCase()
        self.removeLabelsUseCase = factory.makeRemoveLabelsFromBookmarkUseCase()
        self.getLabelsUseCase = factory.makeGetLabelsUseCase()
        
    }
    
    @MainActor
    func loadAllLabels() async {
        isInitialLoading = true
        defer { isInitialLoading = false }
        do {
            let labels = try await getLabelsUseCase.execute()
            allLabels = labels
        } catch {
            errorMessage = "failed to load labels"
            showErrorAlert = true
        }
    }
    
    @MainActor
    func addLabels(to bookmarkId: String, labels: [String]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let uniqueLabels = Set(currentLabels + labels)
            currentLabels = currentLabels.filter { uniqueLabels.contains($0) } + labels.filter { !currentLabels.contains($0) }

            try await addLabelsUseCase.execute(bookmarkId: bookmarkId, labels: labels)
        } catch let error as BookmarkUpdateError {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        } catch {
            errorMessage = "Error adding labels"
            showErrorAlert = true
        }
        
        isLoading = false
    }
    
    @MainActor
    func addLabel(to bookmarkId: String, label: String) async {
        let splitLabels = LabelUtils.splitLabelsFromInput(label)
        let uniqueLabels = LabelUtils.filterUniqueLabels(splitLabels, currentLabels: currentLabels)
        
        guard !uniqueLabels.isEmpty else { return }
        
        await addLabels(to: bookmarkId, labels: uniqueLabels)
        newLabelText = ""
        searchText = ""
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
            errorMessage = "Error removing labels"
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
