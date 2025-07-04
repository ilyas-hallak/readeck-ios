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
    @State private var selectedTabIndex: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(Array(mainTabs.enumerated()), id: \.element) { idx, tab in
                NavigationStack {
                    tabView(for: tab)
                }
                .tabItem {
                    Label(tab.label, systemImage: tab.systemImage)
                }
                .tag(idx)
            }
            
            NavigationStack {
                List(moreTabs, id: \.self, selection: $selectedMoreTab) { tab in
                    NavigationLink(tag: tab, selection: $selectedMoreTab) {
                        tabView(for: tab)
                            .navigationTitle(tab.label)
                    } label: {
                        Label(tab.label, systemImage: tab.systemImage)
                    }
                    .listRowBackground(Color(R.color.bookmark_list_bg))
                }
                .navigationTitle("Mehr")
                .scrollContentBackground(.hidden)
                .background(Color(R.color.bookmark_list_bg))
            }
            .tabItem {
                Label("Mehr", systemImage: "ellipsis")
            }
            .tag(mainTabs.count)
            .onAppear {
                if selectedTabIndex == mainTabs.count && selectedMoreTab != nil {
                    selectedMoreTab = nil
                }
            }
        }
        .accentColor(.accentColor)
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
            Text("Tags")
        }
    }
}
