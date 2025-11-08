//
//  TagSortOrder.swift
//  readeck
//
//  Created by Ilyas Hallak
//

import Foundation

enum TagSortOrder: String, CaseIterable {
    case byCount = "count"
    case alphabetically = "alphabetically"

    var displayName: String {
        switch self {
        case .byCount: return "By usage count"
        case .alphabetically: return "Alphabetically"
        }
    }
}
