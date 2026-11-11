import Foundation

protocol PDetectLoginMethodUseCase: Sendable {
    /// Throws when the server could not be asked, for example on a timeout.
    /// Callers must not fall back to the password login then, it is gone from 0.22.0 on.
    func execute(endpoint: String) async throws -> LoginMethod
}

final class DetectLoginMethodUseCase: PDetectLoginMethodUseCase {
    private static let oauthFeature = "oauth"

    private let repository: PServerInfoRepository

    init(repository: PServerInfoRepository) {
        self.repository = repository
    }

    func execute(endpoint: String) async throws -> LoginMethod {
        let capabilities: ServerCapabilities
        do {
            capabilities = try await repository.getServerInfo(endpoint: endpoint).capabilities
        } catch APIError.endpointNotAvailable {
            // Servers before 0.20.0 have no /api/info and only know the password login.
            return .password
        }

        let hasOAuth = capabilities.features.contains(Self.oauthFeature)
        return hasOAuth || !capabilities.canUsePasswordLogin ? .oauth : .password
    }
}
