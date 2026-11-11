import Foundation
import Testing
@testable import readeck

@Suite("SettingsServerViewModel login method")
@MainActor
struct SettingsServerViewModelTests {
    private let factory = TestUseCaseFactory()

    @Test("failed server check shows an error and no login method")
    func failedServerCheck() async {
        factory.mockDetectLoginMethod.result = .failure(URLError(.timedOut))
        let viewModel = makeViewModel()

        let method = await viewModel.checkLoginMethod()

        #expect(method == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("successful server check returns the method without an error")
    func successfulServerCheck() async {
        factory.mockDetectLoginMethod.result = .success(.oauth)
        let viewModel = makeViewModel()

        let method = await viewModel.checkLoginMethod()

        #expect(method == .oauth)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("password login on a server without /api/auth asks for OAuth instead of failing")
    func passwordLoginEndpointMissing() async {
        factory.mockLogin.result = .failure(APIError.endpointNotAvailable)
        let viewModel = makeViewModel()
        viewModel.username = "user"
        viewModel.password = "secret"

        await viewModel.saveServerSettings()

        #expect(viewModel.serverRequiresOAuth)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoggedIn == false)
    }

    @Test("other password login errors are shown")
    func passwordLoginFails() async {
        factory.mockLogin.result = .failure(APIError.serverError(401))
        let viewModel = makeViewModel()
        viewModel.username = "user"
        viewModel.password = "wrong"

        await viewModel.saveServerSettings()

        #expect(viewModel.serverRequiresOAuth == false)
        #expect(viewModel.errorMessage != nil)
    }

    private func makeViewModel() -> SettingsServerViewModel {
        let viewModel = SettingsServerViewModel(factory)
        viewModel.endpoint = "http://192.168.1.205:8000"
        return viewModel
    }
}
