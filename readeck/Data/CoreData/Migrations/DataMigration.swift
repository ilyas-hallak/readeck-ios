import CoreData
import Foundation

/// A one-time repair of stored *values*, run once at app start.
/// Schema changes are handled by Core Data's lightweight migration, this is for
/// data that a past bug left in a bad state.
protocol DataMigration {
    /// Stable identifier that marks this migration as done. Never change it once shipped.
    var id: String { get }
    func run(in context: NSManagedObjectContext) throws
}
