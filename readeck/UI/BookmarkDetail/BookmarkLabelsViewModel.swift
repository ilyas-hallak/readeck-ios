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
            if oldValue != currentLabels {
                calculatePages()
            }
        }
    }
    var newLabelText = ""
    var searchText = "" {
        didSet {
            if oldValue != searchText {
                calculatePages()
            }
        }
    }
    
    var allLabels: [BookmarkLabel] = [] {
        didSet {
            if oldValue != allLabels {
                calculatePages()
            }
        }
    }
    
    var labelPages: [[BookmarkLabel]] = []
    
    // Cached properties to avoid recomputation
    private var _availableLabels: [BookmarkLabel] = []
    private var _filteredLabels: [BookmarkLabel] = []
    
    var availableLabels: [BookmarkLabel] {
        return _availableLabels
    }
    
    var filteredLabels: [BookmarkLabel] {
        return _filteredLabels
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
    
    private func calculatePages() {
        let pageSize = Constants.Labels.pageSize
        
        // Update cached available labels
        _availableLabels = allLabels.filter { !currentLabels.contains($0.name) }
        
        // Update cached filtered labels
        if searchText.isEmpty {
            _filteredLabels = _availableLabels
        } else {
            _filteredLabels = _availableLabels.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Calculate pages for all labels
        if allLabels.count <= pageSize {
            labelPages = [allLabels]
        } else {
            labelPages = stride(from: 0, to: allLabels.count, by: pageSize).map {
                Array(allLabels[$0..<min($0 + pageSize, allLabels.count)])
            }
        }
        
        // Calculate pages for filtered labels
        if _filteredLabels.count <= pageSize {
            availableLabelPages = [_filteredLabels]
        } else {
            availableLabelPages = stride(from: 0, to: _filteredLabels.count, by: pageSize).map {
                Array(_filteredLabels[$0..<min($0 + pageSize, _filteredLabels.count)])
            }
        }
    }
}
