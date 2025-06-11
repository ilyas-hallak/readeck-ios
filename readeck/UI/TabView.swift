import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: String = "Home"

    var body: some View {
        
        TabView() {
            BookmarksView()
                .tabItem {
                    Label("Links", systemImage: "house")
                }
                .tag("Home")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag("Settings")            
        }
        .accentColor(.blue)
    }
}
