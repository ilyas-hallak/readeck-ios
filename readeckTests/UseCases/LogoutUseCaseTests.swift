import Testing
import Foundation
@testable import readeck

@Suite("LogoutUseCase")
struct LogoutUseCaseTests {
    @Test("execute logs out through the repository and resets hasFinishedSetup")
    func executeLogsOutAndResetsSetup() async throws {
        let authRepository = ConfigurableAuthRepository()
        let settingsRepository = RecordingSettingsRepository()
        settingsRepository.hasFinishedSetup = true
        let useCase = LogoutUseCase(authRepository: authRepository, settingsRepository: settingsRepository)

        try await useCase.execute()

        #expect(authRepository.logoutCallCount == 1)
        #expect(settingsRepository.hasFinishedSetup == false)
    }

    @Test("execute propagates a failing repository logout")
    func executePropagatesRepositoryError() async throws {
        let authRepository = ConfigurableAuthRepository()
        authRepository.logoutError = APIError.serverError(500)
        let settingsRepository = RecordingSettingsRepository()
        let useCase = LogoutUseCase(authRepository: authRepository, settingsRepository: settingsRepository)

        await #expect(throws: APIError.serverError(500)) {
            try await useCase.execute()
        }
    }
}
