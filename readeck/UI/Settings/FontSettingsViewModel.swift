//
//  FontSettingsViewModel.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import Foundation
import Observation
import SwiftUI

@MainActor
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
    var lineHeight = 1.4

    // MARK: - Visibility
    var hideProgressBar = false
    var hideWordCount = false
    var hideHeroImage = false
    var hideSummary = false
    var readingProgressStyle: ReadingProgressStyle = .line

    // MARK: - Loading State
    var isLoading = false

    // MARK: - Custom CSS
    var customCSS = ""

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
    var previewLineSpacing: Double {
        // SwiftUI lineSpacing is extra space between lines, not the CSS line-height multiplier.
        // CSS line-height 1.8 at 20px = 36px total line height, so extra = (1.8 - 1.0) * fontSize
        (lineHeight - 1.0) * fontSizeNumeric
    }

    // MARK: - Messages
    var errorMessage: String?
    var successMessage: String?

    // MARK: - Computed Font Properties for Preview
    var previewTitleFont: Font {
        selectedFontFamily.font(size: fontSizeNumeric, bold: true)
    }

    var previewBodyFont: Font {
        selectedFontFamily.font(size: fontSizeNumeric)
    }

    var previewCaptionFont: Font {
        selectedFontFamily.font(size: fontSizeNumeric * 0.85)
    }

    init(factory: UseCaseFactory = DefaultUseCaseFactory.shared) {
        self.saveSettingsUseCase = factory.makeSaveSettingsUseCase()
        self.loadSettingsUseCase = factory.makeLoadSettingsUseCase()
    }

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
                readingProgressStyle = settings.readingProgressStyle ?? .line
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

    func saveFontSettings() async {
        do {
            try await saveSettingsUseCase.execute(
                selectedFontFamily: selectedFontFamily,
                selectedFontSize: selectedFontSize,
                fontSizeNumeric: fontSizeNumeric
            )
        } catch {
            errorMessage = "Error saving font settings"
        }
    }

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

    /// Shows the progress in the given style, or hides it when the style is nil.
    func saveProgressDisplay(_ style: ReadingProgressStyle?) async {
        if let style, style != readingProgressStyle {
            readingProgressStyle = style
            await saveReadingProgressStyle()
        }
        let hide = style == nil
        if hide != hideProgressBar {
            hideProgressBar = hide
            await saveVisibilitySettings()
        }
    }

    func saveReadingProgressStyle() async {
        do {
            try await saveSettingsUseCase.execute(readingProgressStyle: readingProgressStyle)
        } catch {
            errorMessage = "Error saving progress style"
        }
    }

    func saveCustomCSS() async {
        do {
            try await saveSettingsUseCase.execute(customCSS: customCSS)
        } catch {
            errorMessage = "Error saving custom CSS"
        }
    }

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
