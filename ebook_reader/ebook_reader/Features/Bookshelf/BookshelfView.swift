//
//  BookshelfView.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/07.
//

import SwiftUI
import SwiftData

struct BookshelfView: View {
    // Only fetch books that are either downloaded or specifically marked as "saved"
    @Query(filter: #Predicate<Book> { $0.localFileName != nil },
           sort: \Book.id)
    private var myBooks: [Book]

    var body: some View {
        NavigationStack {
            List {
                if myBooks.isEmpty {
                    ContentUnavailableView("Your Bookshelf is Empty",
                        systemImage: "book.closed",
                        description: Text("Download a book from the Daily Feed or Catalog to see it here."))
                } else {
                    ForEach(myBooks) { book in
                        NavigationLink(destination: ReaderView(book: book)) {
                            BookRowView(book: book)
                        }
                    }
                }
            }
            .navigationTitle("My Bookshelf")
        }
    }
}

