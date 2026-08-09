import Foundation

/// Result of asking "what should be selected after archiving a bookmark?"
enum NextSelection: Equatable {
    /// Select the following bookmark in the list.
    case next(String)
    /// The archived bookmark was the last one — clear the selection.
    case clear
    /// Nothing to do (auto-advance not applicable for this id/list).
    case noop
}

/// Decides which bookmark to open after the one with `id` was archived.
///
/// Pure and side-effect free so the index math is unit-testable without any
/// SwiftUI or notification plumbing.
func nextSelection(after id: String, in ids: [String]) -> NextSelection {
    guard let currentIndex = ids.firstIndex(of: id) else {
        return .noop
    }
    let nextIndex = currentIndex + 1
    return nextIndex < ids.count ? .next(ids[nextIndex]) : .clear
}
