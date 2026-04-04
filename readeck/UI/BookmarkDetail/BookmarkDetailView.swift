import SwiftUI

/// Container view that routes to the appropriate BookmarkDetail implementation
/// based on iOS version availability or user preference
struct BookmarkDetailView: View {
    let bookmarkId: String

    @AppStorage("useNativeWebView") private var useNativeWebView: Bool = true

    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                if Bundle.main.isProduction {
                    // Temporary production stopper: use legacy renderer until native font loading is proven stable.
                    BookmarkDetailLegacyView(bookmarkId: bookmarkId, useNativeWebView: .constant(false))
                } else if useNativeWebView {
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
        .disableBackSwipe(appSettings.disableReaderBackSwipe)
    }
}

#Preview {
    NavigationView {
        BookmarkDetailView(bookmarkId: "123")
    }
}
