//
//  Untitled.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/06.
//

import Foundation

class RSSFeedParserDelegate: NSObject, XMLParserDelegate {
    typealias Continuation = CheckedContinuation<[Book], Error>
    
    private var continuation: Continuation?
    private var eBooks: [Book] = []
    
    // State for tracking current element
    private var currentElement = ""
    private var currentTitle: String = ""
    private var currentLink: String = ""
    private var currentDescription: String = ""
    private var currentPubDate: String = ""
    
    // Flag to ensure we are inside an <item> element
    private var parsingItem = false
    
    init(continuation: Continuation) {
        self.continuation = continuation
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" {
            parsingItem = true
            // Reset temporary variables for a new item
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = "" // Reset for consistency
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard parsingItem else { return }
        
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            currentLink += string
        case "description":
            currentDescription += string
        // If you ever need to use pubDate for the Book model, you'd handle it here:
        // case "pubDate":
        //    currentPubDate += string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" && parsingItem {
            // Finished parsing an item, create EBook and add to array
            parsingItem = false
            
            // Clean up link, title, and description
            let finalTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalLink = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalDescription = currentDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Attempt to create URL
            guard let linkURL = URL(string: finalLink) else {
                print("Warning (Parser): Failed to create valid URL for item: \(finalTitle)")
                // Optionally, resume with an error or continue to skip this item silently
                // For now, we'll just skip it.
                return
            }
            
            // Extract the book ID from the link.
            // Example: For "https://www.gutenberg.org/ebooks/12345", lastPathComponent is "12345".
            let derivedId = Int(linkURL.lastPathComponent)?.description ?? UUID().uuidString
            
            // Instantiate Book using the new designated initializer
            let book = Book(
                id: derivedId, // Pass the derived ID
                title: finalTitle,
                link: linkURL,
                description: finalDescription
            )
            
            eBooks.append(book)
            
            // Reset currentElement state for next characters or elements
            currentElement = ""
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        print("XML Parse successful. Resuming continuation.")
        continuation?.resume(returning: eBooks)
        continuation = nil // Release continuation
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        let errorDescription = parseError.localizedDescription
        print("Fatal XML Parse error occurred: \(errorDescription)")
        continuation?.resume(throwing: FeedServiceError.parsingError(errorDescription))
        continuation = nil // Release continuation
    }
}
