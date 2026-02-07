//
//  Date+Extensions.swift
//  ebook_reader
//
//  Created by Heelin Mistry on 2026/02/06.
//

import Foundation

extension Date {
    var yyyyMMdd: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // POSIX ensures the format doesn't flip based on user's 12/24h settings
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }
}

