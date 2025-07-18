import Foundation
import Observation

@Observable
class LabelsViewModel {
    private let getLabelsUseCase = DefaultUseCaseFactory.shared.makeGetLabelsUseCase()
    
    var labels: [BookmarkLabel] = []
    var isLoading = false
    var errorMessage: String? = nil
    
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
