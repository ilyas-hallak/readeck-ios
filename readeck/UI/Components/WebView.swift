import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let htmlContent: String
    let settings: Settings
    let onHeightChange: (CGFloat) -> Void
    var onScroll: ((Double) -> Void)? = nil
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
        
        // Message Handler hier einmalig hinzufügen
        webView.configuration.userContentController.add(context.coordinator, name: "heightUpdate")
        webView.configuration.userContentController.add(context.coordinator, name: "scrollProgress")
        context.coordinator.onHeightChange = onHeightChange
        context.coordinator.onScroll = onScroll
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Nur den HTML-Inhalt laden, keine Handler-Konfiguration
        context.coordinator.onHeightChange = onHeightChange
        context.coordinator.onScroll = onScroll
        
        let isDarkMode = colorScheme == .dark
        
        // Font Settings aus Settings-Objekt
        let fontSize = getFontSize(from: settings.fontSize ?? .extraLarge)
        let fontFamily = getFontFamily(from: settings.fontFamily ?? .serif)
        
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
            </style>
        </head>
        <body>
            \(htmlContent)
            <script>
                function updateHeight() {
                    const height = document.body.scrollHeight;
                    window.webkit.messageHandlers.heightUpdate.postMessage(height);
                }
                
                window.addEventListener('load', updateHeight);
                setTimeout(updateHeight, 500);
                
                // Höhe bei Bild-Ladevorgängen aktualisieren
                document.querySelectorAll('img').forEach(img => {
                    img.addEventListener('load', updateHeight);
                });
                // Scroll progress reporting
                window.addEventListener('scroll', function() {
                    var scrollTop = window.scrollY || document.documentElement.scrollTop;
                    var docHeight = document.documentElement.scrollHeight - document.documentElement.clientHeight;
                    var progress = docHeight > 0 ? scrollTop / docHeight : 0;
                    window.webkit.messageHandlers.scrollProgress.postMessage(progress);
                });
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
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
}

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var onHeightChange: ((CGFloat) -> Void)?
    var onScroll: ((Double) -> Void)?
    var hasHeightUpdate: Bool = false
    
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
                if self.hasHeightUpdate == false {
                    self.onHeightChange?(height)
                    self.hasHeightUpdate = true
                }
            }
        }
        if message.name == "scrollProgress", let progress = message.body as? Double {
            DispatchQueue.main.async {
                self.onScroll?(progress)
            }
        }
    }
}
