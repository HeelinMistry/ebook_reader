//
//  CatalogBrowserView.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/07.
//
import SwiftUI
import SwiftData

struct CatalogBrowserView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isImporting = false
    
    // Check if we have any books at all
    @Query private var anyBooks: [Book]
    
    // Real Search Query
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if anyBooks.isEmpty {
                    emptyStateView
                } else {
                    // Pass the searchText to our subview
                    FilteredBookList(searchText: searchText)
                }
            }
            .navigationTitle("Catalog")
            .searchable(text: $searchText, prompt: "Search 70,000+ books...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .none) {
                        startImport()
                    } label: {
                        // The icon will now spin continuously while `isImporting` is true
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.green)
                        // Apply a rotation. If importing, target 360 degrees.
                            .rotationEffect(.degrees(isImporting ? 360 : 0))
                        // Animate the rotation. If importing, use a linear, repeating animation.
                        // Otherwise, use a default animation to smoothly return to 0 degrees.
                            .animation(isImporting ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isImporting)
                    }
                }
            }
        }
    }
    
    func startImport() {
        isImporting = true
        Task {
            // Initialize CatalogService with the ModelContainer from the environment's modelContext
            let service = CatalogService(modelContainer: modelContext.container)
            // Use the Live URL
            let liveURL = URL(string: "https://www.gutenberg.org/cache/epub/feeds/pg_catalog.csv")
            
            // Call importCatalog without the 'context' parameter
            try? await service.importCatalog(from: liveURL)
            
            isImporting = false
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical.circle")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            Text("Library Empty")
                .font(.title2)
            Text("Import the Project Gutenberg catalog to search 70,000+ books.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            if isImporting {
                ProgressView("Importing Database...")
                    .padding()
            }
        }
    }
}
