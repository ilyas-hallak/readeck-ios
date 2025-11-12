//
//  FontFamily.swift
//  readeck
//
//  Created by Ilyas Hallak on 06.11.25.
//


enum FontFamily: String, CaseIterable {
    case system = "system"
    case serif = "serif"
    case sansSerif = "sansSerif"
    case monospace = "monospace"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .serif: return "Serif"
        case .sansSerif: return "Sans Serif"
        case .monospace: return "Monospace"
        }
    }
}