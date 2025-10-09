import SwiftUI

/// Container view that routes to the appropriate BookmarkDetail implementation
/// based on iOS version availability or user preference
struct BookmarkDetailView: View {
    let bookmarkId: String

    @AppStorage("useNativeWebView") private var useNativeWebView: Bool = true

    var body: some View {
        if #available(iOS 26.0, *) {
            if useNativeWebView {
                // Use modern SwiftUI-native implementation on iOS 26+
                BookmarkDetailView2(bookmarkId: bookmarkId, useNativeWebView: $useNativeWebView)
            } else {
                // Use legacy WKWebView-based implementation
                BookmarkDetailLegacyView(bookmarkId: bookmarkId, useNativeWebView: $useNativeWebView)
            }
        } else {
            // iOS < 26: always use Legacy
            BookmarkDetailLegacyView(bookmarkId: bookmarkId, useNativeWebView: .constant(false))
        }
    }
}

#Preview {
    NavigationView {
        BookmarkDetailView(bookmarkId: "123")
    }
}
