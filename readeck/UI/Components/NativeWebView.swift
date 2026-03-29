import SwiftUI
import WebKit

// MARK: - iOS 26+ Native SwiftUI WebView Implementation
// This implementation is available but not currently used
// To activate: Replace WebView usage with hybrid approach using #available(iOS 26.0, *)

@available(iOS 26.0, *)
struct NativeWebView: View {
    let htmlContent: String
    let settings: Settings
    let onHeightChange: (Double) -> Void
    var onScroll: ((Double) -> Void)?
    var selectedAnnotationId: String?
    var onAnnotationCreated: ((String, String, Int, Int, String, String) -> Void)?
    var onScrollToPosition: ((Double) -> Void)?

    @State private var webPage = WebPage()
    @State private var annotationPollingTask: Task<Void, Never>?
    @State private var scrollPollingTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WebKit.WebView(webPage)
            .scrollDisabled(true) // Disable internal scrolling
            .onAppear {
                loadStyledContent()
                setupAnnotationMessageHandler()
                setupScrollToPositionHandler()
            }
            .onChange(of: htmlContent) { _, _ in
                loadStyledContent()
            }
            .onChange(of: colorScheme) { _, _ in
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
            .onDisappear {
                // Cancel polling tasks to prevent memory leaks
                annotationPollingTask?.cancel()
                scrollPollingTask?.cancel()
            }
    }

