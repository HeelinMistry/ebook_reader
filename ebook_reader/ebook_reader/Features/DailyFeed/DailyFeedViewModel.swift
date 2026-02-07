//
//  DailyFeedViewModel.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/06.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class DailyFeedViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let feedService: FeedService
    private var cancellables = Set<AnyCancellable>()
    
    // Designated initializer: Inject FeedService as a dependency
    init(feedService: FeedService) {
        self.feedService = feedService
        
        // Observe FeedService's published properties to update own UI state
        feedService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        feedService.$error
            .map { $0?.localizedDescription }
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    // Convenience initializer for default FeedService instantiation
    convenience init() {
        // Since DailyFeedViewModel is @MainActor, this convenience initializer
        // is also @MainActor-isolated, allowing FeedService() to be called.
        self.init(feedService: FeedService())
    }
    
    /// Triggers the feed fetching and persistence process via the FeedService.
    /// - Parameter modelContext: The ModelContext to be used by the FeedService for persistence.
    func fetchDailyFeed(modelContext: ModelContext) async {
        await feedService.refreshDailyFeed(modelContext: modelContext)
    }
}

