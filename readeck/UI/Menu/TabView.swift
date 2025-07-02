import SwiftUI
import Foundation

struct MainTabView: View {
    @State private var selectedTab: SidebarTab = .unread
    @State var selectedBookmark: Bookmark?
    
    // sizeClass
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    @Environment(\.verticalSizeClass)
    var verticalSizeClass
    
    var body: some View {
        if UIDevice.isPhone {
            PhoneTabView()
        } else {
            PadSidebarView()
        }
    }
}

#Preview {
    MainTabView()
}
