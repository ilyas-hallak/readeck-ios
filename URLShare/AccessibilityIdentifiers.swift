import Foundation

/// Stable identifiers for UI automation (Maestro, XCUITest) in the share extension.
enum AccessibilityID {
    enum ShareExtension {
        static let titleField = "shareExtension.titleField"
        static let saveButton = "shareExtension.saveButton"
    }

    /// Kept in sync with the main app's AccessibilityIdentifiers.swift: CoreDataTagManagementView
    /// and UnifiedLabelChip compile into both targets and reference this type by the same name.
    enum Labels {
        static let searchField = "labels.searchField"
        static let addCustomTagButton = "labels.addCustomTagButton"
        static func chip(_ name: String) -> String { "labels.chip.\(name)" }
    }
}
