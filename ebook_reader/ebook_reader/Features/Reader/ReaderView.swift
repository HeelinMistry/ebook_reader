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
    @StateObject private var downloadService = DownloadService()
    @Environment(\.modelContext) private var modelContext
    @State private var isDownloading = false
    
    var body: some View {
        VStack {
            // which now correctly checks the dynamically resolved path.
            if book.isDownloaded, let fileURL = book.actualLocalFileURL {
                // Determine how to render based on file extension
                if fileURL.pathExtension.lowercased() == "html" {
                    WebViewReader(localURL: fileURL)
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

