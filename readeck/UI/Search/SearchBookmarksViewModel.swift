import Foundation
import Combine
import SwiftUI

@Observable
class SearchBookmarksViewModel {
    private let searchBookmarksUseCase = DefaultUseCaseFactory.shared.makeSearchBookmarksUseCase()
    
    var searchQuery: String = "" {
        didSet {
            throttleSearch()
        }
    }
    var bookmarks: BookmarksPage? = nil
    var isLoading = false
    var errorMessage: String? = nil
    
    private var searchWorkItem: DispatchWorkItem?
    
    private func throttleSearch() {
        searchWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Task {
                await self.search()
            }
        }
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    @MainActor
    func search() async {
        guard !searchQuery.isEmpty else {
            bookmarks = nil
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await searchBookmarksUseCase.execute(search: searchQuery)
            bookmarks = result
        } catch {
            errorMessage = "Fehler bei der Suche"
            bookmarks = nil
        }
        isLoading = false
    }
} 