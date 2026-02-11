//
//  ReaderSettings.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/09.
//

import SwiftUI
import Observation // Ensure Observation is imported for @Observable and related features

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
    // Private stored properties that the @Observable macro will track.
    // They are initialized directly from UserDefaults.
    private var _fontSize: Int
    private var _theme: ReaderTheme
    private var _useSystemTheme: Bool
    
    // Initializer to load initial values from UserDefaults when an instance is created.
    init() {
        let savedFontSize = UserDefaults.standard.integer(forKey: "readerFontSize")
        self._fontSize = savedFontSize == 0 ? 18 : savedFontSize // Default to 18
        
        let savedRawTheme = UserDefaults.standard.string(forKey: "readerTheme") ?? "sepia"
        self._theme = ReaderTheme(rawValue: savedRawTheme) ?? .sepia
        
        self._useSystemTheme = UserDefaults.standard.bool(forKey: "useSystemTheme")
    }
    
    // Public computed properties that act as the interface.
    // They get/set the private stored properties and synchronize with UserDefaults.
    var fontSize: Int {
        get { _fontSize }
        set {
            // Only update if the value has actually changed to avoid unnecessary writes/notifications.
            if _fontSize != newValue {
                _fontSize = newValue
                UserDefaults.standard.set(newValue, forKey: "readerFontSize")
            }
        }
    }
    
    var theme: ReaderTheme {
        get { _theme }
        set {
            if _theme != newValue {
                _theme = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: "readerTheme")
            }
        }
    }
    
    var useSystemTheme: Bool {
        get { _useSystemTheme }
        set {
            if _useSystemTheme != newValue {
                _useSystemTheme = newValue
                UserDefaults.standard.set(newValue, forKey: "useSystemTheme")
            }
        }
    }
}
