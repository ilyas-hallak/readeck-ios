//
//  UrlOpener.swift
//  readeck
//
//  Created by Ilyas Hallak on 06.11.25.
//

enum UrlOpener: String, CaseIterable {
    case inAppBrowser = "inAppBrowser"
    case defaultBrowser = "defaultBrowser"
    
    var displayName: String {
        switch self {
        case .inAppBrowser: return "In App Browser"
        case .defaultBrowser: return "Default Browser"
        }
    }
}
