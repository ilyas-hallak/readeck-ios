//
//  CachedArticlesPreviewViewModel.swift
//  readeck
//
//  Created by Claude on 30.11.25.
//

import Foundation
import SwiftUI

@Observable
class CachedArticlesPreviewViewModel {

    // MARK: - Dependencies

    private let getCachedBookmarksUseCase: PGetCachedBookmarksUseCase

    // MARK: - Published State

    var cachedBookmarks: [Bookmark] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Initialization

    init(_ factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.getCachedBookmarksUseCase = factory.makeGetCachedBookmarksUseCase()
    }

    // MARK: - Public Methods

    @MainActor
    func loadCachedBookmarks() async {
        isLoading = true
        errorMessage = nil

        do {
            Logger.viewModel.info("📱 CachedArticlesPreviewViewModel: Loading cached bookmarks...")
            cachedBookmarks = try await getCachedBookmarksUseCase.execute()
            Logger.viewModel.info("✅ Loaded \(cachedBookmarks.count) cached bookmarks for preview")
        } catch {
            Logger.viewModel.error("❌ Failed to load cached bookmarks: \(error.localizedDescription)")
            errorMessage = "Failed to load cached articles"
        }

        isLoading = false
    }

    @MainActor
    func refreshList() async {
        await loadCachedBookmarks()
    }
}
