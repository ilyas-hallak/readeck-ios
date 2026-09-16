import SwiftUI

/// Routes to the appropriate article reader implementation
/// based on iOS version availability or user preference
struct ArticleReaderRouter: View {
    let bookmarkId: String

    @AppStorage(ArticleReaderAvailability.preferenceKey)
    private var useNativeWebView = ArticleReaderAvailability.prefersNativeReaderByDefault

    @State private var showingFontSettings = false

    @Environment(AppSettings.self) private var appSettings

    private var selectedReader: ArticleReaderKind {
        ArticleReaderAvailability.reader(
            isNativeReaderSupported: ArticleReaderAvailability.isNativeReaderSupported,
            prefersNativeReader: useNativeWebView
        )
    }

    var body: some View {
        Group {
            // The availability check is repeated here because ArticleReaderView is
            // annotated @available(iOS 26.0, *); ArticleReaderAvailability also
            // excludes the iPad app running on macOS, where NativeWebView crashes.
            if #available(iOS 26.0, *), selectedReader == .native {
                // Modern SwiftUI-native implementation
                ArticleReaderView(bookmarkId: bookmarkId, showingFontSettings: $showingFontSettings)
            } else {
                // Legacy WKWebView-based implementation
                ArticleReaderLegacyView(bookmarkId: bookmarkId, showingFontSettings: $showingFontSettings)
            }
        }
        // Forces a fresh view (and @State) per article. Without this, navigating
        // directly from one bookmarkId to another (as auto-advance-after-archive
        // does) reuses the existing reader instance, so the content never reloads —
        // previously unreachable since navigation only ever went nil->id or id->nil.
        .id(bookmarkId)
        // Owned by the router, not by the readers: the Modern Reader toggle lives in
        // this sheet and swaps the reader underneath it. A sheet owned by the reader
        // would be torn down together with it, while the user is still in it.
        .sheet(isPresented: $showingFontSettings) {
            fontSettingsSheet
        }
        .modifier(DisableBackSwipeModifier(isDisabled: appSettings.disableReaderBackSwipe))
    }

    private var fontSettingsSheet: some View {
        NavigationView {
            FontSelectionView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingFontSettings = false
                        }
                    }
                }
        }
    }
}

#Preview {
    NavigationView {
        ArticleReaderRouter(bookmarkId: "123")
    }
}
