//
//  ReaderView.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/07.
//

import SwiftUI
import SwiftData

struct ReaderView: View {
    let book: Book
    @State private var prefs = ReaderPreferences()
    @Environment(\.colorScheme) var colorScheme // Detects iOS Light/Dark mode
    @State private var showSettings = false
    
    @StateObject private var downloadService = DownloadService()
    @Environment(\.modelContext) private var modelContext
    @State private var isDownloading = false
    
    private var effectiveTheme: ReaderTheme {
        if prefs.useSystemTheme {
            return colorScheme == .dark ? .dark : .light
        }
        return prefs.theme
    }
    
    var body: some View {
        VStack {
            // which now correctly checks the dynamically resolved path.
            if book.isDownloaded, let fileURL = book.actualLocalFileURL {
                // Determine how to render based on file extension
                if fileURL.pathExtension.lowercased() == "html" {
                    WebViewReader(localURL: fileURL, book: book, prefs: prefs, resolvedTheme: effectiveTheme)
                        .ignoresSafeArea(edges: .bottom)
                } else if fileURL.pathExtension.lowercased() == "epub3" {
                    // WKWebView cannot directly render EPUB.
                    // You would need a dedicated EPUB parsing/rendering solution here.
                    VStack(spacing: 15) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        Text("EPUB file downloaded!")
                            .font(.headline)
                        Text("A dedicated EPUB reader or conversion to HTML is needed to view this format.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // Fallback for unexpected file types
                    ContentUnavailableView(
                        "Unsupported File Type",
                        systemImage: "xmark.octagon.fill",
                        description: Text("The downloaded file format is not supported for reading in this app.")
                    )
                }
            } else {
                // File not downloaded or path is invalid, show download screen
                downloadView
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings.toggle() } label: {
                    Image(systemName: "textformat.size")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ReaderSettingsView(prefs: prefs)
            // 1. Explicitly use PresentationDetent
                .presentationDetents([PresentationDetent.height(250)])
            
            // 2. Explicitly use PresentationBackgroundInteraction
                .presentationBackgroundInteraction(PresentationBackgroundInteraction.enabled)
        }
        .navigationTitle(book.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Debugging: Log the state when ReaderView appears
            print("ReaderView appeared for Book ID: \(book.id). Is Downloaded: \(book.isDownloaded). Local File Name: \(book.localFileName ?? "nil")")
            if let url = book.actualLocalFileURL {
                print("Actual Local File URL: \(url.path(percentEncoded: false))")
            }
        }
        .toolbar {
            if book.isDownloaded {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        downloadService.deleteLocalFile(for: book, using: modelContext)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
    
    private var downloadView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.pages")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            Text(book.displayTitle)
                .font(.headline)
                .multilineTextAlignment(.center)
            if isDownloading {
                ProgressView("Fetching chapters...")
            } else {
                Button("Download for Offline Reading (HTML)") {
                    Task {
                        isDownloading = true
                        await downloadService.startDownloadHTML(for: book, using: modelContext)
                        isDownloading = false
                    }
                }
                .buttonStyle(.borderedProminent)
                Button("Download for Offline Reading (EPUB)") {
                    Task {
                        isDownloading = true
                        await downloadService.startDownloadEPUB(for: book, using: modelContext)
                        isDownloading = false
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
