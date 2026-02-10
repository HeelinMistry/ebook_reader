//
//  Ebook.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/04.
//

import Foundation
import SwiftData
import SwiftUI // Import SwiftUI for potential Image-related helpers, though not strictly needed here for @Model

@Model
final public class Book: Identifiable, Equatable {
    
    // Properties must be mutable for SwiftData, and public access is needed for model initialization/usage
    @Attribute(.unique) public var id: String // Ensures uniqueness based on the Gutenberg ID
    @Attribute public var lastReadLocation: Double = 0.0 // 0.0 to 1.0
    @Attribute public var title: String // Changed access from private to public for predicate access
    private var link: URL
    public var explicitAuthor: String?
    public var descriptionLanguage: String? // Renamed description to ebookDescription to avoid potential namespace conflicts.
    
    // Offline Logic for Book Content
    public var localFileName: String? // Stores only the filename for the main book content
    
    // Computed property to get the full local URL dynamically for the main book content.
    public var actualLocalFileURL: URL? {
        guard let fileName = localFileName else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }
    
    // `isDownloaded` checks the existence of the file at the `actualLocalFileURL`.
    public var isDownloaded: Bool {
        guard let fileURL = actualLocalFileURL else {
            return false
        }
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false))
        return fileExists
    }
    
    // Offline Logic for Cover Image
    // Stores only the filename for the downloaded cover image
    public var localCoverFileName: String?
    
    // Computed property to get the full local URL dynamically for the cover image.
    public var actualLocalCoverURL: URL? {
        guard let fileName = localCoverFileName else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // Store covers in a subdirectory for organization
        return docs.appendingPathComponent("covers").appendingPathComponent(fileName)
    }
    
    // Relationships
    @Relationship(inverse: \DailyCollection.books) var dailyFeatures: [DailyCollection]?
    
    public var displayTitle: String {
        let cleanedTitle = title.replacingOccurrences(of: ":", with: "", range: nil)
        return cleanedTitle.components(separatedBy: " by ").first ?? cleanedTitle
    }
    
    public var author: String {
        if let explicit = explicitAuthor {
            return explicit
        }
        // Fallback to your old parsing logic for older records
        let parts = title.components(separatedBy: " : by ")
        if parts.count > 1 { return parts.last ?? "" }
        let otherParts = title.components(separatedBy: " by ")
        return otherParts.count > 1 ? (otherParts.last ?? "") : "Unknown Author"
    }
    
    public var language: String {
        // Uses the new internal property name
        guard let description = descriptionLanguage else { return "Unknown" }
        // Splits "Language: German" into ["Language", "German"]
        let components = description.components(separatedBy: ": ")
        return components.count > 1 ? components[1].trimmingCharacters(in: .whitespaces) : "Unknown"
    }
    
    // Helper for a cleaner UI (Optional: Add Emoji flags)
    public var languageTag: String {
        switch language.lowercased() {
        case "english":   return "🇺🇸 EN"
        case "spanish":   return "🇪🇸 ES"
        case "german":    return "🇩🇪 DE"
        case "french":    return "🇫🇷 FR"
        case "hungarian": return "🇭🇺 HU"
        case "finnish":   return "🇫🇮 FI"
        case "italian":   return "🇮🇹 IT"
        case "portuguese": return "🇵🇹 PT"
        case "dutch": return "🇳🇱 NL"
        case "catalan": return "🇦🇩 CA"
        default: return "🌐 \(language)"
        }
    }
    
    // MARK: - Initializers
    
    // MODIFIED: Designated Initializer now accepts 'id' directly.
    public init(id: String, title: String, link: URL, description: String?) {
        self.id = id // Use the provided ID
        self.title = title
        self.link = link
        self.descriptionLanguage = description
        self.localFileName = nil
        self.localCoverFileName = nil // Initialize new property
    }
    
    // Equatable conformance for @Model classes
    public static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Book {
    // This is the remote URL for the cover image
    var coverURL: URL? {
        URL(string: "https://www.gutenberg.org/cache/epub/\(id)/pg\(id).cover.medium.jpg")
    }
    
    // Gutenberg HTML URLs are usually: /ebooks/{id}.html.images or /cache/epub/{id}/pg{id}-images.html
    var remoteHTMLURL: URL? {
        URL(string: "https://www.gutenberg.org/ebooks/\(id).html.images")
    }
    
    var remoteEPUBURL: URL? {
        URL(string: "https://www.gutenberg.org/ebooks/\(id).epub3.images")
    }
    
    // These remain as helpers to determine the *expected* filename for HTML
    var localHTMLURL: URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("\(id).html")
    }
    
    // These remain as helpers to determine the *expected* filename for EPUB
    var localEPUBURL: URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("\(id).epub3")
    }
    
    // NEW: Convenience initializer for catalog CSV rows
    convenience init(catalogRow: [String]) throws {
        // Safety check for column count, must be at least 6 based on Gutenberg CSV format
        guard catalogRow.count >= 6 else {
            throw CatalogService.CatalogError.parsingFailed // Not enough columns to create a Book
        }
        
        let id = catalogRow[0].replacingOccurrences(of: "\"", with: "")
        let type = catalogRow[1].replacingOccurrences(of: "\"", with: "")
        let titleFromCSV = catalogRow[3].replacingOccurrences(of: "\"", with: "")
        let languageFromCSV = catalogRow[4].replacingOccurrences(of: "\"", with: "")
        let authorsFromCSV = catalogRow[5].replacingOccurrences(of: "\"", with: "")
        
        // As per CatalogService, filter for English "Text" books.
        guard type == "Text" && languageFromCSV.lowercased() == "en" else {
            // Throw an error if the book doesn't meet the filtering criteria.
            // `parsingFailed` can indicate that a valid Book *could not be parsed* from this row
            // given the desired filtering.
            throw CatalogService.CatalogError.bookCreationFailed("Row does not meet 'Text' and 'en' language criteria.")
        }
        
        // Construct the internal 'title' string to be compatible with existing computed properties
        // (displayTitle and author) which parse "Title by Author" or "Title : by Author" patterns.
        let combinedTitleForBookModel: String
        if authorsFromCSV.isEmpty || authorsFromCSV.lowercased() == "unknown" {
            combinedTitleForBookModel = titleFromCSV
        } else {
            combinedTitleForBookModel = "\(titleFromCSV) by \(authorsFromCSV)"
        }
        
        // Construct a standard Gutenberg URL for the book using its ID.
        guard let link = URL(string: "https://www.gutenberg.org/ebooks/\(id)") else {
            throw CatalogService.CatalogError.parsingFailed // Failed to construct URL from ID
        }
        
        // Format language for `descriptionLanguage` property (e.g., "Language: English")
        let fullLanguageName = Locale.current.localizedString(forLanguageCode: languageFromCSV) ?? languageFromCSV
        
        // 2. Format it
        let descriptionLanguage = "Language: \(fullLanguageName.capitalized)"
        // Call the new designated initializer with the processed data.
        self.init(id: id, title: combinedTitleForBookModel, link: link, description: descriptionLanguage)
        self.explicitAuthor = authorsFromCSV
    }
    
    /// Updates the properties of an existing Book instance from a catalog CSV row.
    /// This is used during an upsert operation to refresh book details from the catalog.
    /// - Parameter catalogRow: An array of strings representing a row from the catalog CSV.
    /// - Throws: `CatalogService.CatalogError` if the row is malformed or if the book no longer
    ///           meets the filtering criteria (e.g., not "Text" or "en" language).
    func update(from catalogRow: [String]) throws {
        // Safety check for column count, must be at least 6 based on Gutenberg CSV format
        guard catalogRow.count >= 6 else {
            throw CatalogService.CatalogError.parsingFailed // Not enough columns to update Book
        }

        let type = catalogRow[1].replacingOccurrences(of: "\"", with: "")
        let titleFromCSV = catalogRow[3].replacingOccurrences(of: "\"", with: "")
        let languageFromCSV = catalogRow[4].replacingOccurrences(of: "\"", with: "")
        let authorsFromCSV = catalogRow[5].replacingOccurrences(of: "\"", with: "")

        // Maintain consistency with the original filtering logic.
        guard type == "Text" && languageFromCSV.lowercased() == "en" else {
            // If the updated row no longer meets criteria, we might decide to
            // skip the update. Throwing `bookCreationFailed` signals this.
            throw CatalogService.CatalogError.bookCreationFailed("Updated row no longer meets 'Text' and 'en' language criteria for book ID \(self.id).")
        }

        // Construct the internal 'title' string
        let combinedTitleForBookModel: String
        if authorsFromCSV.isEmpty || authorsFromCSV.lowercased() == "unknown" {
            combinedTitleForBookModel = titleFromCSV
        } else {
            combinedTitleForBookModel = "\(titleFromCSV) by \(authorsFromCSV)"
        }

        // Construct a standard Gutenberg URL for the book using its ID.
        guard let newLink = URL(string: "https://www.gutenberg.org/ebooks/\(self.id)") else {
            throw CatalogService.CatalogError.parsingFailed // Failed to construct URL from ID
        }

        // Format language for `descriptionLanguage` property (e.g., "Language: English")
        let fullLanguageName = Locale.current.localizedString(forLanguageCode: languageFromCSV) ?? languageFromCSV
        let newDescriptionLanguage = "Language: \(fullLanguageName.capitalized)"

        // Update properties
        self.title = combinedTitleForBookModel
        self.link = newLink
        self.descriptionLanguage = newDescriptionLanguage
        self.explicitAuthor = authorsFromCSV
        // Properties like lastReadLocation, localFileName, localCoverFileName, dailyFeatures
        // are not updated as they are user-specific or download-specific, not catalog metadata.
    }
}
