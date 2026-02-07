//
//  MainTabView.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/07.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .daily
    
    enum Tab {
        case daily, catalog, bookshelf
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Daily Feed
            DailyFeedView()
                .tabItem {
                    Label("Daily", systemImage: "sparkles")
                }
                .tag(Tab.daily)
            
            // Tab 2: Full Catalog (Where the 70k import will live)
            CatalogBrowserView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.catalog)
            
            // Tab 3: My Bookshelf
            BookshelfView()
                .tabItem {
                    Label("Bookshelf", systemImage: "books.vertical.fill")
                }
                .tag(Tab.bookshelf)
        }
    }
}
