import SwiftUI

/// Routes to the appropriate article reader implementation
/// based on iOS version availability or user preference
struct ArticleReaderRouter: View {
    let bookmarkId: String
    var bookmarkIds: [String] = []
    var onNavigateToNextBookmark: ((String) -> Void)? = nil
    var onNoMoreBookmarks: (() -> Void)? = nil

    @AppStorage("useNativeWebView") private var useNativeWebView = true

    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                if Bundle.main.isProduction {
                    // Temporary production stopper: use legacy renderer until native font loading is proven stable.
                    ArticleReaderLegacyView(bookmarkId: bookmarkId, useNativeWebView: .constant(false), bookmarkIds: bookmarkIds, onNavigateToNextBookmark: onNavigateToNextBookmark, onNoMoreBookmarks: onNoMoreBookmarks)
                } else if useNativeWebView {
                    // Use modern SwiftUI-native implementation on iOS 26+
                    ArticleReaderView(bookmarkId: bookmarkId, useNativeWebView: $useNativeWebView, bookmarkIds: bookmarkIds, onNavigateToNextBookmark: onNavigateToNextBookmark, onNoMoreBookmarks: onNoMoreBookmarks)
                } else {
                    // Use legacy WKWebView-based implementation
                    ArticleReaderLegacyView(bookmarkId: bookmarkId, useNativeWebView: $useNativeWebView, bookmarkIds: bookmarkIds, onNavigateToNextBookmark: onNavigateToNextBookmark, onNoMoreBookmarks: onNoMoreBookmarks)
                }
            } else {
                // iOS < 26: always use Legacy
                ArticleReaderLegacyView(bookmarkId: bookmarkId, useNativeWebView: .constant(false), bookmarkIds: bookmarkIds, onNavigateToNextBookmark: onNavigateToNextBookmark, onNoMoreBookmarks: onNoMoreBookmarks)
            }
        }
        // Forces a fresh view (and @State) per article. Without this, navigating
        // directly from one bookmarkId to another (as auto-advance-after-archive
        // does) reuses the existing reader instance, so the content never reloads —
        // previously unreachable since navigation only ever went nil->id or id->nil.
        .id(bookmarkId)
        .modifier(DisableBackSwipeModifier(isDisabled: appSettings.disableReaderBackSwipe))
    }
}

#Preview {
    NavigationView {
        ArticleReaderRouter(bookmarkId: "123")
    }
}
