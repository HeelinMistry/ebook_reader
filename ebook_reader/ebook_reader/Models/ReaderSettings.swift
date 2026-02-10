//
//  ReaderSettings.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/09.
//

import SwiftUI
import Observation

enum ReaderTheme: String, CaseIterable {
    case light = "white"
    case sepia = "#f4ecd8"
    case dark = "#1a1a1a"
    
    var textColor: String {
        self == .dark ? "#f5f5f5" : "#2c2c2c"
    }
}

@Observable // The magic macro
class ReaderPreferences {
    // We manually sync with UserDefaults since @AppStorage doesn't work here
    var fontSize: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "readerFontSize")
            return val == 0 ? 18 : val // Default to 18
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "readerFontSize")
        }
    }
    
    var theme: ReaderTheme {
        get {
            let raw = UserDefaults.standard.string(forKey: "readerTheme") ?? "sepia"
            return ReaderTheme(rawValue: raw) ?? .sepia
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "readerTheme")
        }
    }
}
