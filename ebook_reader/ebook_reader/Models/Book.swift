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
final public class Book: Identifiable, Equatable { // Added Equatable for easier testing/comparison

    // Properties must be mutable for SwiftData, and public access is needed for model initialization/usage
    @Attribute(.unique) public var id: String // Ensures uniqueness based on the Gutenberg ID
    private var title: String
    private var link: URL
    public var ebookDescription: String? // Renamed description to ebookDescription to avoid potential namespace conflicts.

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
        let parts = title.components(separatedBy: " : by ")
        if parts.count > 1 { return parts.last ?? "" }
        let otherParts = title.components(separatedBy: " by ")
        return otherParts.count > 1 ? (otherParts.last ?? "") : "Unknown Author"
    }

    public var language: String {
        // Uses the new internal property name
        guard let description = ebookDescription else { return "Unknown" }
        // Splits "Language: German" into ["Language", "German"]
        let components = description.components(separatedBy: ": ")
        return components.count > 1 ? components[1].trimmingCharacters(in: .whitespaces) : "Unknown"
    }

    // Helper for a cleaner UI (Optional: Add Emoji flags)
    public var languageTag: String {
        switch language.lowercased() {
        case "english": return "🇺🇸 EN"
        case "german":  return "🇩🇪 DE"
        case "french":  return "🇫🇷 FR"
        case "hungarian": return "🇭🇺 HU"
        case "finnish": return "🇫🇮 FI"
        default: return "🌐 \(language)"
        }
    }

    // Initializer remains the same externally
    public init(title: String, link: URL, description: String?) {
        self.id = Int(link.lastPathComponent)?.description ?? UUID().uuidString
        self.title = title
        self.link = link
        self.ebookDescription = description
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
}
