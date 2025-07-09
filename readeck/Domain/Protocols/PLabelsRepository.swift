import Foundation

protocol PLabelsRepository {
    func getLabels() async throws -> [BookmarkLabel]
} 
