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
    @State private var importProgress: Double = 0 // Placeholder for real progress
    
    // Check if we have any books at all
    @Query private var anyBooks: [Book]
    
    // Real Search Query
    @State private var searchText = ""
    @Query var filteredBooks: [Book]
    
    init() {
        // Initialize Query with empty filter or sort
        _filteredBooks = Query(sort: \Book.id)
    }

    var body: some View {
        NavigationStack {
            Group {
                if anyBooks.isEmpty {
                    // --- EMPTY STATE: IMPORT BUTTON ---
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
//                        else {
//                            Button("Import Catalog (25MB)") {
//                                startImport()
//                            }
//                            .buttonStyle(.borderedProminent)
//                        }
                    }
                } else {
                    // --- SEARCH LIST ---
                    List {
                        ForEach(filteredBooks) { book in
                            NavigationLink(destination: ReaderView(book: book)) {
                                BookRowView(book: book)
                            }
                        }
                    }
                    .searchable(text: $searchText)
                    .onChange(of: searchText) { _, newValue in
                        updateSearch(newValue)
                    }
                }
            }
            .navigationTitle("Catalog")
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
    
    // Dynamic Search Filter
    func updateSearch(_ text: String) {
        // SwiftData Predicates don't support complex string operations efficiently yet,
        // but simple "contains" works well.
        if text.isEmpty {
             // Return top 100 or so to avoid UI lag
        } else {
             // Apply predicate
        }
    }
}

