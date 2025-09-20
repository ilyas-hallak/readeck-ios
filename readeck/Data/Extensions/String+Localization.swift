import Foundation

extension String {
    /// Returns a localized version of the string using NSLocalizedString
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized version of the string with comment
    func localized(comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
}