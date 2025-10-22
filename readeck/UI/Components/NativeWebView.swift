import SwiftUI
import WebKit

// MARK: - iOS 26+ Native SwiftUI WebView Implementation
// This implementation is available but not currently used
// To activate: Replace WebView usage with hybrid approach using #available(iOS 26.0, *)

@available(iOS 26.0, *)
struct NativeWebView: View {
    let htmlContent: String
    let settings: Settings
    let onHeightChange: (CGFloat) -> Void
    var onScroll: ((Double) -> Void)? = nil
    var selectedAnnotationId: String?
    var onTextSelected: ((String, Int, Int) -> Void)? = nil

    @State private var webPage = WebPage()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        WebKit.WebView(webPage)
            .scrollDisabled(true) // Disable internal scrolling
            .onAppear {
                loadStyledContent()
                setupTextSelectionCallback()
            }
            .onChange(of: htmlContent) { _, _ in
                loadStyledContent()
            }
            .onChange(of: colorScheme) { _, _ in
                loadStyledContent()
            }
            .onChange(of: selectedAnnotationId) { _, _ in
                loadStyledContent()
            }
            .onChange(of: webPage.isLoading) { _, isLoading in
                if !isLoading {
                    // Update height when content finishes loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        Task {
                            await updateContentHeightWithJS()
                        }
                    }
                }
            }
    }

    private func setupTextSelectionCallback() {
        guard let onTextSelected = onTextSelected else { return }

        // Poll for text selection using JavaScript
        Task { @MainActor in
            let page = webPage // Capture the webPage

            while true {
                try? await Task.sleep(nanoseconds: 300_000_000) // Check every 0.3s

                let script = """
                return (function() {
                    const selection = window.getSelection();
                    if (selection && selection.toString().length > 0) {
                        const range = selection.getRangeAt(0);
                        const selectedText = selection.toString();

                        const preRange = document.createRange();
                        preRange.selectNodeContents(document.body);
                        preRange.setEnd(range.startContainer, range.startOffset);
                        const startOffset = preRange.toString().length;
                        const endOffset = startOffset + selectedText.length;

                        return {
                            text: selectedText,
                            startOffset: startOffset,
                            endOffset: endOffset
                        };
                    }
                    return null;
                })();
                """

                do {
                    if let result = try await page.callJavaScript(script) as? [String: Any],
                       let text = result["text"] as? String,
                       let startOffset = result["startOffset"] as? Int,
                       let endOffset = result["endOffset"] as? Int {
                        onTextSelected(text, startOffset, endOffset)
                    }
                } catch {
                    // Silently continue polling
                }
            }
        }
    }
    
    private func updateContentHeightWithJS() async {
        var lastHeight: CGFloat = 0

        // Similar strategy to WebView: multiple attempts with increasing delays
        let delays = [0.1, 0.2, 0.5, 1.0, 1.5, 2.0] // 6 attempts like WebView

        for (index, delay) in delays.enumerated() {
            let attempt = index + 1
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            do {
                // Try to get height via JavaScript - use simple document.body.scrollHeight
                let result = try await webPage.callJavaScript("return document.body.scrollHeight")

                if let height = result as? Double, height > 0 {
                    let cgHeight = CGFloat(height)

                    // Update height if it's significantly different (> 5px like WebView)
                    if lastHeight == 0 || abs(cgHeight - lastHeight) > 5 {
                        print("🟢 NativeWebView - JavaScript height updated: \(height)px on attempt \(attempt)")
                        DispatchQueue.main.async {
                            self.onHeightChange(cgHeight)
                        }
                        lastHeight = cgHeight
                    }

                    // If height seems stable (no change in last 2 attempts), we can exit early
                    if attempt >= 2 && lastHeight > 0 {
                        print("🟢 NativeWebView - Height stabilized at \(lastHeight)px after \(attempt) attempts")
                        return
                    }
                }
            } catch {
                print("🟡 NativeWebView - JavaScript attempt \(attempt) failed: \(error)")
            }
        }

        // If no valid height was found, use fallback
        if lastHeight == 0 {
            print("🔴 NativeWebView - No valid JavaScript height found, using fallback")
            updateContentHeightFallback()
        } else {
            print("🟢 NativeWebView - Final height: \(lastHeight)px")
        }
    }
    
    private func updateContentHeightFallback() {
        // Simplified fallback calculation
        let fontSize = getFontSize(from: settings.fontSize ?? .extraLarge)
        let plainText = htmlContent.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let characterCount = plainText.count
        let estimatedLines = max(1, characterCount / 80)
        let textHeight = CGFloat(estimatedLines) * CGFloat(fontSize) * 1.8
        let finalHeight = max(400, min(textHeight + 100, 3000))
        
        print("🟡 NativeWebView - Using fallback height: \(finalHeight)px")
        DispatchQueue.main.async {
            self.onHeightChange(finalHeight)
        }
    }
    
    private func loadStyledContent() {
        let isDarkMode = colorScheme == .dark
        let fontSize = getFontSize(from: settings.fontSize ?? .extraLarge)
        let fontFamily = getFontFamily(from: settings.fontFamily ?? .serif)
        
        let styledHTML = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <meta name="color-scheme" content="\(isDarkMode ? "dark" : "light")">
            <style>
                * {
                    max-width: 100%;
                    box-sizing: border-box;
                }

                html {
                    overflow-x: hidden;
                    width: 100%;
                }

                body {
                    font-family: \(fontFamily);
                    line-height: 1.8;
                    margin: 0;
                    padding: 16px;
                    background-color: \(isDarkMode ? "#000000" : "#ffffff");
                    color: \(isDarkMode ? "#ffffff" : "#1a1a1a");
                    font-size: \(fontSize)px;
                    -webkit-text-size-adjust: 100%;
                    -webkit-user-select: text;
                    user-select: text;
                    overflow-x: hidden;
                    width: 100%;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                
                h1, h2, h3, h4, h5, h6 {
                    color: \(isDarkMode ? "#ffffff" : "#000000");
                    margin-top: 24px;
                    margin-bottom: 12px;
                    font-weight: 600;
                }
                
                h1 { font-size: \(fontSize * 3 / 2)px; }
                h2 { font-size: \(fontSize * 5 / 4)px; }
                h3 { font-size: \(fontSize * 9 / 8)px; }
                
                p { margin-bottom: 16px; }

                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 16px 0;
                }
                a { color: \(isDarkMode ? "#0A84FF" : "#007AFF"); text-decoration: none; }
                a:hover { text-decoration: underline; }
                
                blockquote { 
                    border-left: 4px solid \(isDarkMode ? "#0A84FF" : "#007AFF"); 
                    margin: 16px 0; 
                    padding: 12px 16px; 
                    font-style: italic; 
                    background-color: \(isDarkMode ? "rgba(58, 58, 60, 0.3)" : "rgba(0, 122, 255, 0.05)"); 
                    border-radius: 4px; 
                }
                
                code { 
                    background-color: \(isDarkMode ? "#1C1C1E" : "#f5f5f5"); 
                    color: \(isDarkMode ? "#ffffff" : "#000000"); 
                    padding: 2px 6px; 
                    border-radius: 4px; 
                    font-family: 'SF Mono', monospace; 
                }
                
                pre {
                    background-color: \(isDarkMode ? "#1C1C1E" : "#f5f5f5");
                    color: \(isDarkMode ? "#ffffff" : "#000000");
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                    max-width: 100%;
                    white-space: pre-wrap;
                    word-wrap: break-word;
                    font-family: 'SF Mono', monospace;
                }
                
                ul, ol { padding-left: 20px; margin-bottom: 16px; }
                li { margin-bottom: 4px; }
                
                table { width: 100%; border-collapse: collapse; margin: 16px 0; }
                th, td { border: 1px solid #ccc; padding: 8px 12px; text-align: left; }
                th { font-weight: 600; }
                
                hr { border: none; height: 1px; background-color: #ccc; margin: 24px 0; }

                /* Annotation Highlighting - for rd-annotation tags */
                rd-annotation {
                    border-radius: 3px;
                    padding: 2px 0;
                    transition: background-color 0.3s ease, box-shadow 0.3s ease;
                }

                /* Yellow annotations */
                rd-annotation[data-annotation-color="yellow"] {
                    background-color: \(isDarkMode ? "rgba(158, 117, 4, 0.4)" : "rgba(107, 79, 3, 0.3)");
                }
                rd-annotation[data-annotation-color="yellow"].selected {
                    background-color: \(isDarkMode ? "rgba(158, 117, 4, 0.6)" : "rgba(107, 79, 3, 0.5)");
                    box-shadow: 0 0 0 2px \(isDarkMode ? "rgba(158, 117, 4, 0.5)" : "rgba(107, 79, 3, 0.6)");
                }

                /* Green annotations */
                rd-annotation[data-annotation-color="green"] {
                    background-color: \(isDarkMode ? "rgba(132, 204, 22, 0.4)" : "rgba(57, 88, 9, 0.3)");
                }
                rd-annotation[data-annotation-color="green"].selected {
                    background-color: \(isDarkMode ? "rgba(132, 204, 22, 0.6)" : "rgba(57, 88, 9, 0.5)");
                    box-shadow: 0 0 0 2px \(isDarkMode ? "rgba(132, 204, 22, 0.5)" : "rgba(57, 88, 9, 0.6)");
                }

                /* Blue annotations */
                rd-annotation[data-annotation-color="blue"] {
                    background-color: \(isDarkMode ? "rgba(9, 132, 159, 0.4)" : "rgba(7, 95, 116, 0.3)");
                }
                rd-annotation[data-annotation-color="blue"].selected {
                    background-color: \(isDarkMode ? "rgba(9, 132, 159, 0.6)" : "rgba(7, 95, 116, 0.5)");
                    box-shadow: 0 0 0 2px \(isDarkMode ? "rgba(9, 132, 159, 0.5)" : "rgba(7, 95, 116, 0.6)");
                }

                /* Red annotations */
                rd-annotation[data-annotation-color="red"] {
                    background-color: \(isDarkMode ? "rgba(152, 43, 43, 0.4)" : "rgba(103, 29, 29, 0.3)");
                }
                rd-annotation[data-annotation-color="red"].selected {
                    background-color: \(isDarkMode ? "rgba(152, 43, 43, 0.6)" : "rgba(103, 29, 29, 0.5)");
                    box-shadow: 0 0 0 2px \(isDarkMode ? "rgba(152, 43, 43, 0.5)" : "rgba(103, 29, 29, 0.6)");
                }
            </style>
        </head>
        <body>
            \(htmlContent)
            <script>
                function measureHeight() {
                    return Math.max(
                        document.body.scrollHeight || 0,
                        document.body.offsetHeight || 0,
                        document.documentElement.clientHeight || 0,
                        document.documentElement.scrollHeight || 0,
                        document.documentElement.offsetHeight || 0
                    );
                }
                
                // Make function globally available
                window.getContentHeight = measureHeight;
                
                // Auto-measure when everything is ready
                function scheduleHeightCheck() {
                    // Multiple timing strategies
                    if (document.readyState === 'loading') {
                        document.addEventListener('DOMContentLoaded', delayedHeightCheck);
                    } else {
                        delayedHeightCheck();
                    }
                    
                    // Also check after images load
                    window.addEventListener('load', delayedHeightCheck);
                    
                    // Force check after layout
                    setTimeout(delayedHeightCheck, 50);
                    setTimeout(delayedHeightCheck, 100);
                    setTimeout(delayedHeightCheck, 200);
                    setTimeout(delayedHeightCheck, 500);
                }
                
                function delayedHeightCheck() {
                    // Force layout recalculation
                    document.body.offsetHeight;
                    const height = measureHeight();
                    console.log('NativeWebView height check:', height);
                }
                
                scheduleHeightCheck();

                // Text selection detection
                \(generateTextSelectionJS())

                // Scroll to selected annotation
                \(generateScrollToAnnotationJS())
            </script>
        </body>
        </html>
        """
        webPage.load(html: styledHTML)
        
        // Update height after content loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                await updateContentHeightWithJS()
            }
        }
    }
    
    private func getFontSize(from fontSize: FontSize) -> Int {
        switch fontSize {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        case .extraLarge: return 20
        }
    }

    private func getFontFamily(from fontFamily: FontFamily) -> String {
        switch fontFamily {
        case .system: return "-apple-system, BlinkMacSystemFont, sans-serif"
        case .serif: return "'Times New Roman', Times, serif"
        case .sansSerif: return "'Helvetica Neue', Helvetica, Arial, sans-serif"
        case .monospace: return "'SF Mono', Menlo, Monaco, monospace"
        }
    }

    private func generateTextSelectionJS() -> String {
        // Not needed for iOS 26 - we use polling instead
        return ""
    }

    private func generateScrollToAnnotationJS() -> String {
        guard let selectedId = selectedAnnotationId else {
            return ""
        }

        return """
        // Scroll to selected annotation and add selected class
                function scrollToAnnotation() {
                    // Remove 'selected' class from all annotations
                    document.querySelectorAll('rd-annotation.selected').forEach(el => {
                        el.classList.remove('selected');
                    });

                    // Find and highlight selected annotation
                    const selectedElement = document.querySelector('rd-annotation[data-annotation-id-value="\(selectedId)"]');
                    if (selectedElement) {
                        selectedElement.classList.add('selected');
                        setTimeout(() => {
                            selectedElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
                        }, 100);
                    }
                }

                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', scrollToAnnotation);
                } else {
                    setTimeout(scrollToAnnotation, 300);
                }
        """
    }
}

// MARK: - Hybrid WebView (Not Currently Used)
// This would be the implementation to use both native and legacy WebViews
// Currently commented out - the app uses only the crash-resistant WebView

/*
struct HybridWebView: View {
    let htmlContent: String
    let settings: Settings
    let onHeightChange: (CGFloat) -> Void
    var onScroll: ((Double) -> Void)? = nil
    
    var body: some View {
        if #available(iOS 26.0, *) {
            // Use new native SwiftUI WebView on iOS 26+
            NativeWebView(
                htmlContent: htmlContent,
                settings: settings,
                onHeightChange: onHeightChange,
                onScroll: onScroll
            )
        } else {
            // Fallback to crash-resistant WebView for older iOS
            WebView(
                htmlContent: htmlContent,
                settings: settings,
                onHeightChange: onHeightChange,
                onScroll: onScroll
            )
        }
    }
}
*/
