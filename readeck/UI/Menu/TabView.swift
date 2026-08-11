import SwiftUI
import Foundation

struct MainTabView: View {
    @State private var selectedTab: SidebarTab = .unread
    @State private var selectedBookmark: Bookmark?
    @State private var showReleaseNotes = false

    @Environment(DeepLinkRouter.self) private var deepLinkRouter

    // sizeClass
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    var body: some View {
        @Bindable var router = deepLinkRouter

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
        .sheet(item: $router.openedBookmark) { bookmark in
            DeepLinkReaderView(bookmarkId: bookmark.id)
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
        .environment(DeepLinkRouter())
}
