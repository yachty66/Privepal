import SwiftUI
import WebKit

struct MarkdownWebView: UIViewRepresentable {
    let markdown: String
    @Binding var dynamicHeight: CGFloat
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Make background transparent
        config.setValue(false, forKey: "drawsBackground")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false // Sizing to content
        webView.scrollView.bounces = false
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if content changed significantly to avoid jitter, 
        // but for a chat simple reload is safer for correctness
        let html = generateHTML(from: markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MarkdownWebView
        
        init(_ parent: MarkdownWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Calculate height
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { (result, error) in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        // Avoid infinite loops by only updating if difference is significant
                        if abs(self.parent.dynamicHeight - height) > 1 {
                            self.parent.dynamicHeight = height
                        }
                    }
                }
            }
        }
    }
    
    private func generateHTML(from content: String) -> String {
        // Pre-process LLM-style math delimiters to standard Markdown math delimiters
        // This is necessary because many LLMs output \[ \] and \( \) which 'marked' interprets as escaped brackets
        var fixedContent = content
            .replacingOccurrences(of: "\\[", with: "$$")
            .replacingOccurrences(of: "\\]", with: "$$")
            .replacingOccurrences(of: "\\(", with: "$")
            .replacingOccurrences(of: "\\)", with: "$")
            
        // Escape content for JS string
        let finalEscapedContent = fixedContent
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "${", with: "\\${") // Only escape ${ to prevent JS interpolation
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
            
            <!-- Marked (Markdown Parser) -->
            <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
            
            <!-- KaTeX (Math) -->
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
            <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
            
            <!-- Marked KaTeX Extension -->
            <script src="https://cdn.jsdelivr.net/npm/marked-katex-extension/lib/index.umd.js"></script>
            
            <!-- Highlight.js (Code Highlighting) -->
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css">
            <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>

            <style>
                body {
                    color: white;
                    background-color: transparent;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    font-size: 17px;
                    line-height: 1.5;
                    margin: 0;
                    padding: 0;
                    word-wrap: break-word;
                }
                pre {
                    background: #282c34;
                    padding: 12px;
                    border-radius: 8px;
                    overflow-x: auto;
                    margin: 8px 0;
                }
                code {
                    font-family: "Menlo", "Consolas", monospace;
                    font-size: 0.9em;
                }
                .katex-display {
                    overflow-x: auto;
                    overflow-y: hidden;
                    padding: 4px 0;
                }
                p {
                    margin: 0 0 10px 0;
                }
                blockquote {
                    border-left: 4px solid #555;
                    margin: 0;
                    padding-left: 16px;
                    color: #aaa;
                }
                img {
                    max-width: 100%;
                    border-radius: 6px;
                }
            </style>
        </head>
        <body>
            <div id="content"></div>
            
            <script>
                // 1. Configure marked with KaTeX extension and Highlight.js
                // The extension exposes 'markedKatex' globally
                marked.use(markedKatex({
                  throwOnError: false
                }));

                const rawMarkdown = `\(finalEscapedContent)`;
                
                // 2. Parse Markdown (math will be rendered by the extension during parsing)
                document.getElementById('content').innerHTML = marked.parse(rawMarkdown);
                
                // 3. Highlight Code
                hljs.highlightAll();
            </script>
        </body>
        </html>
        """
    }
}
