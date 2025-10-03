//
//  PhoneTabView.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.07.25.
//

import SwiftUI

struct PhoneTabView: View {
    private let mainTabs: [SidebarTab] = [.all, .unread, .favorite, .archived]
    private let moreTabs: [SidebarTab] = [.article, .videos, .pictures, .tags, .settings]

    @State private var selectedMoreTab: SidebarTab? = nil
    @State private var selectedTab: SidebarTab = .unread
    @State private var offlineBookmarksViewModel = OfflineBookmarksViewModel(syncUseCase: DefaultUseCaseFactory.shared.makeOfflineBookmarkSyncUseCase())

    // Navigation paths for each tab
    @State private var allPath = NavigationPath()
    @State private var unreadPath = NavigationPath()
    @State private var favoritePath = NavigationPath()
    @State private var archivedPath = NavigationPath()
    @State private var searchPath = NavigationPath()
    @State private var morePath = NavigationPath()

    // Search functionality
    @State private var searchViewModel = SearchBookmarksViewModel()
    @FocusState private var searchFieldIsFocused: Bool

    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        GlobalPlayerContainerView {
            TabView(selection: $selectedTab) {

                Tab(value: SidebarTab.all) {
                    NavigationStack(path: $allPath) {
                        tabView(for: .all)
                    }
                } label: {
                    Label(SidebarTab.all.label, systemImage: SidebarTab.all.systemImage)
                }

                Tab(value: SidebarTab.unread) {
                    NavigationStack(path: $unreadPath) {
                        tabView(for: .unread)
                    }
                } label: {
                    Label(SidebarTab.unread.label, systemImage: SidebarTab.unread.systemImage)
                }

                Tab(value: SidebarTab.favorite) {
                    NavigationStack(path: $favoritePath) {
                        tabView(for: .favorite)
                    }
                } label: {
                    Label(SidebarTab.favorite.label, systemImage: SidebarTab.favorite.systemImage)
                }

                Tab(value: SidebarTab.archived) {
                    NavigationStack(path: $archivedPath) {
                        tabView(for: .archived)
                    }
                } label: {
                    Label(SidebarTab.archived.label, systemImage: SidebarTab.archived.systemImage)
                }

                // iOS 26+: Dedicated search tab with role
                if #available(iOS 26, *) {
                    Tab("Search", systemImage: SidebarTab.search.systemImage, value: SidebarTab.search, role: .search) {
                        NavigationStack {
                            moreTabContent
                                .searchable(text: $searchViewModel.searchQuery, prompt: "Search bookmarks...")
                        }
                    }
                    .badge(offlineBookmarksViewModel.state.localBookmarkCount > 0 ? offlineBookmarksViewModel.state.localBookmarkCount : 0)
                } else {
                    Tab(value: SidebarTab.settings) {
                        NavigationStack(path: $morePath) {
                            VStack(spacing: 0) {

                                // Classic search bar for iOS 18
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    TextField("Search...", text: $searchViewModel.searchQuery)
                                        .focused($searchFieldIsFocused)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                    if !searchViewModel.searchQuery.isEmpty {
                                        Button(action: {
                                            searchViewModel.searchQuery = ""
                                            searchFieldIsFocused = true
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(10)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding([.horizontal, .top])

                                moreTabContent
                                moreTabsFooter
                            }
                            .navigationTitle("More")
                            .onAppear {
                                selectedMoreTab = nil
                            }
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis")
                    }
                    .badge(offlineBookmarksViewModel.state.localBookmarkCount > 0 ? offlineBookmarksViewModel.state.localBookmarkCount : 0)
                }
            }
            .accentColor(.accentColor)
            
            // .tabBarMinimizeBehavior(.onScrollDown)
        }
    }
    
    
    // MARK: - Tab Content

    @ViewBuilder
    private var moreTabContent: some View {
        if searchViewModel.searchQuery.isEmpty {
            moreTabsList
        } else {
            searchResultsView
        }
    }

    @ViewBuilder
    private var searchResultsView: some View {
        if searchViewModel.isLoading {
            ProgressView("Searching...")
                .padding()
        } else if let error = searchViewModel.errorMessage {
            Text(error)
                .foregroundColor(.red)
                .padding()
        } else if let bookmarks = searchViewModel.bookmarks?.bookmarks, !bookmarks.isEmpty {
            List(bookmarks) { bookmark in
                ZStack {
                    NavigationLink {
                        BookmarkDetailView(bookmarkId: bookmark.id)
                            .toolbar(.hidden, for: .tabBar)
                            .navigationBarBackButtonHidden(false)
                    } label: {
                        BookmarkCardView(
                            bookmark: bookmark,
                            currentState: .all,
                            layout: appSettings.settings?.cardLayoutStyle ?? .compact,
                            onArchive: { _ in },
                            onDelete: { _ in },
                            onToggleFavorite: { _ in }
                        )
                        .listRowBackground(Color(R.color.bookmark_list_bg))
                    }
                    .listRowInsets(EdgeInsets(
                        top: appSettings.settings?.cardLayoutStyle == .compact ? 8 : 12,
                        leading: 16,
                        bottom: appSettings.settings?.cardLayoutStyle == .compact ? 8 : 12,
                        trailing: 16
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color(R.color.bookmark_list_bg))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(R.color.bookmark_list_bg))
            .listStyle(.plain)
        } else if searchViewModel.searchQuery.isEmpty == false {
            ContentUnavailableView("No results", systemImage: "magnifyingglass", description: Text("No bookmarks found."))
                .padding()
        }
    }

    @ViewBuilder
    private var moreTabsList: some View {
        List {
            ForEach(moreTabs, id: \.self) { tab in
                NavigationLink {
                    tabView(for: tab)
                        .navigationTitle(tab.label)
                        .navigationBarTitleDisplayMode(.large)
                        .onDisappear {
                            // tags and search handle navigation by own
                            if tab != .tags && tab != .search {
                                selectedMoreTab = nil
                            }
                        }
                } label: {
                    Label(tab.label, systemImage: tab.systemImage)
                }
                .listRowBackground(Color(R.color.bookmark_list_bg))
            }
            
            if case .idle = offlineBookmarksViewModel.state {
                // Don't show anything for idle state
            } else {
                Section {
                    VStack {
                        LocalBookmarksSyncView(state: offlineBookmarksViewModel.state) {
                            await offlineBookmarksViewModel.syncOfflineBookmarks()
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
        }
        .navigationTitle("More")
        .scrollContentBackground(.hidden)
        .background(Color(R.color.bookmark_list_bg))
    }
    
    @ViewBuilder
    private var moreTabsFooter: some View {
        if appSettings.enableTTS {
            PlayerQueueResumeButton()
                .padding(.top, 16)
        }
    }
    
    @ViewBuilder
    private func tabView(for tab: SidebarTab) -> some View {
        switch tab {
        case .all:
            BookmarksView(state: .all, type: [.article, .video, .photo], selectedBookmark: .constant(nil))
        case .unread:
            BookmarksView(state: .unread, type: [.article], selectedBookmark: .constant(nil))
        case .favorite:
            BookmarksView(state: .favorite, type: [.article], selectedBookmark: .constant(nil))
        case .archived:
            BookmarksView(state: .archived, type: [.article], selectedBookmark: .constant(nil))
        case .search:
            SearchBookmarksView(selectedBookmark: .constant(nil))
        case .settings:
            SettingsView()
        case .article:
            BookmarksView(state: .all, type: [.article], selectedBookmark: .constant(nil))
        case .videos:
            BookmarksView(state: .all, type: [.video], selectedBookmark: .constant(nil))
        case .pictures:
            BookmarksView(state: .all, type: [.photo], selectedBookmark: .constant(nil))
        case .tags:
            LabelsView(selectedTag: .constant(nil))
        }
    }
}
