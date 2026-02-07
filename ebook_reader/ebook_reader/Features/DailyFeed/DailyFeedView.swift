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
    
    // Fetch all daily collections, sorted by date in reverse
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
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Error Loading Feed",
                        systemImage: "network.slash",
                        description: Text(errorMessage)
                    )
                }
                else {
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
            .navigationDestination(for: Book.self) { book in
                ReaderView(book: book)
            }
            .refreshable {
                await viewModel.fetchDailyFeed(modelContext: modelContext)
            }
            .onAppear {
                // Auto-fetch if no collection for today exists and not already loading
                let today = Calendar.current.startOfDay(for: Date())
                let hasTodayCollection = collections.contains(where: {
                    Calendar.current.isDate($0.date, inSameDayAs: today)
                })
                
                if !hasTodayCollection && !viewModel.isLoading {
                    Task { await viewModel.fetchDailyFeed(modelContext: modelContext) }
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
