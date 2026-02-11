//
//  ReaderSettingsView.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/11.
//

import SwiftUI

struct ReaderSettingsView: View {
    @Bindable var prefs: ReaderPreferences
    
    var body: some View {
        VStack(spacing: 20) {
            Toggle("Match System Appearance", isOn: $prefs.useSystemTheme)
                .padding(.horizontal)
            
            // Theme Picker (Dimmed if System Sync is on)
            HStack(spacing: 20) {
                ForEach(ReaderTheme.allCases, id: \.self) { theme in
                    themeCircle(for: theme)
                }
            }
            .opacity(prefs.useSystemTheme ? 0.5 : 1.0)
            .disabled(prefs.useSystemTheme)
            
            Divider()
            
            // Font Size Controls
            fontSizeControls
                .disabled(prefs.useSystemTheme)
        }
        .padding()
    }
    
    private func themeCircle(for theme: ReaderTheme) -> some View {
        Circle()
            .fill(Color(hex: theme.rawValue))
            .frame(width: 50, height: 50)
            .shadow(radius: 2)
            .overlay(
                Circle()
                    .stroke(prefs.theme == theme ? Color.blue : Color.clear, lineWidth: 3)
            )
            .onTapGesture {
                withAnimation(.spring()) {
                    prefs.theme = theme
                }
            }
    }
    
    private var fontSizeControls: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "textformat.size.smaller")
                
                Slider(value: .init(
                    get: { Double(prefs.fontSize) },
                    set: { prefs.fontSize = Int($0) }
                ), in: 12...36, step: 1)
                .tint(.blue)
                
                Image(systemName: "textformat.size.larger")
            }
            
            Text("Font Size: \(prefs.fontSize)px")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

// Helper to handle the hex strings in your Enum
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        // Handle "white" or actual hex
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
