//
//  ReaderSwitchTip.swift
//  readeck
//

import SwiftUI
import TipKit

/// Points existing users at the reader switch now that the modern reader is the
/// default. Fresh installs never saw the old reader, so they are excluded.
struct ReaderSwitchTip: Tip {
    /// Set by ``readeckApp`` at launch. Persisted by `@Parameter`.
    // swiftlint:disable:next redundant_type_annotation - the @Parameter macro needs the explicit type
    @Parameter static var isUpgradingUser: Bool = false

    var title: Text {
        Text("New reader")
    }

    var message: Text? {
        Text("Articles now open in the modern reader. If anything looks off, you can switch back under Font Settings.")
    }

    var image: Image? {
        Image(systemName: "text.alignleft")
    }

    var rules: [Rule] {
        #Rule(Self.$isUpgradingUser) { $0 == true }
    }

    var options: [any TipOption] {
        MaxDisplayCount(1)
    }

    /// True when the app already ran on an older version. A fresh install has no
    /// last seen version and must not be told about a reader it never used.
    static func isUpgrade(lastSeenVersion: String?, currentVersion: String) -> Bool {
        guard let lastSeenVersion else { return false }
        return lastSeenVersion != currentVersion
    }
}
