import CoreData
import Foundation

extension SettingEntity {
    /// Marks "the user never picked a margin". 0 cannot serve as that marker because it is
    /// a valid choice (no margin at all), so the CoreData default matches this value.
    static let unsetHorizontalMargin: Double = -1
}
