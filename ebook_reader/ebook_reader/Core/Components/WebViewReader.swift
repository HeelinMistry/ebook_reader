//
//  WebViewReader.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/07.
//

import SwiftUI
import WebKit

struct WebViewReader: UIViewRepresentable {
    let localURL: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // We load the file from the Documents folder.
        // readAccessTo is vital for security permissions.
        let directory = localURL.deletingLastPathComponent()
        uiView.loadFileURL(localURL, allowingReadAccessTo: directory)
        
        // Inject CSS to make it look like a book
        let css = """
            body { 
                font-family: -apple-system, sans-serif; 
                line-height: 1.6; 
                padding: 20px; 
                font-size: 110%;
                color: #333;
                background-color: #fdfaf3; /* Sepia-ish */
            }
            img { max-width: 100%; height: auto; }
        """
        let script = "var style = document.createElement('style'); style.innerHTML = '\(css)'; document.head.appendChild(style);"
        uiView.evaluateJavaScript(script)
    }
}
