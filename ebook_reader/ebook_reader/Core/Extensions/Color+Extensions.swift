//
//  Color+Extensions.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/11.
//

import SwiftUI


// Helper to handle the hex strings in your Enum
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        if hex.lowercased() == "white" {
            self = .white
        } else {
            let r, g, b: UInt64
            r = (int >> 16) & 0xff
            g = (int >> 8) & 0xff
            b = int & 0xff
            self = Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
        }
    }
}
