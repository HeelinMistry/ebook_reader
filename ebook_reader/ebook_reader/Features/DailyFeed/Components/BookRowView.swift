//
//  BookRowView.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/06.
//

import SwiftUI

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack(alignment: .top) {
            // Placeholder Cover
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 75)
                .overlay(
                    Image(systemName: "text.book.closed")
                        .foregroundColor(.secondary)
                )
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(book.displayTitle)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                    Spacer()
                    Text("\(book.languageTag)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(book.author)
                    .font(.subheadline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            
                if book.isDownloaded {
                    Label("Downloaded", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
