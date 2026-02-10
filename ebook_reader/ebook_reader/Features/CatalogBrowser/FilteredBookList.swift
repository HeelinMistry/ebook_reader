//
//  FilteredBookList.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/10.
//

import SwiftUI
import SwiftData


struct FilteredBookList: View {
    @Environment(\.modelContext) private var modelContext
    @Query var books: [Book]
    
    // Define a constant for the fetch limit for better readability and maintainability.
    private let fetchLimit = 100
    
    init(searchText: String) {
        let predicate = #Predicate<Book> { book in
            if searchText.isEmpty {
                return true
            } else {
                // Search title OR explicitAuthor
                // Use optional chaining with '== true' for explicitAuthor to avoid nil-coalescing issues in SwiftData predicate translation.
                return book.title.localizedStandardContains(searchText) ||
                       (book.explicitAuthor?.localizedStandardContains(searchText) == true)
            }
        }
        
        // Apply the limit directly to the SwiftData query for efficiency.
        // This tells the database to only fetch up to `fetchLimit` records.
        var descriptor = FetchDescriptor<Book>(predicate: predicate, sortBy: [SortDescriptor(\.title)])
        descriptor.fetchLimit = fetchLimit
        _books = Query(descriptor)
    }
    
    var body: some View {
        List {
            // The query already limits to `fetchLimit`, so iterate directly over 'books'.
            ForEach(books) { book in
                NavigationLink(destination: ReaderView(book: book)) {
                    BookRowView(book: book)
                }
            }
            
            // This condition now means that we've reached the fetch limit,
            // implying there might be more results than what was fetched.
            if books.count == fetchLimit {
                Text("Showing first \(fetchLimit) matches...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if books.isEmpty {
                ContentUnavailableView.search(text: "No books found")
            }
        }
    }
}
