import Foundation

class AuthRepository: PAuthRepository {
    private let api: PAPI

    init(api: PAPI) {
        self.api = api
    }
    
    func login(username: String, password: String) async throws -> User {
        let userDto = try await api.login(username: username, password: password)
        UserDefaults.standard.set(userDto.token, forKey: "token")
        UserDefaults.standard.synchronize()
        return User(id: userDto.id, token: userDto.token)
    }
    
    func logout() async throws {
        // Implement logout logic if needed
    }
    
}

struct User {
    let id: String
    let token: String
}
