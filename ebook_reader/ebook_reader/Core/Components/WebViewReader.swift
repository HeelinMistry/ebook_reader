import SwiftUI
import WebKit
import Observation

struct WebViewReader: UIViewRepresentable {
    let localURL: URL
    let book: Book
    @Bindable var prefs: ReaderPreferences
    let resolvedTheme: ReaderTheme

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, book: book)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.delegate = context.coordinator
        
        // Allow the background to be transparent to prevent a white flash during load
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        webView.loadFileURL(localURL, allowingReadAccessTo: localURL.deletingLastPathComponent())
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // This handles updates to theme/font while the user is already looking at the book
        applyStylesAndScroll(to: uiView, animate: true)
    }

    // Moved to a shared function
    func applyStylesAndScroll(to webView: WKWebView, animate: Bool = false) {
        let css = """
        body {
            background-color: \(resolvedTheme.rawValue) !important;
            color: \(resolvedTheme.textColor) !important;
            font-size: \(prefs.fontSize)px !important;
            transition: background-color 0.3s ease, color 0.3s ease;
            font-family: -apple-system, Helvetica, Arial, sans-serif !important;
            line-height: 1.6 !important;
            padding: 20px !important;
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

            requestAnimationFrame(function() {
                var scrollHeight = document.body.scrollHeight;
                var scrollOffset = scrollHeight * \(scrollPercentage);
                window.scrollTo({
                    top: scrollOffset,
                    behavior: '\(animate ? "smooth" : "instant")'
                });
            });
        })();
        """
        
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var parent: WebViewReader
        var book: Book

        init(parent: WebViewReader, book: Book) {
            self.parent = parent
            self.book = book
        }

        // 1. THIS IS THE KEY: Runs when the HTML is fully ready
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.applyStylesAndScroll(to: webView, animate: false)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            saveProgress(scrollView)
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate { saveProgress(scrollView) }
        }

        private func saveProgress(_ scrollView: UIScrollView) {
            let percentage = scrollView.contentOffset.y / scrollView.contentSize.height
            // Filter out edge cases
            guard percentage >= 0 else { return }
            
            Task { @MainActor in
                book.lastReadLocation = percentage
            }
        }
    }
}
