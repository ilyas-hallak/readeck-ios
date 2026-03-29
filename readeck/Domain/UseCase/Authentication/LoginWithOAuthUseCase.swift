import Foundation

#if os(iOS) && !APP_EXTENSION

protocol PLoginWithOAuthUseCase {
    func execute(endpoint: String) async throws -> (OAuthToken, String)
}

final class LoginWithOAuthUseCase: PLoginWithOAuthUseCase {
    private let oauthCoordinator: OAuthFlowCoordinator

    init(oauthCoordinator: OAuthFlowCoordinator) {
        self.oauthCoordinator = oauthCoordinator
    }

    func execute(endpoint: String) async throws -> (OAuthToken, String) {
        try await oauthCoordinator.executeOAuthFlow(endpoint: endpoint)
    }
}

#endif
