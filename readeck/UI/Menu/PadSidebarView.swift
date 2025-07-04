//
//  PadSidebarView.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.07.25.
//

import SwiftUI

struct PadSidebarView: View {
    @State private var selectedTab: SidebarTab = .unread
    @State private var selectedBookmark: Bookmark?
    
    private let sidebarTabs: [SidebarTab] = [.search, .all, .unread, .favorite, .archived, .article, .videos, .pictures, .tags]
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(sidebarTabs, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        Label(tab.label, systemImage: tab.systemImage)
                            .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .listRowBackground(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color(R.color.menu_sidebar_bg))
                    
                    if tab == .archived {
                        Spacer()
                            .listRowBackground(Color(R.color.menu_sidebar_bg))
                    }
                    
                    if tab == .pictures {
                        Group {
                            Spacer()
                            Divider()
                            Spacer()
                        }
                        .listRowBackground(Color(R.color.menu_sidebar_bg))
                            
                    }
                }
            }
            .listRowBackground(Color(R.color.menu_sidebar_bg))
            .background(Color(R.color.menu_sidebar_bg))
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom, alignment: .center) {
                VStack(spacing: 0) {
                    Divider()
                    Button(action: {
                        selectedTab = .settings
                    }) {
                        Label(SidebarTab.settings.label, systemImage: SidebarTab.settings.systemImage)
                            .foregroundColor(selectedTab == .settings ? .accentColor : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .listRowBackground(selectedTab == .settings ? Color.accentColor.opacity(0.15) : Color(R.color.menu_sidebar_bg))
                }
                .padding(.horizontal, 12)
                .background(Color(R.color.menu_sidebar_bg))
            }
        } content: {
            Group {
                switch selectedTab {
                case .search:
                    SearchBookmarksView(selectedBookmark: $selectedBookmark)
                case .all:
                    BookmarksView(state: .all, type: [.article, .video, .photo], selectedBookmark: $selectedBookmark)
                case .unread:
                    BookmarksView(state: .unread, type: [.article], selectedBookmark: $selectedBookmark)
                case .favorite:
                    BookmarksView(state: .favorite, type: [.article], selectedBookmark: $selectedBookmark)
                case .archived:
                    BookmarksView(state: .archived, type: [.article], selectedBookmark: $selectedBookmark)
                case .settings:
                    SettingsView()
                case .article:
                    BookmarksView(state: .all, type: [.article], selectedBookmark: $selectedBookmark)
                case .videos:
                    BookmarksView(state: .all, type: [.video], selectedBookmark: $selectedBookmark)
                case .pictures:
                    BookmarksView(state: .all, type: [.photo], selectedBookmark: $selectedBookmark)
                case .tags:
                    Text("Tags")
                }
            }
            .navigationTitle(selectedTab.label)
            
            
        } detail: {
            if let bookmark = selectedBookmark, selectedTab != .settings {
                BookmarkDetailView(bookmarkId: bookmark.id)
            } else {
                Text(selectedTab == .settings ? "" : "Select a bookmark")
                    .foregroundColor(.gray)
            }
        }
        .background(Color(R.color.menu_sidebar_bg))
    }
}