    private func setupAnnotationMessageHandler() {
        // Cancel any existing polling task
        annotationPollingTask?.cancel()

        guard let onAnnotationCreated else { return }

        // Poll for annotation messages from JavaScript
        annotationPollingTask = Task { @MainActor in
            let page = webPage

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1s

                let script = """
                return (function() {
                    if (window.__pendingAnnotation) {
                        const data = window.__pendingAnnotation;
                        window.__pendingAnnotation = null;
                        return data;
                    }
                    return null;
                })();
                """

                do {
                    if let result = try await page.callJavaScript(script) as? [String: Any],
                       let color = result["color"] as? String,
                       let text = result["text"] as? String,
                       let startOffset = result["startOffset"] as? Int,
                       let endOffset = result["endOffset"] as? Int,
                       let startSelector = result["startSelector"] as? String,
                       let endSelector = result["endSelector"] as? String {
                        onAnnotationCreated(color, text, startOffset, endOffset, startSelector, endSelector)
                    }
                } catch {
                    // Silently continue polling
                }
            }
        }
    }

    private func setupScrollToPositionHandler() {
        // Cancel any existing polling task
        scrollPollingTask?.cancel()

        guard let onScrollToPosition else { return }

        // Poll for scroll position messages from JavaScript
        scrollPollingTask = Task { @MainActor in
            let page = webPage

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1s

                let script = """
                return (function() {
                    if (window.__pendingScrollPosition !== undefined) {
                        const position = window.__pendingScrollPosition;
                        window.__pendingScrollPosition = undefined;
                        return position;
                    }
                    return null;
                })();
                """

                do {
                    if let position = try await page.callJavaScript(script) as? Double {
                        onScrollToPosition(Double(position))
                    }
                } catch {
                    // Silently continue polling
                }
            }
        }
    }

    private func updateContentHeightWithJS() async {
        var lastHeight: Double = 0

        // Similar strategy to WebView: multiple attempts with increasing delays
        let delays = [0.1, 0.2, 0.5, 1.0, 1.5, 2.0] // 6 attempts like WebView

        for (index, delay) in delays.enumerated() {
            let attempt = index + 1
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            do {
                // Try to get height via JavaScript - use simple document.body.scrollHeight
                let result = try await webPage.callJavaScript("return document.body.scrollHeight")

                if let height = result as? Double, height > 0 {
                    let cgHeight = Double(height)

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
        let textHeight = Double(estimatedLines) * Double(fontSize) * 1.8
        let finalHeight = max(400, min(textHeight + 100, 3000))

        print("🟡 NativeWebView - Using fallback height: \(finalHeight)px")
        DispatchQueue.main.async {
            self.onHeightChange(finalHeight)
        }
    }

    private func loadStyledContent() {
        let isDarkMode = colorScheme == .dark
        let fontSize = getFontSize(from: settings.fontSize ?? .extraLarge)
        let selectedFontFamily = settings.fontFamily ?? .serif
        let fontCSS = ReaderFontCSSBuilder.build(fontFamily: selectedFontFamily)
        let codeFontFamily = selectedFontFamily == .monospace
            ? "var(--font-family)"
            : "'SF Mono', Menlo, Monaco, Consolas, monospace"
        Logger.ui.debug("NativeWebView font '\(selectedFontFamily.rawValue)' embedded: \(fontCSS.embedded)")

        let styledHTML = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <meta name="color-scheme" content="\(isDarkMode ? "dark" : "light")">
            <style>
                /* Load selected custom font from app bundle */
                \(fontCSS.fontFaceCSS)

                * {
                    max-width: 100%;
                    box-sizing: border-box;
                }

                html {
                    overflow-x: hidden;
                    width: 100%;
                }

                body {
                    font-family: \(fontCSS.fontStackCSS);
                    line-height: 1.8;
                    margin: 0;
                    padding: 16px 16px 100px;
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

                body, article, p, li, td, th, blockquote, h1, h2, h3, h4, h5, h6, span, div, a {
                    font-family: \(fontCSS.fontStackCSS) !important;
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

                code, pre, kbd, samp {
                    font-family: \(codeFontFamily) !important;
                }

                code {
                    background-color: \(isDarkMode ? "#1C1C1E" : "#f5f5f5");
                    color: \(isDarkMode ? "#ffffff" : "#000000");
                    padding: 2px 6px;
                    border-radius: 4px;
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
                }

                pre code {
                    font-family: inherit !important;
                }

                ul, ol { padding-left: 20px; margin-bottom: 16px; }
                li { margin-bottom: 4px; }

                table { width: 100%; border-collapse: collapse; margin: 16px 0; }
                th, td { border: 1px solid #ccc; padding: 8px 12px; text-align: left; }
                th { font-weight: 600; }

                hr { border: none; height: 1px; background-color: #ccc; margin: 24px 0; }

                /* Annotation Highlighting - for rd-annotation tags */
                rd-annotation {
                    display: inline;
                    border-radius: 3px;
                    padding: 2px 0;
                    transition: background-color 0.3s ease, box-shadow 0.3s ease;
                    -webkit-box-decoration-break: clone;
                    box-decoration-break: clone;
                }

                /* Yellow annotations */
                rd-annotation[data-annotation-color="yellow"] {
                    background-color: \(AnnotationColor.yellow.cssColor(isDark: isDarkMode));
                }
                rd-annotation[data-annotation-color="yellow"].selected {
                    background-color: \(AnnotationColor.yellow.cssColorWithOpacity(0.5));
                    box-shadow: 0 0 0 2px \(AnnotationColor.yellow.cssColorWithOpacity(0.6));
                }

                /* Green annotations */
                rd-annotation[data-annotation-color="green"] {
                    background-color: \(AnnotationColor.green.cssColor(isDark: isDarkMode));
                }
                rd-annotation[data-annotation-color="green"].selected {
                    background-color: \(AnnotationColor.green.cssColorWithOpacity(0.5));
                    box-shadow: 0 0 0 2px \(AnnotationColor.green.cssColorWithOpacity(0.6));
                }

                /* Blue annotations */
                rd-annotation[data-annotation-color="blue"] {
                    background-color: \(AnnotationColor.blue.cssColor(isDark: isDarkMode));
                }
                rd-annotation[data-annotation-color="blue"].selected {
                    background-color: \(AnnotationColor.blue.cssColorWithOpacity(0.5));
                    box-shadow: 0 0 0 2px \(AnnotationColor.blue.cssColorWithOpacity(0.6));
                }

                /* Red annotations */
                rd-annotation[data-annotation-color="red"] {
                    background-color: \(AnnotationColor.red.cssColor(isDark: isDarkMode));
                }
                rd-annotation[data-annotation-color="red"].selected {
                    background-color: \(AnnotationColor.red.cssColorWithOpacity(0.5));
                    box-shadow: 0 0 0 2px \(AnnotationColor.red.cssColorWithOpacity(0.6));
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

                // Scroll to selected annotation
                \(generateScrollToAnnotationJS())

                // Text Selection and Annotation Overlay
                \(generateAnnotationOverlayJS(isDarkMode: isDarkMode))
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

    private func generateAnnotationOverlayJS(isDarkMode: Bool) -> String {
        let highlightLabel = NSLocalizedString("Highlight", comment: "")

        return """
        // Create annotation color overlay
        (function() {
            let currentSelection = null;
            let currentRange = null;
            let selectionTimeout = null;

            // Create overlay container with arrow
            const overlay = document.createElement('div');
            overlay.id = 'annotation-overlay';
            overlay.style.cssText = `
                display: none;
                position: absolute;
                z-index: 10000;
            `;

            // Create arrow/triangle pointing up with glass effect
            const arrow = document.createElement('div');
            arrow.style.cssText = `
                position: absolute;
                width: 20px;
                height: 20px;
                background: rgba(255, 255, 255, 0.15);
                backdrop-filter: blur(20px) saturate(180%);
                -webkit-backdrop-filter: blur(20px) saturate(180%);
                border: 1px solid rgba(255, 255, 255, 0.2);
                border-right: none;
                border-bottom: none;
                top: -11px;
                left: 50%;
                transform: translateX(-50%) rotate(45deg);
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            `;
            overlay.appendChild(arrow);

            // Create the actual content container with glass morphism effect
            const content = document.createElement('div');
            content.style.cssText = `
                display: flex;
                background: rgba(255, 255, 255, 0.15);
                backdrop-filter: blur(20px) saturate(180%);
                -webkit-backdrop-filter: blur(20px) saturate(180%);
                border: 1px solid rgba(255, 255, 255, 0.2);
                border-radius: 24px;
                padding: 12px 16px;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3),
                            0 2px 8px rgba(0, 0, 0, 0.15),
                            inset 0 1px 0 rgba(255, 255, 255, 0.3);
                gap: 12px;
                flex-direction: row;
                align-items: center;
            `;
            overlay.appendChild(content);

            // Add localized label
            const label = document.createElement('span');
            label.textContent = '\(highlightLabel)';
            label.style.cssText = `
                color: black;
                font-size: 16px;
                font-weight: 500;
                margin-right: 4px;
            `;
            content.appendChild(label);

            // Create color buttons with solid colors
            const colors = [
                { name: 'yellow', color: '\(AnnotationColor.yellow.hexColor)' },
                { name: 'red', color: '\(AnnotationColor.red.hexColor)' },
                { name: 'blue', color: '\(AnnotationColor.blue.hexColor)' },
                { name: 'green', color: '\(AnnotationColor.green.hexColor)' }
            ];

            colors.forEach(({ name, color }) => {
                const btn = document.createElement('button');
                btn.dataset.color = name;
                btn.style.cssText = `
                    width: 40px;
                    height: 40px;
                    border-radius: 50%;
                    background: ${color};
                    border: 3px solid rgba(255, 255, 255, 0.3);
                    cursor: pointer;
                    padding: 0;
                    margin: 0;
                    transition: transform 0.2s, border-color 0.2s;
                `;
                btn.addEventListener('mouseenter', () => {
                    btn.style.transform = 'scale(1.1)';
                    btn.style.borderColor = 'rgba(255, 255, 255, 0.6)';
                });
                btn.addEventListener('mouseleave', () => {
                    btn.style.transform = 'scale(1)';
                    btn.style.borderColor = 'rgba(255, 255, 255, 0.3)';
                });
                btn.addEventListener('click', () => handleColorSelection(name));
                content.appendChild(btn);
            });

            document.body.appendChild(overlay);

            // Selection change listener
            document.addEventListener('selectionchange', () => {
                clearTimeout(selectionTimeout);
                selectionTimeout = setTimeout(() => {
                    const selection = window.getSelection();
                    const text = selection.toString().trim();

                    if (text.length > 0) {
                        currentSelection = text;
                        currentRange = selection.getRangeAt(0).cloneRange();
                        showOverlay(selection.getRangeAt(0));
                    } else {
                        hideOverlay();
                    }
                }, 150);
            });

            function showOverlay(range) {
                const rect = range.getBoundingClientRect();
                const scrollY = window.scrollY || window.pageYOffset;

                overlay.style.display = 'block';

                // Center horizontally under selection
                const overlayWidth = 320; // Approximate width with label + 4 buttons
                const centerX = rect.left + (rect.width / 2);
                const leftPos = Math.max(8, Math.min(centerX - (overlayWidth / 2), window.innerWidth - overlayWidth - 8));

                // Position with extra space below selection (55px instead of 70px) to bring it closer
                const topPos = rect.bottom + scrollY + 55;

                overlay.style.left = leftPos + 'px';
                overlay.style.top = topPos + 'px';
            }

            function hideOverlay() {
                overlay.style.display = 'none';
                currentSelection = null;
                currentRange = null;
            }

            function calculateOffset(container, offset) {
                const preRange = document.createRange();
                preRange.selectNodeContents(document.body);
                preRange.setEnd(container, offset);
                return preRange.toString().length;
            }

            function getXPathSelector(node) {
                // If node is text node, use parent element
                const element = node.nodeType === Node.TEXT_NODE ? node.parentElement : node;
                if (!element || element === document.body) return 'body';

                const path = [];
                let current = element;

                while (current && current !== document.body) {
                    const tagName = current.tagName.toLowerCase();

                    // Count position among siblings of same tag (1-based index)
                    let index = 1;
                    let sibling = current.previousElementSibling;
                    while (sibling) {
                        if (sibling.tagName === current.tagName) {
                            index++;
                        }
                        sibling = sibling.previousElementSibling;
                    }

                    // Format: tagname[index] (1-based)
                    path.unshift(tagName + '[' + index + ']');

                    current = current.parentElement;
                }

                const selector = path.join('/');
                console.log('Generated selector:', selector);
                return selector || 'body';
            }

            function calculateOffsetInElement(container, offset) {
                // Calculate offset relative to the parent element (not document.body)
                const element = container.nodeType === Node.TEXT_NODE ? container.parentElement : container;
                if (!element) return offset;

                // Create range from start of element to the position
                const range = document.createRange();
                range.selectNodeContents(element);
                range.setEnd(container, offset);

                return range.toString().length;
            }

            function generateTempId() {
                return 'temp-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
            }

            function getTextNodesInRange(range) {
                const textNodes = [];
                const startContainer = range.startContainer;
                const endContainer = range.endContainer;

                // If start and end are the same text node, just return it
                if (startContainer === endContainer && startContainer.nodeType === Node.TEXT_NODE) {
                    return [startContainer];
                }

                const walker = document.createTreeWalker(
                    range.commonAncestorContainer,
                    NodeFilter.SHOW_TEXT,
                    null
                );

                let foundStart = false;
                let node;

                while (node = walker.nextNode()) {
                    if (node === startContainer) {
                        foundStart = true;
                    }
                    if (foundStart && node.textContent.trim().length > 0) {
                        textNodes.push(node);
                    }
                    if (node === endContainer) {
                        break;
                    }
                }

                return textNodes;
            }

            function handleColorSelection(color) {
                if (!currentRange || !currentSelection) return;

                // Generate XPath-like selectors for start and end containers
                const startSelector = getXPathSelector(currentRange.startContainer);
                const endSelector = getXPathSelector(currentRange.endContainer);

                // Calculate offsets relative to the element (not document.body)
                const startOffset = calculateOffsetInElement(currentRange.startContainer, currentRange.startOffset);
                const endOffset = calculateOffsetInElement(currentRange.endContainer, currentRange.endOffset);

                const tempId = generateTempId();

                // Wrap selection in annotation
                try {
                    // Try surroundContents for simple single-element selections
                    const annotation = document.createElement('rd-annotation');
                    annotation.setAttribute('data-annotation-color', color);
                    annotation.setAttribute('data-annotation-id-value', tempId);
                    currentRange.surroundContents(annotation);
                } catch (e) {
                    // For complex selections spanning multiple elements: wrap each text node individually
                    const textNodes = getTextNodesInRange(currentRange);
                    textNodes.forEach((node, index) => {
                        const wrapper = document.createElement('rd-annotation');
                        wrapper.setAttribute('data-annotation-color', color);
                        wrapper.setAttribute('data-annotation-id-value', tempId);
                        if (index > 0) {
                            wrapper.setAttribute('data-annotation-continued', 'true');
                        }

                        const parent = node.parentNode;
                        parent.insertBefore(wrapper, node);
                        wrapper.appendChild(node);
                    });
                }

                // For NativeWebView: use global variable for polling
                window.__pendingAnnotation = {
                    color: color,
                    text: currentSelection,
                    startOffset: startOffset,
                    endOffset: endOffset,
                    startSelector: startSelector,
                    endSelector: endSelector
                };

                // Clear selection and hide overlay
                window.getSelection().removeAllRanges();
                hideOverlay();
            }
        })();
        """
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

                        // Get the element's position relative to the document
                        const rect = selectedElement.getBoundingClientRect();
                        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
                        const elementTop = rect.top + scrollTop;

                        // Send position to Swift via polling mechanism
                        setTimeout(() => {
                            window.__pendingScrollPosition = elementTop;
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
