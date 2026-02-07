//
//  CatalogBrowserView.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/07.
//

import SwiftUI

struct CatalogBrowserView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Gutenberg Archive")
                    .font(.largeTitle)
                Text("70,000+ Books")
                    .foregroundStyle(.secondary)
                
                // This is where the Importer UI will go shortly
                ProgressView("Catalog not yet imported", value: 0)
                    .padding()
            }
            .navigationTitle("Full Catalog")
            .searchable(text: .constant(""), prompt: "Search 70k books...")
        }
    }
}
