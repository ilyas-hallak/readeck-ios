import SwiftUI
import Foundation

struct MainTabView: View {
    @State private var selectedTab: SidebarTab = .unread
    @State var selectedBookmark: Bookmark?
    @StateObject private var playerUIState = PlayerUIState()
    @State private var showReleaseNotes = false

    // sizeClass
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass

    @Environment(\.verticalSizeClass)
    var verticalSizeClass

    var body: some View {
        Group {
            if UIDevice.isPhone {
                PhoneTabView()
                    .environmentObject(playerUIState)
            } else {
                PadSidebarView()
                    .environmentObject(playerUIState)
            }
        }
        .sheet(isPresented: $showReleaseNotes) {
            ReleaseNotesView()
        }
        .onAppear {
            checkForNewVersion()
        }
    }

    private func checkForNewVersion() {
        if VersionManager.shared.isNewVersion {
            showReleaseNotes = true
            VersionManager.shared.markVersionAsSeen()
        }
    }
}

#Preview {
    MainTabView()
}
