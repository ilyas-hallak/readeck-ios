//
//  CachedArticlesPreviewView.swift
//  readeck
//
//  Created by Ilyas Hallak on 30.11.25.
//

import SwiftUI

struct CachedArticlesPreviewView: View {
    // MARK: - State

    @State private var viewModel = CachedArticlesPreviewViewModel()
    @State private var selectedBookmarkId: String?
    @EnvironmentObject private var appSettings: AppSettings

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.cachedBookmarks.isEmpty {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else if viewModel.cachedBookmarks.isEmpty {
                emptyStateView
            } else {
                cachedBookmarksList
            }
        }
        .navigationTitle("Cached Articles".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            item: Binding<String?>(
                get: { selectedBookmarkId },
                set: { selectedBookmarkId = $0 }
            )
        ) { bookmarkId in
            BookmarkDetailView(bookmarkId: bookmarkId)
                .toolbar(.hidden, for: .tabBar)
        }
        .task {
            await viewModel.loadCachedBookmarks()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var cachedBookmarksList: some View {
        List {
            Section {
                ForEach(viewModel.cachedBookmarks, id: \.id) { bookmark in
                    Button(action: {
                        selectedBookmarkId = bookmark.id
                    }) {
                        BookmarkCardView(
                            bookmark: bookmark,
                            currentState: .unread,
                            layout: .magazine,
                            onSwipeAction: { _, _ in }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets(
                        top: 12,
                        leading: 16,
                        bottom: 12,
                        trailing: 16
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(R.color.bookmark_list_bg))
                }
            } header: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(String(format: "%lld articles cached".localized, viewModel.cachedBookmarks.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .textCase(nil)
                .padding(.bottom, 4)
            } footer: {
                Text("These articles are available offline. You can read them without an internet connection.".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .background(Color(R.color.bookmark_list_bg))
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.refreshList()
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(.accentColor)

            VStack(spacing: 8) {
                Text("Loading Cached Articles".localized)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Please wait...".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(R.color.bookmark_list_bg))
    }

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            VStack(spacing: 8) {
                Text("Unable to load cached articles".localized)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Try Again".localized) {
                Task {
                    await viewModel.loadCachedBookmarks()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(R.color.bookmark_list_bg))
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Cached Articles".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Enable offline reading and sync to cache articles for offline access".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Hint
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                    Text("Use 'Sync Now' to download articles".localized)
                        .font(.caption)
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(R.color.bookmark_list_bg))
    }
}

#Preview {
    NavigationStack {
        CachedArticlesPreviewView()
            .environmentObject(AppSettings())
    }
}
