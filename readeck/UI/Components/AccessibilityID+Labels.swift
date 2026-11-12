import Foundation

/// Compiled into the app and the share extension, since CoreDataTagManagementView
/// and UnifiedLabelChip use it in both. Each target declares its own `AccessibilityID`.
extension AccessibilityID {
    enum Labels {
        static let searchField = "labels.searchField"
        static let addCustomTagButton = "labels.addCustomTagButton"
        static func chip(_ name: String) -> String { "labels.chip.\(name)" }
    }
}
