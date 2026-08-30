//
//  PadSidebarView.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.07.25.
//

import SwiftUI

struct PadSidebarView: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedTab: SidebarTab = .unread
    @State private var selectedBookmark: Bookmark?
    @State private var selectedTag: BookmarkLabel?
    @Environment(AppSettings.self) private var appSettings
    @State private var offlineBookmarksViewModel = OfflineBookmarksViewModel()
    @State private var isPlayerDismissed = false
    @State private var speechPlayerViewModel = SpeechPlayerViewModel()

    private let sidebarTabs: [SidebarTab] = [.search, .all, .unread, .favorite, .archived, .article, .videos, .pictures, .tags]

    /// Sidebar surface color; pure black while the OLED theme is active.
    private var sidebarBackground: Color {
        Color(R.color.menu_sidebar_bg).oledBlack(appSettings.theme.isOLED)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List {
                ForEach(sidebarTabs, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                        selectedBookmark = nil
                        selectedTag = nil
                    }) {
                        Label(tab.label, systemImage: tab.systemImage)
                            .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .listRowBackground(selectedTab == tab ? Color.accentColor.opacity(0.15) : sidebarBackground)

                    if tab == .archived {
                        Spacer()
                            .listRowBackground(sidebarBackground)
                    }
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
            .listRowBackground(sidebarBackground)
            .background(sidebarBackground)
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom, alignment: .center) {
                VStack(spacing: 0) {
                    if appSettings.enableTTS && isPlayerDismissed {
                        PlayerQueueResumeButton(
                            hasItems: speechPlayerViewModel.hasItems,
                            currentTitle: speechPlayerViewModel.currentItem?.title,
                            queueCount: speechPlayerViewModel.queueCount
                        ) {
                            isPlayerDismissed = false
                        }
                    }

                    Button(action: {
                        selectedTab = .settings
                    }) {
                        Label(SidebarTab.settings.label, systemImage: SidebarTab.settings.systemImage)
                            .foregroundColor(selectedTab == .settings ? .accentColor : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .listRowBackground(selectedTab == .settings ? Color.accentColor.opacity(0.15) : sidebarBackground)
                }
                .padding(.horizontal, 12)
                .background(sidebarBackground)
            }
        } content: {
            GlobalPlayerContainerView(viewModel: speechPlayerViewModel, isPlayerDismissed: $isPlayerDismissed) {
                Group {
                    switch selectedTab {
                    case .search:
                        SearchBookmarksView(selectedBookmark: $selectedBookmark)
                    case .all:
                        BookmarksView(state: .all, type: [.article, .video, .photo], selectedBookmark: $selectedBookmark)
                    case .unread:
                        BookmarksView(state: .unread, type: [.article, .video, .photo], selectedBookmark: $selectedBookmark)
                    case .favorite:
                        BookmarksView(state: .favorite, type: [.article, .video, .photo], selectedBookmark: $selectedBookmark)
                    case .archived:
                        BookmarksView(state: .archived, type: [.article, .video, .photo], selectedBookmark: $selectedBookmark)
                    case .settings:
                        SettingsView()
                    case .article:
                        BookmarksView(state: .all, type: [.article], selectedBookmark: $selectedBookmark)
                    case .videos:
                        BookmarksView(state: .all, type: [.video], selectedBookmark: $selectedBookmark)
                    case .pictures:
                        BookmarksView(state: .all, type: [.photo], selectedBookmark: $selectedBookmark)
                    case .tags:
                        NavigationStack {
                            LabelsView(selectedTag: $selectedTag)
                        }
                        .navigationDestination(item: $selectedTag) { label in
                            BookmarksView(state: .all, type: [], selectedBookmark: $selectedBookmark, tag: label.name)
                                .navigationTitle("\(label.name) (\(label.count))")
                                .onDisappear {
                                    selectedTag = nil
                                }
                        }
                    }
                }
                .navigationTitle(selectedTab.label)
            }
        } detail: {
            if let bookmark = selectedBookmark, selectedTab != .settings {
                ArticleReaderRouter(bookmarkId: bookmark.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation {
                                    columnVisibility = columnVisibility == .detailOnly ? .all : .detailOnly
                                }
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                            }
                        }
                    }
            } else if selectedTab == .settings {
                Text("").foregroundColor(.gray)
            }
        }
        .background(sidebarBackground)
        .task {
            await speechPlayerViewModel.setup()
        }
    }
}
