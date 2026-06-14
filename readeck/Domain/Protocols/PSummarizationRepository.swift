import Foundation

protocol PSummarizationRepository {
    static var isAvailable: Bool { get }
    static var supportedLanguages: [String] { get }
    func summarize(text: String, instructions: String) async throws -> String
    func prewarm()
}
