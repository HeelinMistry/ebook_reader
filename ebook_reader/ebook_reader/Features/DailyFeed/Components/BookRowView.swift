//
//  BookRowView.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/06.
//

import SwiftUI
import SwiftData

struct BookRowView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext // Inject ModelContext for cover download/save
    
    // Inject CoverImageService
    // Using @StateObject to ensure the service instance lives for the lifetime of the view
    // or as long as it's needed. For simpler cases, you could also pass it from a parent view.
    @StateObject private var downloadService = DownloadService()
    
    var body: some View {
        HStack(alignment: .top) {
            // Display Cover Image
            AsyncImage(url: book.actualLocalCoverURL ?? book.coverURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    // Show a generic book icon if there's an error loading the image (e.g., URL invalid, network down)
                    Image(systemName: "text.book.closed")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(10)
                        .foregroundColor(.secondary)
                        .background(Color.gray.opacity(0.1))
                } else {
                    // Show a progress view while the image is loading
                    ProgressView()
                }
            }
            .frame(width: 50, height: 75) // Standard size for the cover thumbnail
            .cornerRadius(4) // Rounded corners for aesthetics
            .clipped() // Ensures image content is clipped to the frame
            .task {
                // This .task block runs when the view appears.
                // It checks if a local cover image needs to be downloaded.
                // This makes covers available offline after they've been viewed once.
                // Call the service method, passing the book and modelContext.
                if book.localCoverFileName == nil || book.actualLocalCoverURL == nil || !FileManager.default.fileExists(atPath: book.actualLocalCoverURL!.path(percentEncoded: false)) {
                    await downloadService.downloadCover(for: book, using: modelContext)
                }
            }
            
            VStack(alignment: .leading) {
                Text(book.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                Text(book.author)
                    .font(.subheadline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                HStack() {
                    Text("\(book.languageTag)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if book.isDownloaded {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
