//
//  DailyFeedViewModel.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/06.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class DailyFeedViewModel: NSObject, ObservableObject, XMLParserDelegate {
    override init() {
        super.init()
    }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    
    private var parser: RSSFeedParserDelegate?
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentBooksBuffer: [Book] = []

    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func fetchDailyFeed() async {
        guard let context = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        currentBooksBuffer = [] // Reset buffer
        
        guard let url = URL(string: "https://www.gutenberg.org/cache/epub/feeds/today.rss") else {
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            currentBooksBuffer = try await parseXMLData(data)
            // After parsing, save data to SwiftData
            try syncBufferToDatabase(context: context)
            
        } catch {
            errorMessage = "Error loading feed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func syncBufferToDatabase(context: ModelContext) throws {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 1. Get or Create "DailyCollection" for today
        // We use a Predicate to find if today already exists
        let collectionDescriptor = FetchDescriptor<DailyCollection>(
            predicate: #Predicate { $0.date == today }
        )
        
        let dailyCollection: DailyCollection
        if let existing = try context.fetch(collectionDescriptor).first {
            dailyCollection = existing
        } else {
            dailyCollection = DailyCollection(date: today)
            context.insert(dailyCollection)
        }
        
        // 2. Add books to the collection
        for book in currentBooksBuffer {
            // Check if Book already exists in the main catalog
            let bookIDToMatch = book.id
            let bookDescriptor = FetchDescriptor<Book>(
                predicate: #Predicate { $0.id == bookIDToMatch }
            )
            if let existingBook = try context.fetch(bookDescriptor).first {
                // Book exists, link it to today's collection if not already there
                if !dailyCollection.books.contains(existingBook) {
                    dailyCollection.books.append(existingBook)
                }
            } else {
                context.insert(book)
                dailyCollection.books.append(book)
            }
        }
        
        // 3. Persist changes
        try context.save()
    }
    
    private func parseXMLData(_ data: Data) async throws -> [Book] {
        return try await withCheckedThrowingContinuation { continuation in
            let parserDelegate = RSSFeedParserDelegate(continuation: continuation)
            let parser = XMLParser(data: data)
            parser.delegate = parserDelegate
            
            if !parser.parse() {
                let errorDescription = parser.parserError?.localizedDescription ?? "Unknown synchronous parsing error"
                print("XML Parse failed synchronously: \(errorDescription)")
                continuation.resume(throwing: FeedServiceError.parsingError(errorDescription))
            }
        }
    }
}
