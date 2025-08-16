import Foundation

protocol PLabelsRepository {
    func getLabels() async throws -> [BookmarkLabel]
    func saveLabels(_ dtos: [BookmarkLabelDto]) async throws
}
