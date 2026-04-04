import SwiftUI

/// Routes to the appropriate article reader implementation
/// based on iOS version availability or user preference
struct ArticleReaderRouter: View {
    let bookmarkId: String

    @AppStorage("useNativeWebView") private var useNativeWebView = true

    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                if Bundle.main.isProduction {
                    // Temporary production stopper: use legacy renderer until native font loading is proven stable.
                    ArticleReaderLegacyView(bookmarkId: bookmarkId, useNativeWebView: .constant(false))
                } else if useNativeWebView {
                    // Use modern SwiftUI-native implementation on iOS 26+
                    ArticleReaderView(bookmarkId: bookmarkId, useNativeWebView: $useNativeWebView)
                } else {
                    // Use legacy WKWebView-based implementation
                    ArticleReaderLegacyView(bookmarkId: bookmarkId, useNativeWebView: $useNativeWebView)
                }
            } else {
                // iOS < 26: always use Legacy
                ArticleReaderLegacyView(bookmarkId: bookmarkId, useNativeWebView: .constant(false))
            }
        }
        .disableBackSwipe(appSettings.disableReaderBackSwipe)
    }
}

#Preview {
    NavigationView {
        ArticleReaderRouter(bookmarkId: "123")
    }
}
