//
//  DailyCollection.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/06.
//

import Foundation
import SwiftData

@Model
final public class DailyCollection {
    @Attribute(.unique) var date: Date // e.g., 2026-02-06
    var books: [Book] = [] // Relationship to the Book model
    
    init(date: Date) {
        self.date = date
    }
}
