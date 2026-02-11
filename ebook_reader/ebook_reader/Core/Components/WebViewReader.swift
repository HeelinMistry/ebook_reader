import SwiftUI
import WebKit
import Observation

struct WebViewReader: UIViewRepresentable {
    let localURL: URL
    let book: Book
    @Bindable var prefs: ReaderPreferences
    let resolvedTheme: ReaderTheme

    func makeCoordinator() -> Coordinator {
        // The Coordinator is responsible for handling WKWebView delegates and
        // now also for receiving messages from JavaScript.
        Coordinator(parent: self, book: book)
    }

    func makeUIView(context: Context) -> WKWebView {
        let userContentController = WKUserContentController()
        // Register the coordinator as a script message handler.
        // JavaScript can send messages to Swift using `window.webkit.messageHandlers.contentReady.postMessage(...)`
        userContentController.add(context.coordinator, name: "contentReady")

        let config = WKWebViewConfiguration()
        config.userContentController = userContentController // Assign the content controller to the WKWebViewConfiguration
        
        // Prevents users from accidentally zooming in/out
        let webView = WKWebView(frame: .zero, configuration: config)
        
        webView.navigationDelegate = context.coordinator
        webView.scrollView.delegate = context.coordinator
        
        // Quality of life: Remove background noise
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        // Start invisible to prevent the "layout jump" before content is ready
        webView.alpha = 0 
        
        webView.loadFileURL(localURL, allowingReadAccessTo: localURL.deletingLastPathComponent())
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Apply styles and scroll position whenever relevant preferences or content change.
        // The `animate` parameter here refers to the scroll animation, not the fade-in.
        applyStylesAndScroll(to: uiView, animate: true)
    }

    func applyStylesAndScroll(to webView: WKWebView, animate: Bool = false) {
        // Advanced CSS for a "Book" feel
        let css = """
        /* 1. Reset everything to your preferred size */
        * {
            -webkit-text-size-adjust: none !important; /* Prevents iOS from 'guessing' font sizes */
        }

        body, p, div, span, li {
            background-color: \(resolvedTheme.rawValue) !important;
            color: \(resolvedTheme.textColor) !important;
            font-size: \(prefs.fontSize)px !important;
            line-height: 1.6 !important;
            font-family: -apple-system, serif !important;
        }

        /* 2. Scale headings RELATIVELY so they stay proportional */
        h1 { font-size: 1.6em !important; margin-top: 1em !important; }
        h2 { font-size: 1.4em !important; }
        h3 { font-size: 1.2em !important; }

        /* 3. Global layout polish */
        body {
            padding: 40px 25px !important;
            max-width: 700px !important;
            margin: 0 auto !important;
            text-align: justify !important;
            hyphens: auto !important;
            transition: background-color 0.3s ease;
        }
        """
        
        let scrollPercentage = book.lastReadLocation
        let escapedCSS = css.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "'", with: "\\'")

        let js = """
        (function() {
            var style = document.getElementById('reader-style');
            if (!style) {
                style = document.createElement('style');
                style.id = 'reader-style';
                document.head.appendChild(style);
            }
            style.innerHTML = `\(escapedCSS)`;

            // Wait for next animation frame to ensure styles are applied and layout is stable
            requestAnimationFrame(function() {
                var scrollHeight = document.body.scrollHeight;
                var scrollOffset = scrollHeight * \(scrollPercentage);
                window.scrollTo({
                    top: scrollOffset,
                    behavior: '\(animate ? "smooth" : "instant")'
                });
                // After styling and scrolling are complete, send a message to Swift
                window.webkit.messageHandlers.contentReady.postMessage('contentLoaded');
            });
        })();
        """
        
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("Error evaluating JavaScript: \(error)")
            }
            // The UIView.animate block has been removed from here.
            // The fade-in will now be triggered by the JavaScript message received by the Coordinator.
        }
    }

    // Coordinator now conforms to WKScriptMessageHandler to receive messages from JavaScript
    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate, WKScriptMessageHandler {
        var parent: WebViewReader
        var book: Book

        init(parent: WebViewReader, book: Book) {
            self.parent = parent
            self.book = book
        }

        // MARK: - WKNavigationDelegate
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // When the web page finishes loading, apply the styles and scroll to the last read position.
            // This will also trigger the JavaScript to send the 'contentReady' message.
            parent.applyStylesAndScroll(to: webView, animate: false)
        }

        // MARK: - UIScrollViewDelegate
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            saveProgress(scrollView)
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate { saveProgress(scrollView) }
        }

        private func saveProgress(_ scrollView: UIScrollView) {
            // Calculate progress based on content offset
            let percentage = scrollView.contentOffset.y / scrollView.contentSize.height
            guard percentage >= 0, percentage <= 1 else { return }
            
            Task { @MainActor in
                book.lastReadLocation = percentage
            }
        }
        
        // MARK: - WKScriptMessageHandler
        // This method is called when JavaScript sends a message to Swift.
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Check if the message name is "contentReady" and the body is "contentLoaded"
            if message.name == "contentReady", let body = message.body as? String, body == "contentLoaded" {
                // The WKWebView instance is provided as a parameter to this method.
                // Only animate if the webView is currently invisible.
                if let webView = message.webView, webView.alpha == 0 {
                    UIView.animate(withDuration: 0.5) {
                        webView.alpha = 1 // Fade in the web view smoothly
                    }
                }
            }
        }
    }
}
