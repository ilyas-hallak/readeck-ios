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
final class FontSettingsViewModel {
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
        let size = selectedFontSize.size

        switch selectedFontFamily {
        // Apple System Fonts
        case .system:
            return Font.system(size: size).weight(.semibold)
        case .newYork:
            return Font.system(size: size, design: .serif).weight(.semibold)
        case .avenirNext:
            return Font.custom("AvenirNext-DemiBold", size: size)
        case .monospace:
            return Font.system(size: size, design: .monospaced).weight(.semibold)

        // Google Serif Fonts
        case .literata:
            return Font.custom("Literata-Bold", size: size)
        case .merriweather:
            return Font.custom("Merriweather-Bold", size: size)
        case .sourceSerif:
            return Font.custom("SourceSerif4-Bold", size: size)

        // Google Sans Serif Fonts
        case .lato:
            return Font.custom("Lato-Bold", size: size)
        case .montserrat:
            return Font.custom("Montserrat-Bold", size: size)
        case .sourceSans:
            return Font.custom("SourceSans3-Bold", size: size)

        // Legacy
        case .serif:
            return Font.custom("Times New Roman", size: size).weight(.semibold)
        case .sansSerif:
            return Font.custom("Helvetica Neue", size: size).weight(.semibold)
        }
    }

    var previewBodyFont: Font {
        let size = selectedFontSize.size

        switch selectedFontFamily {
        // Apple System Fonts
        case .system:
            return Font.system(size: size)
        case .newYork:
            return Font.system(size: size, design: .serif)
        case .avenirNext:
            return Font.custom("AvenirNext-Regular", size: size)
        case .monospace:
            return Font.system(size: size, design: .monospaced)

        // Google Serif Fonts
        case .literata:
            return Font.custom("Literata-Regular", size: size)
        case .merriweather:
            return Font.custom("Merriweather-Regular", size: size)
        case .sourceSerif:
            return Font.custom("SourceSerif4-Regular", size: size)

        // Google Sans Serif Fonts
        case .lato:
            return Font.custom("Lato-Regular", size: size)
        case .montserrat:
            return Font.custom("Montserrat-Regular", size: size)
        case .sourceSans:
            return Font.custom("SourceSans3-Regular", size: size)

        // Legacy
        case .serif:
            return Font.custom("Times New Roman", size: size)
        case .sansSerif:
            return Font.custom("Helvetica Neue", size: size)
        }
    }

    var previewCaptionFont: Font {
        let captionSize = selectedFontSize.size * 0.85

        switch selectedFontFamily {
        // Apple System Fonts
        case .system:
            return Font.system(size: captionSize)
        case .newYork:
            return Font.system(size: captionSize, design: .serif)
        case .avenirNext:
            return Font.custom("AvenirNext-Regular", size: captionSize)
        case .monospace:
            return Font.system(size: captionSize, design: .monospaced)

        // Google Serif Fonts
        case .literata:
            return Font.custom("Literata-Regular", size: captionSize)
        case .merriweather:
            return Font.custom("Merriweather-Regular", size: captionSize)
        case .sourceSerif:
            return Font.custom("SourceSerif4-Regular", size: captionSize)

        // Google Sans Serif Fonts
        case .lato:
            return Font.custom("Lato-Regular", size: captionSize)
        case .montserrat:
            return Font.custom("Montserrat-Regular", size: captionSize)
        case .sourceSans:
            return Font.custom("SourceSans3-Regular", size: captionSize)

        // Legacy
        case .serif:
            return Font.custom("Times New Roman", size: captionSize)
        case .sansSerif:
            return Font.custom("Helvetica Neue", size: captionSize)
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
