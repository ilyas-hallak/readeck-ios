import Foundation

extension String {
    /// Returns a localized version of the string using NSLocalizedString
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns a localized version of the string with comment
    func localized(comment: String) -> String {
        NSLocalizedString(self, comment: comment)
    }
}
