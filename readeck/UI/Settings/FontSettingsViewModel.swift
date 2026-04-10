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
    var fontSizeNumeric: Double = 20

    // MARK: - Reader Layout
    var horizontalMargin: Double = 16
    var lineHeight: Double = 1.4

    // MARK: - Visibility
    var hideProgressBar: Bool = false
    var hideWordCount: Bool = false
    var hideHeroImage: Bool = false
    var hideSummary: Bool = false

    // MARK: - Loading State
    var isLoading = false

    // MARK: - Custom CSS
    var customCSS: String = ""

    // MARK: - Color Theme
    var readerColorTheme: ReaderColorTheme = .system
    var customBackgroundColor: Color = .white
    var customTextColor: Color = .black

    // MARK: - Computed Color Properties
    var effectiveBackgroundColor: Color? {
        switch readerColorTheme {
        case .system: return nil
        case .custom: return customBackgroundColor
        default: return readerColorTheme.backgroundColor
        }
    }

    var effectiveTextColor: Color? {
        switch readerColorTheme {
        case .system: return nil
        case .custom: return customTextColor
        default: return readerColorTheme.textColor
        }
    }

    // MARK: - Computed Preview Properties
    var previewLineSpacing: CGFloat {
        // SwiftUI lineSpacing is extra space between lines, not the CSS line-height multiplier.
        // CSS line-height 1.8 at 20px = 36px total line height, so extra = (1.8 - 1.0) * fontSize
        return (lineHeight - 1.0) * fontSizeNumeric
    }

    // MARK: - Messages
    var errorMessage: String?
    var successMessage: String?

    // MARK: - Computed Font Properties for Preview
    var previewTitleFont: Font {
        let size = fontSizeNumeric

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
        let size = fontSizeNumeric

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
        let captionSize = fontSizeNumeric * 0.85

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
        isLoading = true
        defer { isLoading = false }

        do {
            if let settings = try await loadSettingsUseCase.execute() {
                selectedFontFamily = settings.fontFamily ?? .system
                selectedFontSize = settings.fontSize ?? .medium

                // Determine font size: custom uses numeric, presets use enum size
                if let numeric = settings.fontSizeNumeric, selectedFontSize == .custom {
                    fontSizeNumeric = numeric
                } else if selectedFontSize != .custom {
                    fontSizeNumeric = selectedFontSize.size
                } else {
                    fontSizeNumeric = 20
                }

                horizontalMargin = settings.horizontalMargin ?? 16
                lineHeight = settings.lineHeight ?? 1.4
                hideProgressBar = settings.hideProgressBar ?? false
                hideWordCount = settings.hideWordCount ?? false
                hideHeroImage = settings.hideHeroImage ?? false
                hideSummary = settings.hideSummary ?? false
                customCSS = settings.customCSS ?? ""
                readerColorTheme = settings.readerColorTheme ?? .system
                if let bgHex = settings.customBackgroundColor {
                    customBackgroundColor = Color(hex: bgHex)
                }
                if let textHex = settings.customTextColor {
                    customTextColor = Color(hex: textHex)
                }
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
                fontSizeNumeric: fontSizeNumeric
            )
        } catch {
            errorMessage = "Error saving font settings"
        }
    }

    @MainActor
    func saveReaderLayout() async {
        do {
            try await saveSettingsUseCase.execute(
                readerLayout: horizontalMargin,
                lineHeight: lineHeight
            )
        } catch {
            errorMessage = "Error saving reader layout"
        }
    }

    @MainActor
    func saveVisibilitySettings() async {
        do {
            try await saveSettingsUseCase.execute(
                readerVisibility: hideProgressBar,
                hideWordCount: hideWordCount,
                hideHeroImage: hideHeroImage,
                hideSummary: hideSummary
            )
        } catch {
            errorMessage = "Error saving visibility settings"
        }
    }

    @MainActor
    func saveCustomCSS() async {
        do {
            try await saveSettingsUseCase.execute(customCSS: customCSS)
        } catch {
            errorMessage = "Error saving custom CSS"
        }
    }

    @MainActor
    func saveColorTheme() async {
        do {
            let bgHex = readerColorTheme == .custom ? customBackgroundColor.hexString : nil
            let textHex = readerColorTheme == .custom ? customTextColor.hexString : nil
            try await saveSettingsUseCase.execute(
                readerColorTheme: readerColorTheme,
                customBackgroundColor: bgHex,
                customTextColor: textHex
            )
        } catch {
            errorMessage = "Error saving color theme"
        }
    }


    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
