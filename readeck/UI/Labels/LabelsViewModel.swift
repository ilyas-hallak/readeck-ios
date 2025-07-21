import Foundation
import Observation

@Observable
class LabelsViewModel {
    private let getLabelsUseCase: PGetLabelsUseCase
    
    var labels: [BookmarkLabel] = []
    var isLoading: Bool
    var errorMessage: String?
    
    init(factory: UseCaseFactory = DefaultUseCaseFactory.shared, labels: [BookmarkLabel] = [], isLoading: Bool = false, errorMessage: String? = nil) {
        self.labels = labels
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        getLabelsUseCase = factory.makeGetLabelsUseCase()
    }
    
    @MainActor
    func loadLabels() async {
        isLoading = true
        errorMessage = nil
        do {
            labels = try await getLabelsUseCase.execute()
        } catch  {
            errorMessage = "Error loading labels"
        }
        isLoading = false
    }
} 
