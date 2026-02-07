//
//  DownloadService.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/07.
//

import Foundation
import SwiftData
import Combine

@MainActor
class DownloadService: ObservableObject {
    static let shared = DownloadService()
    
    /// Downloads the cover image for a given book and updates the book's `localCoverFileName` property.
    /// - Parameters:
    ///   - book: The Book model instance to download the cover for.
    ///   - modelContext: The ModelContext to use for saving changes to the book.
    public func downloadCover(for book: Book, using modelContext: ModelContext) async {
        // If we already have a local filename and the file exists, no need to re-download.
        if let existingLocalPath = book.actualLocalCoverURL?.path(percentEncoded: false),
           FileManager.default.fileExists(atPath: existingLocalPath) {
            // print("Cover already exists locally for book \(book.id). Path: \(existingLocalPath)") // Debugging
            return
        }
        
        guard let remoteCoverURL = book.coverURL else {
            print("No remote cover URL for book \(book.id)")
            return
        }
        
        // Define a consistent local filename for the cover
        let coverFileName = "cover_\(book.id).jpg"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let coversDirectory = docs.appendingPathComponent("covers")
        let localTargetURL = coversDirectory.appendingPathComponent(coverFileName)
        
        do {
            // Ensure the 'covers' subdirectory exists
            if !FileManager.default.fileExists(atPath: coversDirectory.path(percentEncoded: false)) {
                try FileManager.default.createDirectory(at: coversDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            print("Downloading cover for book \(book.id) from \(remoteCoverURL)...")
            let (tempURL, _) = try await URLSession.shared.download(from: remoteCoverURL)
            
            // Remove any existing file at the target path before moving the new one
            if FileManager.default.fileExists(atPath: localTargetURL.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: localTargetURL)
            }
            
            // Move the downloaded temporary file to its permanent local location
            try FileManager.default.moveItem(at: tempURL, to: localTargetURL)
            
            // Update the stored `localCoverFileName` property in SwiftData
            book.localCoverFileName = coverFileName
            try? modelContext.save() // Save the change to the model
            
            print("Cover downloaded and localCoverFileName set for book \(book.id) to \(coverFileName)")
            
        } catch {
            print("Failed to download or save cover for book \(book.id): \(error.localizedDescription)")
            book.localCoverFileName = nil // Clear the filename on failure
            try? modelContext.save() // Save the change
        }
    }
    
    /// Deletes the local cover image file for a given book.
    /// - Parameters:
    ///   - book: The Book model instance to delete the cover for.
    ///   - modelContext: The ModelContext to use for saving changes to the book.
    public func deleteCover(for book: Book, using modelContext: ModelContext) async {
        guard let fileURL = book.actualLocalCoverURL else {
            print("No local cover to delete for book \(book.id).")
            return
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            book.localCoverFileName = nil // Clear the stored filename
            try? modelContext.save() // Save the change
            print("Cover file deleted and localCoverFileName cleared for book \(book.id)")
        } catch {
            print("Error deleting local cover file for book \(book.id): \(error.localizedDescription)")
        }
    }
    
    
    public func startDownloadHTML(for book: Book, using modelContext: ModelContext) async {
        guard let remoteURL = book.remoteHTMLURL, let localTargetURL = book.localHTMLURL else { return }
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
            
            // Ensure the destination directory exists (Documents directory always exists)
            let destinationDirectory = localTargetURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)

            // Remove existing file if it exists to avoid conflicts
            if FileManager.default.fileExists(atPath: localTargetURL.path(percentEncoded: false)) {
                try? FileManager.default.removeItem(at: localTargetURL)
            }
            
            try FileManager.default.moveItem(at: tempURL, to: localTargetURL)
            
            // *** IMPORTANT: Update the stored `localFileName` property ***
            // Store only the filename, not the full path
            book.localFileName = localTargetURL.lastPathComponent
            
            // SwiftData usually auto-saves changes to @Model objects, but explicit save is safer if not
            try? modelContext.save()
            
            print("HTML Downloaded and localFileName set to: \(book.localFileName ?? "nil") for book ID: \(book.id)")
        } catch {
            print("HTML Download failed: \(error)")
            book.localFileName = nil // Clear file name on failed download
        }
    }
    
    public func startDownloadEPUB(for book: Book, using modelContext: ModelContext) async {
        guard let remoteURL = book.remoteEPUBURL, let localTargetURL = book.localEPUBURL else { return }
        
        do {
            let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)

            let destinationDirectory = localTargetURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)

            if FileManager.default.fileExists(atPath: localTargetURL.path(percentEncoded: false)) {
                try? FileManager.default.removeItem(at: localTargetURL)
            }
            
            try FileManager.default.moveItem(at: tempURL, to: localTargetURL)
            
            // *** IMPORTANT: Update the stored `localFileName` property ***
            book.localFileName = localTargetURL.lastPathComponent
            
            try? modelContext.save()
            
            print("EPUB Downloaded and localFileName set to: \(book.localFileName ?? "nil") for book ID: \(book.id)")
        } catch {
            print("EPUB Download failed: \(error)")
            book.localFileName = nil // Clear file name on failed download
        }
    }
    
    
    // MARK: - Deletion Logic (Example)
    /*
    private func deleteLocalFile() {
        guard let fileURL = book.actualLocalFileURL else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
            book.localFileName = nil // Clear the stored filename
            try? modelContext.save() // Save the change
            print("File deleted and localFileName cleared for book ID: \(book.id)")
        } catch {
            print("Error deleting local file: \(error)")
        }
    }
    */

}
