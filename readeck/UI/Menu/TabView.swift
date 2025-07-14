import SwiftUI
import Foundation

struct MainTabView: View {
    @State private var selectedTab: SidebarTab = .unread
    @State var selectedBookmark: Bookmark?
    @StateObject private var playerUIState = PlayerUIState()
    
    // sizeClass
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    
    var body: some View {
        if UIDevice.isPhone {
            PhoneTabView()
                .environmentObject(playerUIState)
        } else {
            PadSidebarView()
                .environmentObject(playerUIState)
        }
    }
}

#Preview {
    MainTabView()
}
