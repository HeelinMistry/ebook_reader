//
//  CSVParser.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/07.
//

import Foundation

struct CSVParser {
    static func parse(_ data: String) -> [[String]] {
        var result: [[String]] = []
        var rows = data.components(separatedBy: .newlines)
        
        // Drop the header row if needed (Gutenberg usually has headers)
        if !rows.isEmpty { rows.removeFirst() }
        
        for row in rows where !row.isEmpty {
            result.append(parseRow(row))
        }
        return result
    }
    
    private static func parseRow(_ row: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                columns.append(currentColumn)
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
        }
        columns.append(currentColumn)
        return columns
    }
}
