//
//  ArchiveAdvanceMode.swift
//  readeck
//
//  What should happen to the reader after the currently-open article is
//  archived (or deleted). Replaces the former boolean auto-advance toggle so
//  users can choose between advancing to the next article (#55) and returning
//  to the list (Codeberg #41).
//

import Foundation

enum ArchiveAdvanceMode: String, CaseIterable, Identifiable {
    /// Stay on the current article — do nothing (previously: toggle off).
    case stay
    /// Open the next article in the list (previously: toggle on). Covers #55.
    case nextArticle
    /// Dismiss the reader and return to the list. Covers Codeberg #41.
    case returnToList

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .stay:
            return "Stay on Article".localized
        case .nextArticle:
            return "Open Next Article".localized
        case .returnToList:
            return "Return to List".localized
        }
    }
}
