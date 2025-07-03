class LoginUseCase {
    private let repository: PAuthRepository

    init(repository: PAuthRepository) {
        self.repository = repository
    }

    func execute(endpoint: String, username: String, password: String) async throws -> User {
        return try await repository.login(endpoint: endpoint, username: username, password: password)
    }
}
