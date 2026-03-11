import Foundation

struct ReaderFontCSSBuildResult {
    let fontFaceCSS: String
    let fontStackCSS: String
    let embedded: Bool
}

enum ReaderFontCSSBuilder {
    static func build(fontFamily: FontFamily) -> ReaderFontCSSBuildResult {
        let fallbackStack = fallbackFontStack(for: fontFamily)

        guard let fileNames = fontFamily.fontFileNames,
              let cssFamilyName = fontFamily.cssFontFamily else {
            return ReaderFontCSSBuildResult(
                fontFaceCSS: "",
                fontStackCSS: fallbackStack,
                embedded: false
            )
        }

        var fontFaceRules: [String] = []

        for (fileName, weight) in fileNames {
            guard let fontData = resolveFontData(fileName: fileName) else {
                Logger.ui.debug("Reader font file not found: \(fileName).ttf")
                continue
            }

            let encodedFont = fontData.base64EncodedString()
            fontFaceRules.append(
                """
                @font-face {
                    font-family: '\(cssFamilyName)';
                    src: url('data:font/ttf;base64,\(encodedFont)') format('truetype');
                    font-weight: \(weight);
                    font-style: normal;
                    font-display: swap;
                }
                """
            )
        }

        let hasEmbeddedFont = !fontFaceRules.isEmpty
        return ReaderFontCSSBuildResult(
            fontFaceCSS: fontFaceRules.joined(separator: "\n\n"),
            fontStackCSS: "'\(cssFamilyName)', \(fallbackStack)",
            embedded: hasEmbeddedFont
        )
    }

    private static func resolveFontData(fileName: String) -> Data? {
        let bundle = Bundle.main
        let extensionName = "ttf"

        let directCandidates: [URL?] = [
            bundle.url(forResource: fileName, withExtension: extensionName),
            bundle.url(forResource: fileName, withExtension: extensionName, subdirectory: "Resources/Fonts"),
            bundle.url(forResource: fileName, withExtension: extensionName, subdirectory: "Fonts"),
            bundle.url(forResource: fileName, withExtension: extensionName, subdirectory: "Resources")
        ]

        for case let url? in directCandidates {
            if let data = try? Data(contentsOf: url) {
                return data
            }
        }

        let scanDirectories: [String?] = [nil, "Resources/Fonts", "Fonts", "Resources"]
        for directory in scanDirectories {
            guard let urls = bundle.urls(forResourcesWithExtension: extensionName, subdirectory: directory) else {
                continue
            }

            if let match = urls.first(where: { $0.deletingPathExtension().lastPathComponent == fileName }),
               let data = try? Data(contentsOf: match) {
                return data
            }
        }

        return nil
    }

    private static func fallbackFontStack(for fontFamily: FontFamily) -> String {
        switch fontFamily {
        case .system:
            return "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
        case .newYork:
            return "'New York', 'Times New Roman', Georgia, serif"
        case .avenirNext:
            return "'Avenir Next', Avenir, 'Helvetica Neue', sans-serif"
        case .monospace:
            return "'SF Mono', Menlo, Monaco, Consolas, 'Liberation Mono', monospace"
        case .literata:
            return "Georgia, 'Times New Roman', serif"
        case .merriweather:
            return "Georgia, 'Times New Roman', serif"
        case .sourceSerif:
            return "'Source Serif Pro', Georgia, serif"
        case .lato:
            return "'Helvetica Neue', Arial, sans-serif"
        case .montserrat:
            return "'Helvetica Neue', Arial, sans-serif"
        case .sourceSans:
            return "'Source Sans Pro', 'Helvetica Neue', sans-serif"
        case .serif:
            return "'Times New Roman', Times, 'Liberation Serif', serif"
        case .sansSerif:
            return "'Helvetica Neue', Helvetica, Arial, sans-serif"
        }
    }
}
