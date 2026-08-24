import CoreData
import Foundation

/// One-time repair for #103: the CoreData default for `horizontalMargin` used to be 0,
/// which `loadSettings` cannot tell apart from a deliberate zero margin. Every stored 0
/// therefore almost certainly comes from that bug, so it is reset to the "unset" sentinel
/// once. From then on a deliberate 0 is preserved.
struct ResetAccidentalHorizontalMargin: DataMigration {
    let id = "reset-accidental-horizontal-margin"

    func run(in context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<SettingEntity> = SettingEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "horizontalMargin == 0")

        let affected = try context.fetch(fetchRequest)
        guard !affected.isEmpty else { return }

        for entity in affected {
            entity.horizontalMargin = SettingEntity.unsetHorizontalMargin
        }
        Logger.data.info("Reset \(affected.count) accidental horizontal margin(s) to unset")
    }
}
