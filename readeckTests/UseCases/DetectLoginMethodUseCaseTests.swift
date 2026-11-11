import Foundation
import Testing
@testable import readeck

@Suite("DetectLoginMethodUseCase")
struct DetectLoginMethodUseCaseTests {
    @Test("server with the oauth feature uses OAuth")
    func oauthFeature() async throws {
        let useCase = makeUseCase(.success(ServerInfo(version: "0.23.5", isReachable: true, features: ["oauth"])))

        #expect(try await useCase.execute(endpoint: "http://192.168.1.205:8000") == .oauth)
    }

    @Test("server from 0.22 on uses OAuth even without the feature, it has no password login")
    func newServerWithoutFeature() async throws {
        let useCase = makeUseCase(.success(ServerInfo(version: "0.22.0", isReachable: true, features: nil)))

        #expect(try await useCase.execute(endpoint: "http://192.168.1.205:8000") == .oauth)
    }

    @Test("server without the oauth feature uses the password")
    func passwordOnlyServer() async throws {
        let useCase = makeUseCase(.success(ServerInfo(version: "0.20.4", isReachable: true, features: nil)))

        #expect(try await useCase.execute(endpoint: "http://192.168.1.205:8000") == .password)
    }

    @Test("server without /api/info uses the password")
    func serverWithoutInfoEndpoint() async throws {
        let useCase = makeUseCase(.failure(APIError.endpointNotAvailable))

        #expect(try await useCase.execute(endpoint: "http://192.168.1.205:8000") == .password)
    }

    @Test("unreachable server is an error, not a reason to use the password", arguments: [
        URLError(.timedOut) as Error,
        URLError(.notConnectedToInternet) as Error,
        APIError.serverError(502) as Error
    ])
    func unreachableServer(error: Error) async {
        let useCase = makeUseCase(.failure(error))

        await #expect(throws: (any Error).self) {
            _ = try await useCase.execute(endpoint: "http://192.168.1.205:8000")
        }
    }

    private func makeUseCase(_ result: Result<ServerInfo, Error>) -> DetectLoginMethodUseCase {
        DetectLoginMethodUseCase(repository: StubServerInfoRepository(result: result))
    }
}

private struct StubServerInfoRepository: PServerInfoRepository, @unchecked Sendable {
    let result: Result<ServerInfo, Error>

    func checkServerReachability() async -> Bool {
        (try? result.get()) != nil
    }

    func getServerInfo(endpoint: String?) async throws -> ServerInfo {
        try result.get()
    }
}
