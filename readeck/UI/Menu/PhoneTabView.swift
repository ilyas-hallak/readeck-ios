//
//  PhoneTabView.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.07.25.
//

import SwiftUI

struct PhoneTabView: View {
    private let mainTabs: [SidebarTab] = [.all, .unread, .favorite, .archived]
    private let moreTabs: [SidebarTab] = [.search, .article, .videos, .pictures, .tags, .settings]
    
    @State private var selectedMoreTab: SidebarTab? = nil
    @State private var selectedTabIndex: Int = 1
    @State private var offlineBookmarksViewModel = OfflineBookmarksViewModel(syncUseCase: DefaultUseCaseFactory.shared.makeOfflineBookmarkSyncUseCase())
    
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        NavigationStack {
            GlobalPlayerContainerView {
                TabView(selection: $selectedTabIndex) {
                    mainTabsContent
                    moreTabContent
                }
                .accentColor(.accentColor)
            }
        }
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var mainTabsContent: some View {
        ForEach(Array(mainTabs.enumerated()), id: \.element) { idx, tab in
            Tab(tab.label, systemImage: tab.systemImage, value: idx) {
                tabView(for: tab)
            }
        }
    }
    
    @ViewBuilder
    private var moreTabContent: some View {
        Tab("More", systemImage: "ellipsis", value: mainTabs.count) {
            VStack(spacing: 0) {
                moreTabsList
                moreTabsFooter
            }
            .onAppear {
                if selectedTabIndex == mainTabs.count && selectedMoreTab != nil {
                    selectedMoreTab = nil
                }
            }
        }
        .badge(offlineBookmarksViewModel.state.localBookmarkCount > 0 ? offlineBookmarksViewModel.state.localBookmarkCount : 0)
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
