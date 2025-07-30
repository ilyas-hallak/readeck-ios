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
    var currentLabels: [String] = [] {
        didSet {
            calculatePages()
        }
    }
    var newLabelText = ""
    var searchText = "" {
        didSet {
            calculatePages()
        }
    }
    
    var allLabels: [BookmarkLabel] = [] {
        didSet {
            calculatePages()
        }
    }
    
    var labelPages: [[BookmarkLabel]] = []
    
    // Computed property for available labels (excluding current labels)
    var availableLabels: [BookmarkLabel] {
        return allLabels.filter { currentLabels.contains($0.name) == false }
    }
    
    // Computed property for filtered labels based on search text
    var filteredLabels: [BookmarkLabel] {
        if searchText.isEmpty {
            return availableLabels
        } else {
            return availableLabels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var availableLabelPages: [[BookmarkLabel]] = []
    
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
        
        calculatePages()
    }
    
    @MainActor
    func addLabels(to bookmarkId: String, labels: [String]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentLabels.append(contentsOf: labels)
            currentLabels = Array(Set(currentLabels)) // Remove duplicates

            try await addLabelsUseCase.execute(bookmarkId: bookmarkId, labels: labels)
        } catch let error as BookmarkUpdateError {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        } catch {
            errorMessage = "Error adding labels"
            showErrorAlert = true
        }
        
        isLoading = false
        calculatePages()
    }
    
    @MainActor
    func addLabel(to bookmarkId: String, label: String) async {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLabel.isEmpty else { return }
        
        await addLabels(to: bookmarkId, labels: [trimmedLabel])
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
        calculatePages()
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
        
        calculatePages()
    }
    
    func updateLabels(_ labels: [String]) {
        currentLabels = labels
    }
    
    private func calculatePages() {
        let pageSize = Constants.Labels.pageSize
        
        // Calculate pages for all labels
        if allLabels.count <= pageSize {
            labelPages = [allLabels]
        } else {
            // Normal pagination for larger datasets
            labelPages = stride(from: 0, to: allLabels.count, by: pageSize).map {
                Array(allLabels[$0..<min($0 + pageSize, allLabels.count)])
            }
        }
        
        // Calculate pages for filtered labels (search results or available labels)
        let labelsToShow = searchText.isEmpty ? availableLabels : filteredLabels
        if labelsToShow.count <= pageSize {
            availableLabelPages = [labelsToShow]
        } else {
            // Normal pagination for larger datasets
            availableLabelPages = stride(from: 0, to: labelsToShow.count, by: pageSize).map {
                Array(labelsToShow[$0..<min($0 + pageSize, labelsToShow.count)])
            }
        }
    }
}
