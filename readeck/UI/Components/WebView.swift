import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let htmlContent: String
    let onHeightChange: (CGFloat) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        
        // Message Handler hier einmalig hinzufügen
        webView.configuration.userContentController.add(context.coordinator, name: "heightUpdate")
        context.coordinator.onHeightChange = onHeightChange
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Nur den HTML-Inhalt laden, keine Handler-Konfiguration
        context.coordinator.onHeightChange = onHeightChange
        
        let styledHTML = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.8;
                    margin: 0;
                    padding: 16px;
                    color: #1a1a1a;
                    font-size: 16px;
                }
                h1, h2, h3, h4, h5, h6 {
                    color: #000;
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
                    color: #007AFF;
                    text-decoration: none;
                }
                a:hover {
                    text-decoration: underline;
                }
                blockquote {
                    border-left: 4px solid #007AFF;
                    margin: 16px 0;
                    padding-left: 16px;
                    font-style: italic;
                    color: #666;
                }
                code {
                    background-color: #f5f5f5;
                    padding: 2px 4px;
                    border-radius: 4px;
                    font-family: 'SF Mono', Consolas, monospace;
                    font-size: 14px;
                }
                pre {
                    background-color: #f5f5f5;
                    padding: 12px;
                    border-radius: 8px;
                    overflow-x: auto;
                    font-family: 'SF Mono', Consolas, monospace;
                    font-size: 14px;
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