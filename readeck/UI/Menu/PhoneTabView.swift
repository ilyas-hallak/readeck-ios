//
//  PhoneTabView.swift
//  readeck
//
//  Created by Ilyas Hallak on 01.07.25.
//

import SwiftUI

struct PhoneTabView: View {
    var body: some View {
        TabView {
            
            NavigationStack {
                BookmarksView(state: .unread, type: [.article, .video, .photo], selectedBookmark: .constant(nil))
            }
            .tabItem {
                Label("Alle", systemImage: "list.bullet")
            }
            
            NavigationStack {
                BookmarksView(state: .unread, type: [.article], selectedBookmark: .constant(nil))
            }
            .tabItem {
                Label("Ungelesen", systemImage: "house")
            }
            
            BookmarksView(state: .favorite, type: [.article], selectedBookmark: .constant(nil))
                .tabItem {
                    Label("Favoriten", systemImage: "heart")
                }
            
            BookmarksView(state: .archived, type: [.article], selectedBookmark: .constant(nil))
                .tabItem {
                    Label("Archiv", systemImage: "archivebox")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(.accentColor)
    }
}
