import Foundation

@Observable
class SettingsViewModel {
    
    enum State {
        case `default`, error, success
    }
    
    var username: String = "admin"
    var password: String = "Diggah123"
    var endpoint: String = ""
    var isLoading: Bool = false
    var state: State = .default
    var showAlert: Bool = false
    
    private let loginUseCase = DefaultUseCaseFactory.shared.makeLoginUseCase()
    
    var isLoginDisabled: Bool {
        username.isEmpty || password.isEmpty || isLoading
    }
    
    @MainActor
    func login() async {
        isLoading = true
        
        do {
            let userResult = try await loginUseCase.execute(username: username, password: password)
            state = userResult.token.isEmpty ? .error : .success
            isLoading = false
        } catch {
            state = .error
            isLoading = false
        }
        
    }
}
