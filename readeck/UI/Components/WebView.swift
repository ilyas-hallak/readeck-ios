import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let htmlContent: String
    let settings: Settings
    let onHeightChange: (CGFloat) -> Void
    var onScroll: ((Double) -> Void)? = nil
    var selectedAnnotationId: String?
    var onAnnotationCreated: ((String, String, Int, Int, String, String) -> Void)? = nil
    var onScrollToPosition: ((CGFloat) -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Enable text selection and copy functionality
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear

        // Allow text selection and copying
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = true

        webView.configuration.userContentController.add(context.coordinator, name: "heightUpdate")
        webView.configuration.userContentController.add(context.coordinator, name: "scrollProgress")
        webView.configuration.userContentController.add(context.coordinator, name: "annotationCreated")
        webView.configuration.userContentController.add(context.coordinator, name: "scrollToPosition")
        context.coordinator.onHeightChange = onHeightChange
        context.coordinator.onScroll = onScroll
        context.coordinator.onAnnotationCreated = onAnnotationCreated
        context.coordinator.onScrollToPosition = onScrollToPosition
        context.coordinator.webView = webView

        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onHeightChange = onHeightChange
        context.coordinator.onScroll = onScroll
        context.coordinator.onAnnotationCreated = onAnnotationCreated
        context.coordinator.onScrollToPosition = onScrollToPosition

        let isDarkMode = colorScheme == .dark
        let fontSize = getFontSize(from: settings.fontSize ?? .extraLarge)
        let fontFamily = getFontFamily(from: settings.fontFamily ?? .serif)

        // Clean up problematic HTML that kills performance
        let cleanedHTML = htmlContent
            // Remove Google attributes that cause navigation events
            .replacingOccurrences(of: #"\s*jsaction="[^"]*""#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*jscontroller="[^"]*""#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*jsname="[^"]*""#, with: "", options: .regularExpression)
            // Remove unnecessary IDs that bloat the DOM
            .replacingOccurrences(of: #"\s*id="[^"]*""#, with: "", options: .regularExpression)
            // Remove tabindex from non-interactive elements
            .replacingOccurrences(of: #"\s*tabindex="[^"]*""#, with: "", options: .regularExpression)
            // Remove role=button from figures (causes false click targets)
            .replacingOccurrences(of: #"\s*role="button""#, with: "", options: .regularExpression)
            // Fix invalid nested <p> tags inside <pre><span>
            .replacingOccurrences(of: #"<pre><span[^>]*>([^<]*)<p>"#, with: "<pre><span>$1\n", options: .regularExpression)
            .replacingOccurrences(of: #"</p>([^<]*)</span></pre>"#, with: "\n$1</span></pre>", options: .regularExpression)

        let styledHTML = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <meta name="color-scheme" content="\(isDarkMode ? "dark" : "light")">
            <style>
                :root {
                    --background-color: \(isDarkMode ? "#000000" : "#ffffff");
                    --text-color: \(isDarkMode ? "#ffffff" : "#1a1a1a");
                    --heading-color: \(isDarkMode ? "#ffffff" : "#000000");
                    --link-color: \(isDarkMode ? "#0A84FF" : "#007AFF");
                    --quote-color: \(isDarkMode ? "#8E8E93" : "#666666");
                    --quote-border: \(isDarkMode ? "#0A84FF" : "#007AFF");
                    --code-background: \(isDarkMode ? "#1C1C1E" : "#f5f5f5");
                    --code-text: \(isDarkMode ? "#ffffff" : "#000000");
                    --separator-color: \(isDarkMode ? "#38383A" : "#e0e0e0");
                    
                    /* Font Settings from Settings */
                    --base-font-size: \(fontSize)px;
                    --font-family: \(fontFamily);
                }
                
                body {
                    font-family: var(--font-family);
                    line-height: 1.8;
                    margin: 0;
                    padding: 16px;
                    background-color: var(--background-color);
                    color: var(--text-color);
                    font-size: var(--base-font-size);
                    -webkit-text-size-adjust: 100%;
                    -webkit-user-select: text;
                    -webkit-touch-callout: default;
                    user-select: text;
                }
                
                h1, h2, h3, h4, h5, h6 {
                    color: var(--heading-color);
                    margin-top: 24px;
                    margin-bottom: 12px;
                    font-weight: 600;
                    font-family: var(--font-family);
                }
                h1 { font-size: calc(var(--base-font-size) * 1.5); }
                h2 { font-size: calc(var(--base-font-size) * 1.25); }
                h3 { font-size: calc(var(--base-font-size) * 1.125); }
                h4 { font-size: var(--base-font-size); }
                h5 { font-size: calc(var(--base-font-size) * 0.875); }
                h6 { font-size: calc(var(--base-font-size) * 0.75); }
                
                p {
                    margin-bottom: 16px;
                    font-family: var(--font-family);
                    font-size: var(--base-font-size);
                }
                
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 16px 0;
                }
                
                a {
                    color: var(--link-color);
                    text-decoration: none;
                    font-family: var(--font-family);
                }
                a:hover {
                    text-decoration: underline;
                }
                
                blockquote {
                    border-left: 4px solid var(--quote-border);
                    margin: 16px 0;
                    padding-left: 16px;
                    font-style: italic;
                    color: var(--quote-color);
                    background-color: \(isDarkMode ? "rgba(58, 58, 60, 0.3)" : "rgba(0, 122, 255, 0.05)");
                    border-radius: 4px;
                    padding: 12px 16px;
                    font-family: var(--font-family);
                    font-size: var(--base-font-size);
                }
                
                code {
                    background-color: var(--code-background);
                    color: var(--code-text);
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-family: \(settings.fontFamily == .monospace ? "var(--font-family)" : "'SF Mono', Menlo, Monaco, Consolas, monospace");
                    font-size: calc(var(--base-font-size) * 0.875);
                }
                
                pre {
                    background-color: var(--code-background);
                    color: var(--code-text);
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                    font-family: \(settings.fontFamily == .monospace ? "var(--font-family)" : "'SF Mono', Menlo, Monaco, Consolas, monospace");
                    font-size: calc(var(--base-font-size) * 0.875);
                    border: 1px solid var(--separator-color);
                }
                
                pre code {
                    background-color: transparent;
                    padding: 0;
                    font-family: inherit;
                }
                
                hr {
                    border: none;
                    height: 1px;
                    background-color: var(--separator-color);
                    margin: 24px 0;
                }
                
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 16px 0;
                    font-family: var(--font-family);
                    font-size: var(--base-font-size);
                }
                
                th, td {
                    border: 1px solid var(--separator-color);
                    padding: 8px 12px;
                    text-align: left;
                }
                
                th {
                    background-color: \(isDarkMode ? "rgba(58, 58, 60, 0.5)" : "rgba(0, 0, 0, 0.05)");
                    font-weight: 600;
                }
                
                ul, ol {
                    padding-left: 20px;
                    margin-bottom: 16px;
                    font-family: var(--font-family);
                    font-size: var(--base-font-size);
                }
                
                li {
                    margin-bottom: 4px;
                }
                
                /* Dark mode media query als Fallback */
                @media (prefers-color-scheme: dark) {
                    :root {
                        --background-color: #000000;
                        --text-color: #ffffff;
                        --heading-color: #ffffff;
                        --link-color: #0A84FF;
                        --quote-color: #8E8E93;
                        --quote-border: #0A84FF;
                        --code-background: #1C1C1E;
                        --code-text: #ffffff;
                        --separator-color: #38383A;
                    }
                }
                
                /* Light mode media query als Fallback */
                @media (prefers-color-scheme: light) {
                    :root {
                        --background-color: #ffffff;
                        --text-color: #1a1a1a;
                        --heading-color: #000000;
                        --link-color: #007AFF;
                        --quote-color: #666666;
                        --quote-border: #007AFF;
                        --code-background: #f5f5f5;
                        --code-text: #000000;
                        --separator-color: #e0e0e0;
                    }
                }

                /* Annotation Highlighting - for rd-annotation tags */
                rd-annotation {
                    border-radius: 3px;
                    padding: 2px 0;
                    transition: background-color 0.3s ease, box-shadow 0.3s ease;
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
            \(cleanedHTML)
            <script>
                let lastHeight = 0;
                let heightUpdateTimeout = null;
                let scrollTimeout = null;
                let isScrolling = false;
                
                function updateHeight() {
                    const height = document.body.scrollHeight;
                    if (Math.abs(height - lastHeight) > 5 && !isScrolling) {
                        lastHeight = height;
                        window.webkit.messageHandlers.heightUpdate.postMessage(height);
                    }
                }
                
                function debouncedHeightUpdate() {
                    clearTimeout(heightUpdateTimeout);
                    heightUpdateTimeout = setTimeout(updateHeight, 100);
                }
                
                window.addEventListener('load', updateHeight);
                setTimeout(updateHeight, 500);
                
                document.querySelectorAll('img').forEach(img => {
                    img.addEventListener('load', debouncedHeightUpdate);
                });

                // Scroll to selected annotation
                \(generateScrollToAnnotationJS())

                // Text Selection and Annotation Overlay
                \(generateAnnotationOverlayJS(isDarkMode: isDarkMode))
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
    
    func dismantleUIView(_ webView: WKWebView, coordinator: WebViewCoordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "heightUpdate")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "scrollProgress")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "annotationCreated")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "scrollToPosition")
        webView.loadHTMLString("", baseURL: nil)
        coordinator.cleanup()
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator()
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
        case .system:
            return "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
        case .serif:
            return "'Times New Roman', Times, 'Liberation Serif', serif"
        case .sansSerif:
            return "'Helvetica Neue', Helvetica, Arial, sans-serif"
        case .monospace:
            return "'SF Mono', Menlo, Monaco, Consolas, 'Liberation Mono', monospace"
        }
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

                        // Send position to Swift
                        setTimeout(() => {
                            window.webkit.messageHandlers.scrollToPosition.postMessage(elementTop);
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

    private func generateAnnotationOverlayJS(isDarkMode: Bool) -> String {
        let yellowColor = AnnotationColor.yellow.cssColor(isDark: isDarkMode)
        let greenColor = AnnotationColor.green.cssColor(isDark: isDarkMode)
        let blueColor = AnnotationColor.blue.cssColor(isDark: isDarkMode)
        let redColor = AnnotationColor.red.cssColor(isDark: isDarkMode)

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

            // Add "Markierung" label
            const label = document.createElement('span');
            label.textContent = 'Markierung';
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

            function handleColorSelection(color) {
                if (!currentRange || !currentSelection) return;

                // Generate XPath-like selectors for start and end containers
                const startSelector = getXPathSelector(currentRange.startContainer);
                const endSelector = getXPathSelector(currentRange.endContainer);

                // Calculate offsets relative to the element (not document.body)
                const startOffset = calculateOffsetInElement(currentRange.startContainer, currentRange.startOffset);
                const endOffset = calculateOffsetInElement(currentRange.endContainer, currentRange.endOffset);

                // Create annotation element
                const annotation = document.createElement('rd-annotation');
                annotation.setAttribute('data-annotation-color', color);
                annotation.setAttribute('data-annotation-id-value', generateTempId());

                // Wrap selection in annotation
                try {
                    currentRange.surroundContents(annotation);
                } catch (e) {
                    // If surroundContents fails (e.g., partial element selection), extract and wrap
                    const fragment = currentRange.extractContents();
                    annotation.appendChild(fragment);
                    currentRange.insertNode(annotation);
                }

                // Send to Swift with selectors
                window.webkit.messageHandlers.annotationCreated.postMessage({
                    color: color,
                    text: currentSelection,
                    startOffset: startOffset,
                    endOffset: endOffset,
                    startSelector: startSelector,
                    endSelector: endSelector
                });

                // Clear selection and hide overlay
                window.getSelection().removeAllRanges();
                hideOverlay();
            }
        })();
        """
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    // Callbacks
    var onHeightChange: ((CGFloat) -> Void)?
    var onScroll: ((Double) -> Void)?
    var onAnnotationCreated: ((String, String, Int, Int, String, String) -> Void)?
    var onScrollToPosition: ((CGFloat) -> Void)?

    // WebView reference
    weak var webView: WKWebView?

    // Height management
    var lastHeight: CGFloat = 0
    var pendingHeight: CGFloat = 0
    var heightUpdateTimer: Timer?

    // Scroll management
    var isScrolling: Bool = false
    var scrollVelocity: Double = 0
    var lastScrollTime: Date = Date()
    var scrollEndTimer: Timer?

    // Lifecycle
    private var isCleanedUp = false
    
    deinit {
        cleanup()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "heightUpdate", let height = message.body as? CGFloat {
            DispatchQueue.main.async {
                self.handleHeightUpdate(height: height)
            }
        }
        if message.name == "scrollProgress", let progress = message.body as? Double {
            DispatchQueue.main.async {
                self.handleScrollProgress(progress: progress)
            }
        }
        if message.name == "annotationCreated", let body = message.body as? [String: Any],
           let color = body["color"] as? String,
           let text = body["text"] as? String,
           let startOffset = body["startOffset"] as? Int,
           let endOffset = body["endOffset"] as? Int,
           let startSelector = body["startSelector"] as? String,
           let endSelector = body["endSelector"] as? String {
            DispatchQueue.main.async {
                self.onAnnotationCreated?(color, text, startOffset, endOffset, startSelector, endSelector)
            }
        }
        if message.name == "scrollToPosition", let position = message.body as? Double {
            DispatchQueue.main.async {
                self.onScrollToPosition?(CGFloat(position))
            }
        }
    }
    
    private func handleHeightUpdate(height: CGFloat) {
        // Store the pending height
        pendingHeight = height
        
        // If we're actively scrolling, defer the height update
        if isScrolling {
            return
        }
        
        // Apply height update immediately if not scrolling
        applyHeightUpdate(height: height)
    }
    
    private func handleScrollProgress(progress: Double) {
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastScrollTime)

        // Calculate scroll velocity to detect fast scrolling
        if timeDelta > 0 {
            scrollVelocity = abs(progress) / timeDelta
        }

        lastScrollTime = now
        isScrolling = true

        // Longer delay for scroll end detection, especially during fast scrolling
        let scrollEndDelay: TimeInterval = scrollVelocity > 2.0 ? 0.8 : 0.5

        scrollEndTimer?.invalidate()
        scrollEndTimer = Timer.scheduledTimer(withTimeInterval: scrollEndDelay, repeats: false) { [weak self] _ in
            self?.handleScrollEnd()
        }

        onScroll?(progress)
    }
    
    private func handleScrollEnd() {
        isScrolling = false
        scrollVelocity = 0
        
        // Apply any pending height update after scrolling ends
        if pendingHeight != lastHeight && pendingHeight > 0 {
            // Add small delay to ensure scroll has fully stopped
            heightUpdateTimer?.invalidate()
            heightUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.applyHeightUpdate(height: self.pendingHeight)
            }
        }
    }
    
    private func applyHeightUpdate(height: CGFloat) {
        // Only update if height actually changed significantly
        let heightDifference = abs(height - lastHeight)
        if heightDifference < 5 { // Ignore tiny height changes that cause flicker
            return
        }

        lastHeight = height
        onHeightChange?(height)
    }

    func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true

        scrollEndTimer?.invalidate()
        scrollEndTimer = nil
        heightUpdateTimer?.invalidate()
        heightUpdateTimer = nil

        onHeightChange = nil
        onScroll = nil
        onAnnotationCreated = nil
        onScrollToPosition = nil
    }
}
