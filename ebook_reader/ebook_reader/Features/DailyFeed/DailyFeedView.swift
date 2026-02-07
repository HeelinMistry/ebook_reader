//
//  DailyFeedView.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/06.
//

import SwiftUI
import SwiftData

struct DailyFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DailyFeedViewModel()
    
    // Fetch today's collection automatically
    // We filter for entries where 'date' is today
    @Query(sort: \DailyCollection.date, order: .reverse)
    private var collections: [DailyCollection]
    
    var body: some View {
        NavigationStack {
            List {
                if collections.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Feeds Found",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Pull to refresh to load today's books.")
                    )
                } else {
                    // Iterate through every day found in persistent storage
                    ForEach(collections) { collection in
                        Section(header: Text(formatDate(collection.date))) {
                            ForEach(collection.books) { book in
                                NavigationLink(value: book) {
                                    BookRowView(book: book)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Gutenberg Feed")
            .refreshable {
                await viewModel.fetchDailyFeed()
            }
            .onAppear {
                // Pass the context to VM so it can save data
                viewModel.setContext(modelContext)
                
                // Auto-fetch if empty
                if collections.isEmpty {
                    Task { await viewModel.fetchDailyFeed() }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Fetching Gutenberg...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}
