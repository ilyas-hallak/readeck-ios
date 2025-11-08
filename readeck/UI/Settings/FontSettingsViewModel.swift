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
    private let saveSettingsUseCase: PSaveSettingsUseCase
    private let loadSettingsUseCase: PLoadSettingsUseCase
    
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
    
    init(factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
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
            errorMessage = "Error loading font settings"
        }
    }
    
    @MainActor
    func saveFontSettings() async {
        do {
            try await saveSettingsUseCase.execute(
                selectedFontFamily: selectedFontFamily, 
                selectedFontSize: selectedFontSize
            )
            successMessage = "Font settings saved"
        } catch {
            errorMessage = "Error saving font settings"
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}




