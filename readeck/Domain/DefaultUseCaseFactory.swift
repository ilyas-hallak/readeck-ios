import Foundation

protocol UseCaseFactory {
    func makeLoginUseCase() -> LoginUseCase
    func makeGetBooksmarksUseCase() -> GetBooksmarksUseCase
}

class DefaultUseCaseFactory: UseCaseFactory {
    private let api: PAPI
    
    static let shared = DefaultUseCaseFactory()
    
    init(api: PAPI = API(baseURL: "https://keep.mnk.any64.de/api")) {
        self.api = api
    }
    
    func makeLoginUseCase() -> LoginUseCase {
        LoginUseCase(repository: AuthRepository(api: api))
    }
    
    func makeGetBooksmarksUseCase() -> GetBooksmarksUseCase {
        GetBooksmarksUseCase(repository: .init(api: api))
    }
}
