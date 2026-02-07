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
    var body: some Scene {
        WindowGroup {
            DailyFeedView()
        }
        .modelContainer(DataController.shared.container)
    }
}
