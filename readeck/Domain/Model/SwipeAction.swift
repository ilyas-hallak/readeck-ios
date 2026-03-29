// readeck/Domain/Model/SwipeAction.swift

import Foundation

enum SwipeAction: String, Codable, CaseIterable, Identifiable {
    case archive
    case favorite
    case delete
    case showTags
    case openInBrowser

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .archive: return "Archive"
        case .favorite: return "Favorite"
        case .delete: return "Delete"
        case .showTags: return "Tags"
        case .openInBrowser: return "Open in Browser"
        }
    }

    var iconName: String {
        switch self {
        case .archive: return "archivebox"
        case .favorite: return "heart.fill"
        case .delete: return "trash"
        case .showTags: return "tag"
        case .openInBrowser: return "safari"
        }
    }
}

struct SwipeActionConfig: Codable, Equatable {
    var leadingActions: [SwipeAction]
    var trailingActions: [SwipeAction]

    static let `default` = SwipeActionConfig(
        leadingActions: [.archive, .favorite],
        trailingActions: [.delete]
    )

    /// All actions currently assigned to either side
    var assignedActions: Set<SwipeAction> {
        Set(leadingActions + trailingActions)
    }

    /// Actions not yet assigned to any side
    var availableActions: [SwipeAction] {
        SwipeAction.allCases.filter { !assignedActions.contains($0) }
    }

    static let maxActionsPerSide = 3
}
