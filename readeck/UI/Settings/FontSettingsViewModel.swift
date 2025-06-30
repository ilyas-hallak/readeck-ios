//
//  FontSettingsViewModel.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import Foundation
import Observation
import SwiftUI

@Observable
class FontSettingsViewModel {
    private let saveSettingsUseCase: SaveSettingsUseCase
    private let loadSettingsUseCase: LoadSettingsUseCase
    
    // MARK: - Font Settings
    var selectedFontFamily: FontFamily = .system
    var selectedFontSize: FontSize = .medium
    
    // MARK: - Messages
    var errorMessage: String?
    var successMessage: String?

    // MARK: - Computed Font Properties for Preview
    var previewTitleFont: Font {
        switch selectedFontFamily {
        case .system:
            return selectedFontSize.systemFont.weight(.semibold)
        case .serif:
            return Font.custom("Times New Roman", size: selectedFontSize.size).weight(.semibold)
        case .sansSerif:
            return Font.custom("Helvetica Neue", size: selectedFontSize.size).weight(.semibold)
        case .monospace:
            return Font.custom("Menlo", size: selectedFontSize.size).weight(.semibold)
        }
    }
    
    var previewBodyFont: Font {
        switch selectedFontFamily {
        case .system:
            return selectedFontSize.systemFont
        case .serif:
            return Font.custom("Times New Roman", size: selectedFontSize.size)
        case .sansSerif:
            return Font.custom("Helvetica Neue", size: selectedFontSize.size)
        case .monospace:
            return Font.custom("Menlo", size: selectedFontSize.size)
        }
    }

    var previewCaptionFont: Font {
        let captionSize = selectedFontSize.size * 0.85
        switch selectedFontFamily {
        case .system:
            return Font.system(size: captionSize)
        case .serif:
            return Font.custom("Times New Roman", size: captionSize)
        case .sansSerif:
            return Font.custom("Helvetica Neue", size: captionSize)
        case .monospace:
            return Font.custom("Menlo", size: captionSize)
        }
    }
    
    init() {
        let factory = DefaultUseCaseFactory.shared
        self.saveSettingsUseCase = factory.makeSaveSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }
    
    @MainActor
    func loadFontSettings() async {
        do {
            if let settings = try await loadSettingsUseCase.execute() {
                selectedFontFamily = settings.fontFamily ?? .system
                selectedFontSize = settings.fontSize ?? .medium
            }
        } catch {
            errorMessage = "Fehler beim Laden der Schrift-Einstellungen"
        }
    }
    
    @MainActor
    func saveFontSettings() async {
        do {
            try await saveSettingsUseCase.execute(
                selectedFontFamily: selectedFontFamily, 
                selectedFontSize: selectedFontSize
            )
            successMessage = "Schrift-Einstellungen gespeichert"
        } catch {
            errorMessage = "Fehler beim Speichern der Schrift-Einstellungen"
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Font Enums (moved from SettingsViewModel)
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

enum FontSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var displayName: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .extraLarge: return "XL"
        }
    }
    
    var size: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .extraLarge: return 20
        }
    }
    
    var systemFont: Font {
        return Font.system(size: size)
    }
} 
