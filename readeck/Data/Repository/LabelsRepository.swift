import Foundation

class LabelsRepository: PLabelsRepository {
    private let api: PAPI
    
    init(api: PAPI) {
        self.api = api
    }
    
    func getLabels() async throws -> [BookmarkLabel] {
        let dtos = try await api.getBookmarkLabels()
        return dtos.map { $0.toDomain() }
    }
}
