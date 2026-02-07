//
//  GutenbergReaderApp.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/04.
//

import SwiftUI
import SwiftData

@main
struct GutenbergReaderApp: App {
    // Initialize the SwiftData container with our schema
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Book.self,
            DailyCollection.self,
        ])
        // isStoredInMemoryOnly: false ensures data persists between app launches
        print("data persists between app launches")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            DailyFeedView()
        }
        .modelContainer(sharedModelContainer) // Inject database into the view hierarchy
    }
}
