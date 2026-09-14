//
//  ArticleReaderAvailability.swift
//  readeck
//

import Foundation

/// Decides whether the native SwiftUI article reader can run on this device,
/// and which reader implementation a given user preference resolves to.
enum ArticleReaderAvailability {
    /// True when the native reader may be used on the current device.
    ///
    /// The native reader requires iOS 26. It must additionally be excluded when the
    /// iPad app runs on macOS: `#available(iOS 26.0, *)` also reports true there, but
    /// `NativeWebView` crashes as soon as an article is opened (GitHub issue #24,
    /// crash reports on macOS Tahoe). Do not remove this guard.
    static var isNativeReaderSupported: Bool {
        let isOS26OrNewer: Bool
        if #available(iOS 26.0, *) {
            isOS26OrNewer = true
        } else {
            isOS26OrNewer = false
        }
        return isNativeReaderSupported(
            isOS26OrNewer: isOS26OrNewer,
            isiOSAppOnMac: ProcessInfo.processInfo.isiOSAppOnMac
        )
    }

    /// Pure variant of ``isNativeReaderSupported`` so the rule can be tested.
    static func isNativeReaderSupported(isOS26OrNewer: Bool, isiOSAppOnMac: Bool) -> Bool {
        isOS26OrNewer && !isiOSAppOnMac
    }

    /// Resolves the reader to show for a given device capability and user preference.
    static func reader(isNativeReaderSupported: Bool, prefersNativeReader: Bool) -> ArticleReaderKind {
        isNativeReaderSupported && prefersNativeReader ? .native : .legacy
    }
}

/// The available article reader implementations.
enum ArticleReaderKind: Equatable {
    case native
    case legacy
}
