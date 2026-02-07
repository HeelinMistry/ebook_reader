//
//  DataController.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/06.
//

import SwiftData
import SwiftUI

@MainActor
class DataController {
    static let shared = DataController()
    
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Book.self,
            DailyCollection.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // Useful for SwiftUI Previews
    static var previewContainer: ModelContainer = {
        let schema = Schema([Book.self, DailyCollection.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        // Insert dummy data here if needed...
        return container
    }()
}
