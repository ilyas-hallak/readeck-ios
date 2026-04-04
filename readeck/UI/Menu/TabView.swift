import SwiftUI
import Foundation

struct MainTabView: View {
    @State private var selectedTab: SidebarTab = .unread
    @State private var selectedBookmark: Bookmark?
    @State private var showReleaseNotes = false

    // sizeClass
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    var body: some View {
        Group {
            if UIDevice.isPhone {
                PhoneTabView()
            } else {
                PadSidebarView()
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
