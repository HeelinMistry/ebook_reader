//
//  CatalogService.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/07.
//

import Foundation
import SwiftData

actor CatalogService {
    
    enum CatalogError: Error {
        case fileNotFound
        case downloadFailed
        case parsingFailed
        case bookCreationFailed(String)
        case bookUpdateFailed(String) // NEW: Added an error for update failures
    }

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Determines if we should run the import
    func needsInitialImport() async -> Bool {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Book>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        // If we have less than 1,000 books, we probably only have the daily feed
        // and should run the full 70k import.
        return count < 1000
    }

    /// Imports the catalog from a CSV, optionally linking books to a specific DailyCollection.
    /// - Parameters:
    ///   - url: The URL of the CSV catalog. If nil, uses the bundled seed_catalog.csv.
    ///   - targetDailyCollectionDate: The date of an optional `DailyCollection` to which processed books will be linked.
    ///                            If provided, existing books will be fetched (not skipped) to allow linking.
    func importCatalog(from url: URL? = nil, targetDailyCollectionDate: Date? = nil) async throws {
        // 1. Determine Source
        let sourceURL: URL
        if let url = url {
            print("Downloading catalog from web...")
            sourceURL = url
        } else {
            print("Loading catalog from Bundle...")
            guard let bundleURL = Bundle.main.url(forResource: "seed_catalog", withExtension: "csv") else {
                throw CatalogError.fileNotFound
            }
            sourceURL = bundleURL
        }
        
        // 2. Load Data (Background)
        let data: Data
        if sourceURL.isFileURL {
            data = try Data(contentsOf: sourceURL)
        } else {
            let (downloadedData, _) = try await URLSession.shared.data(from: sourceURL)
            data = downloadedData
        }
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw CatalogError.parsingFailed
        }
        
        // 3. Parse CSV (Background)
        print("Parsing CSV...")
        let allRows = await CSVParser.parse(content)
        
        // 4. Switch to MainActor to interact with SwiftData
        await MainActor.run {
            let context = ModelContext(modelContainer)
            
            print("Fetching existing IDs for initial check...")
            // Fetch ONLY the IDs of existing books to efficiently check if a book already exists.
            // If `targetDailyCollectionDate` is provided, we will later fetch the actual `Book` object
            // for existing books instead of skipping.
            var existingIDs: Set<String> = []
            do {
                let descriptor = FetchDescriptor<Book>()
                let books = try context.fetch(descriptor)
                existingIDs = Set(books.map { $0.id })
            } catch {
                print("Failed to fetch existing book IDs: \(error)")
            }
            
            print("Filtering \(allRows.count) rows against \(existingIDs.count) existing books...")
            
            var insertedCount = 0
            var updatedCount = 0 // NEW: Counter for updated books
            var linkedToDailyCollectionCount = 0
            
            // If a targetDailyCollectionDate is provided, ensure it's fetched or available in the current context
            var collectionToUpdate: DailyCollection? = nil
            if let date = targetDailyCollectionDate {
                let fetchCollectionDescriptor = FetchDescriptor<DailyCollection>(
                    predicate: #Predicate { $0.date == date }
                )
                // Try to fetch it from the context.
                if let existingCollection = try? context.fetch(fetchCollectionDescriptor).first {
                    collectionToUpdate = existingCollection
                } else {
                    // No existing collection found, so create a new one and insert it.
                    let newCollection = DailyCollection(date: date)
                    context.insert(newCollection)
                    collectionToUpdate = newCollection
                }
            }
            
            // 5. Process Rows: Insert new books, or fetch existing ones if needed for linking/updating
            for row in allRows {
                guard !row.isEmpty else { continue }
                
                let rawID = row[0].replacingOccurrences(of: "\"", with: "")
                
                var bookToProcess: Book? = nil
                
                if existingIDs.contains(rawID) {
                    // Book already exists. Fetch it.
                    let fetchDescriptor = FetchDescriptor<Book>(predicate: #Predicate { $0.id == rawID })
                    if let existingBook = try? context.fetch(fetchDescriptor).first {
                        bookToProcess = existingBook // Found the existing book
                        
                        // NEW LOGIC: If it's a full catalog import (no specific targetDailyCollectionDate),
                        // attempt to update the existing book's details from the current catalog row.
                        if targetDailyCollectionDate == nil {
                            do {
                                try existingBook.update(from: row) // Call the new update method on Book
                                updatedCount += 1
                            } catch CatalogError.bookCreationFailed(let reason) {
                                // This happens if the updated row no longer meets filtering criteria (e.g., language/type changed)
                                print("Skipping update for book ID \(rawID) due to filtering criteria change: \(reason)")
                                bookToProcess = nil // Do not process this book further (e.g., if it was to be linked to a collection, skip it)
                            } catch {
                                print("Failed to update existing book ID \(rawID): \(error)")
                                // Log the error, but continue processing other books.
                                // If you want to halt the entire import on an update failure, rethrow the error.
                                // throw CatalogError.bookUpdateFailed("ID \(rawID): \(error.localizedDescription)")
                                bookToProcess = nil // If update fails, don't link it either.
                            }
                        }
                    } else {
                        // This case should ideally not happen if existingIDs is accurate,
                        // but if fetching by ID fails after existingIDs said it exists,
                        // it's safer to just skip this row for further processing.
                        print("Warning: Book ID \(rawID) found in existingIDs but failed to fetch from context. Skipping.")
                        continue
                    }
                } else {
                    // This is a new book. Create and Insert.
                    do {
                        let newBook = try Book(catalogRow: row)
                        context.insert(newBook)
                        bookToProcess = newBook
                        insertedCount += 1
                    } catch CatalogError.bookCreationFailed {
                        // Expected error for non-English/non-Text books that don't meet filtering criteria. Skip this row.
                        continue
                    } catch {
                        print("Skipping row due to book creation error: \(error)")
                    }
                }
                
                // If we have a book (either existing or newly created/updated) and a collection to link to
                if let book = bookToProcess, let collection = collectionToUpdate {
                    // Only add the book to the collection if it's not already present.
                    if !collection.books.contains(where: { $0.id == book.id }) {
                        collection.books.append(book)
                        linkedToDailyCollectionCount += 1
                    }
                }
            }
            
            // 6. Save Once at the end
            do {
                try context.save()
                var logMessage = "Import Success: Added \(insertedCount) new books, updated \(updatedCount) existing books." 
                if targetDailyCollectionDate != nil {
                    logMessage += " Linked \(linkedToDailyCollectionCount) books to DailyCollection for \(collectionToUpdate?.date.formatted(date: .abbreviated, time: .omitted) ?? "unknown date")."
                }
                print(logMessage)
            } catch {
                print("Save failed: \(error)")
                // In a production app, you might want more robust error handling or rethrowing here.
            }
        }
    }
}
