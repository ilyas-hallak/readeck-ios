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
    @StateObject private var syncManager = OfflineSyncManager.shared
    @State private var phoneTabLocalBookmarkCount = 0
    
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        GlobalPlayerContainerView {
            TabView(selection: $selectedTabIndex) {
                mainTabsContent
                moreTabContent
            }
            .accentColor(.accentColor)
            .onAppear {
                updateLocalBookmarkCount()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                updateLocalBookmarkCount()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                updateLocalBookmarkCount()
            }
            .onChange(of: syncManager.isSyncing) {
                if !syncManager.isSyncing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        updateLocalBookmarkCount()
                    }
                }
            }
        }
    }
    
    private func updateLocalBookmarkCount() {
        let count = syncManager.getOfflineBookmarksCount()
        DispatchQueue.main.async {
            self.phoneTabLocalBookmarkCount = count
        }
    }
    
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var mainTabsContent: some View {
        ForEach(Array(mainTabs.enumerated()), id: \.element) { idx, tab in
            NavigationStack {
                tabView(for: tab)
            }
            .tabItem {
                Label(tab.label, systemImage: tab.systemImage)
            }
            .tag(idx)
        }
    }
    
    @ViewBuilder
    private var moreTabContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                moreTabsList
                moreTabsFooter
            }
        }
        .tabItem {
            Label("More", systemImage: "ellipsis")
        }
        .badge(phoneTabLocalBookmarkCount > 0 ? phoneTabLocalBookmarkCount : 0)
        .tag(mainTabs.count)
        .onAppear {
            if selectedTabIndex == mainTabs.count && selectedMoreTab != nil {
                selectedMoreTab = nil
            }
        }
    }
    
    @ViewBuilder
    private var moreTabsList: some View {
        List {
            ForEach(moreTabs, id: \.self) { tab in
                NavigationLink {
                    tabView(for: tab)
                        .navigationTitle(tab.label)
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
            
            if phoneTabLocalBookmarkCount > 0 {
                Section {
                    VStack {
                        LocalBookmarksSyncView(bookmarkCount: phoneTabLocalBookmarkCount)
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
