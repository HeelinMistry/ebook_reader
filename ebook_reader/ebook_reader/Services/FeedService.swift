import Foundation
import Combine
import SwiftData

// MARK: - Error Handling

public enum FeedServiceError: Error {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case noFeedFound(Date) // New error for when no cached feed is found
    
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "The feed URL is invalid."
        case .networkError(let error):
            return "A network error occurred: \(error.localizedDescription)"
        case .parsingError(let reason):
            return "Failed to parse the feed: \(reason)"
        case .noFeedFound(let date):
            return "No cached feed found for \(date.formatted(date: .abbreviated, time: .omitted))."
        }
    }
}

// MARK: - Service

@MainActor
final public class FeedService: ObservableObject {
    @Published private(set) var isLoading: Bool = false
    @Published public var error: FeedServiceError?
    
    private let urlSession: URLSession
    
    // Dependency Injection for URLSession
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    /// Fetches the daily feed from Gutenberg, parses it, and persists the books and daily collection to SwiftData.
    /// - Parameter modelContext: The ModelContext to use for persistence.
    public func refreshDailyFeed(modelContext: ModelContext) async {
        self.error = nil // Clear any previous errors
        
        // Prevent concurrent fetches if one is already in progress
        guard !isLoading else {
            print("Fetch already in progress. Skipping.")
            return
        }
        
        self.isLoading = true // Set loading state
        
        do {
            guard let url = URL(string: "https://www.gutenberg.org/cache/epub/feeds/today.rss") else {
                throw FeedServiceError.invalidURL
            }
            print("Starting network fetch for \(url.absoluteString)...")
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FeedServiceError.networkError(NSError(domain: "HTTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))
            }
            
            if httpResponse.statusCode != 200 {
                let status = httpResponse.statusCode
                throw FeedServiceError.networkError(NSError(domain: "HTTP", code: status, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response status"]))
            }
            
            print("Network response successful (Status: 200). Data size: \(data.count) bytes.")
            
            let parsedBooks = try await parseXMLData(data)
            
            // 2. Create Today's Collection and Upsert Books
            let today = Calendar.current.startOfDay(for: Date()) // Use startOfDay for consistent dating
            
            // Fetch or create the daily collection for today
            let collectionDescriptor = FetchDescriptor<DailyCollection>(
                predicate: #Predicate { $0.date == today }
            )
            
            let dailyCollection: DailyCollection
            if let existing = try modelContext.fetch(collectionDescriptor).first {
                dailyCollection = existing
            } else {
                dailyCollection = DailyCollection(date: today)
                modelContext.insert(dailyCollection)
            }
            
            // 3. Upsert Books
            for book in parsedBooks {
                let bookIDToMatch = book.id
                let descriptor = FetchDescriptor<Book>(predicate: #Predicate { $0.id == bookIDToMatch })
                
                if let existingBook = try? modelContext.fetch(descriptor).first {
                    // Link existing book, but only if not already linked
                    if !dailyCollection.books.contains(where: { $0.id == existingBook.id }) {
                        dailyCollection.books.append(existingBook)
                    }
                } else {
                    modelContext.insert(book)
                    dailyCollection.books.append(book)
                }
            }
            
            try modelContext.save()
            print("Persistence successful. Stored \(parsedBooks.count) eBooks for today.")
            
        } catch let parsingError as FeedServiceError {
            self.error = parsingError
            print("Fetch failed with parsing error: \(parsingError.localizedDescription)")
        } catch {
            // Catch SwiftData persistence errors or general network errors
            self.error = .networkError(error)
            print("Fetch failed with error: \(error.localizedDescription)")
        }
        
        self.isLoading = false
        print("Fetch complete.")
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
