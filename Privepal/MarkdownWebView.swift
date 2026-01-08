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
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css">
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
                
                /* Container for the code block structure */
                .code-container {
                    background: #24292e; /* Matches github-dark bg (approx) */
                    border-radius: 8px;
                    margin: 12px 0;
                    overflow: hidden;
                    border: 1px solid #444;
                }
                
                /* Header bar with Language and Copy button */
                .code-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    background: #393e46; /* Slightly lighter header */
                    padding: 6px 12px;
                    font-family: inherit;
                    color: #bbb;
                    font-size: 13px;
                    border-bottom: 1px solid #444;
                }
                
                .lang-label {
                    font-weight: 600;
                    text-transform: lowercase;
                }
                
                .copy-btn {
                    background: none;
                    border: none;
                    cursor: pointer;
                    padding: 2px;
                    color: #bbb;
                    display: flex;
                    align-items: center;
                }
                
                .copy-btn svg {
                    width: 16px;
                    height: 16px;
                    fill: currentColor;
                }
                
                .copy-btn:hover {
                    color: white;
                }

                pre {
                    margin: 0;
                    padding: 12px;
                    overflow-x: auto;
                    background: transparent; /* Let container bg show through */
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
                // 1. Configure marked
                marked.use(markedKatex({
                  throwOnError: false
                }));
                
                // Custom renderer for code blocks to wrap them in our structure
                const renderer = new marked.Renderer();
                
                // marked v4+ sends ({ text, lang, escaped }) or just (code, lang) depending on version/options.
                // But let's stick to standard (code, lang) which works with string concatenation.
                renderer.code = function({ text, lang, escaped } = {}) {
                    // Fallback for older signatures or direct string calls (though marked doesn't usually do that anymore)
                    const codeContent = text || arguments[0]; 
                    const language = lang || arguments[1] || 'plaintext';
                    
                    const validLang = hljs.getLanguage(language) ? language : 'plaintext';
                    
                    let highlighted;
                    try {
                        highlighted = hljs.highlight(codeContent, { language: validLang }).value;
                    } catch (e) {
                         highlighted = codeContent; // fallback
                    }

                   return `
                   <div class="code-container">
                       <div class="code-header">
                           <span class="lang-label">${language}</span>
                           <button class="copy-btn" onclick="copyCode(this)">
                               <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"/></svg>
                           </button>
                       </div>
                       <pre><code class="hljs ${validLang}">${highlighted}</code></pre>
                   </div>
                   `;
                };
                
                marked.use({ renderer });

                const rawMarkdown = `\(finalEscapedContent)`;
                
                // 2. Parse Markdown
                document.getElementById('content').innerHTML = marked.parse(rawMarkdown);
                
                // 3. (Highlighting is handled by renderer now)
                
                // 4. Copy Function
                window.copyCode = function(btn) {
                    const code = btn.closest('.code-container').querySelector('code').innerText;
                    // Native bridge can be better, but simple clipboard API works on newer iOS webviews
                    // Or communicate back to swift. For now simpler:
                    /*
                       Using a hidden textarea hack is safer in restricted webviews if nav.clipboard fails
                    */
                    const textArea = document.createElement("textarea");
                    textArea.value = code;
                    document.body.appendChild(textArea);
                    textArea.select();
                    try {
                        document.execCommand('copy');
                        // Feedback
                        const originalSVG = btn.innerHTML;
                        btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>';
                        setTimeout(() => { btn.innerHTML = originalSVG; }, 1500);
                    } catch (err) { }
                    document.body.removeChild(textArea);
                }
            </script>
        </body>
        </html>
        """
    }
} 