import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let htmlContent: String
    let onHeightChange: (CGFloat) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        
        // Message Handler hier einmalig hinzufügen
        webView.configuration.userContentController.add(context.coordinator, name: "heightUpdate")
        context.coordinator.onHeightChange = onHeightChange
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Nur den HTML-Inhalt laden, keine Handler-Konfiguration
        context.coordinator.onHeightChange = onHeightChange
        
        let isDarkMode = colorScheme == .dark
        
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
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.8;
                    margin: 0;
                    padding: 16px;
                    background-color: var(--background-color);
                    color: var(--text-color);
                    font-size: 16px;
                    -webkit-text-size-adjust: 100%;
                }
                
                h1, h2, h3, h4, h5, h6 {
                    color: var(--heading-color);
                    margin-top: 24px;
                    margin-bottom: 12px;
                    font-weight: 600;
                }
                h1 { font-size: 24px; }
                h2 { font-size: 20px; }
                h3 { font-size: 18px; }
                
                p {
                    margin-bottom: 16px;
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
                }
                
                code {
                    background-color: var(--code-background);
                    color: var(--code-text);
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-family: 'SF Mono', Menlo, Monaco, Consolas, monospace;
                    font-size: 14px;
                }
                
                pre {
                    background-color: var(--code-background);
                    color: var(--code-text);
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                    font-family: 'SF Mono', Menlo, Monaco, Consolas, monospace;
                    font-size: 14px;
                    border: 1px solid var(--separator-color);
                }
                
                pre code {
                    background-color: transparent;
                    padding: 0;
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
                setTimeout(updateHeight, 100);
                setTimeout(updateHeight, 500);
                setTimeout(updateHeight, 1000);
                
                // Höhe bei Bild-Ladevorgängen aktualisieren
                document.querySelectorAll('img').forEach(img => {
                    img.addEventListener('load', updateHeight);
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
}

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var onHeightChange: ((CGFloat) -> Void)?
    
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
                self.onHeightChange?(height)
            }
        }
    }
    
    deinit {
        // Der Message Handler wird automatisch mit der WebView entfernt
    }
}