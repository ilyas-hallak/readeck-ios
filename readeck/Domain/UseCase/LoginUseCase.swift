
class LoginUseCase {
    private let repository: PAuthRepository

    init(repository: PAuthRepository) {
        self.repository = repository
    }

    func execute(username: String, password: String) async throws -> User {
        return try await repository.login(username: username, password: password)
    }
}
