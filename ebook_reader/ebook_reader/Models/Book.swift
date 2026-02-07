//
//  Ebook.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/04.
//

import Foundation
import SwiftData 

@Model
final public class Book: Identifiable, Equatable { // Added Equatable for easier testing/comparison
    
    // Properties must be mutable for SwiftData, and public access is needed for model initialization/usage
    @Attribute(.unique) public var id: String // Ensures uniqueness based on the Gutenberg ID
    private var title: String
    private var link: URL
    public var ebookDescription: String? // Renamed description to ebookDescription to avoid potential namespace conflicts.
    
    // Offline Logic
    public var isDownloaded: Bool = false
    public var localFilePath: String?
    
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
        let extractedID = link.lastPathComponent
        if Int(extractedID) != nil {
            self.id = extractedID
        } else {
            self.id = UUID().uuidString
        }
        self.title = title
        self.link = link
        self.ebookDescription = description
    }
    
    // Equatable conformance for @Model classes
    public static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id
    }
}
