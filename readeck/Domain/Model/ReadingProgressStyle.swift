//
//  ReadingProgressStyle.swift
//  readeck
//
//  How the native reader shows the reading progress while the navigation bar is hidden.
//

import Foundation

enum ReadingProgressStyle: String, CaseIterable, Identifiable {
    case line
    case islandRing
    case islandRingOnStop
    case percentTopTrailing
    case percentAtScrollIndicator

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .line:
            return "Line".localized
        case .islandRing:
            return "Island Ring".localized
        case .islandRingOnStop:
            return "Island Ring on Pause".localized
        case .percentTopTrailing:
            return "Percent in Corner".localized
        case .percentAtScrollIndicator:
            return "Percent at Scroll Indicator".localized
        }
    }

    var localizedDescription: String {
        switch self {
        case .line:
            return "A thin line below the navigation bar slides away with it.".localized
        case .islandRing:
            return "A ring around the Dynamic Island fills up as you read.".localized
        case .islandRingOnStop:
            return "The ring around the Dynamic Island shows up when you stop scrolling.".localized
        case .percentTopTrailing:
            return "The percentage pops up in the top corner when you stop scrolling.".localized
        case .percentAtScrollIndicator:
            return "The percentage follows the scroll indicator and shows up when you stop scrolling.".localized
        }
    }

    var requiresDynamicIsland: Bool {
        self == .islandRing || self == .islandRingOnStop
    }
}
