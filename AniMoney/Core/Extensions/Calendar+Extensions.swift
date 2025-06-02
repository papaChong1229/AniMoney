//
//  Calendar+Extensions.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/6/1.
//

import Foundation

// MARK: - Calendar 擴展
extension Calendar {
    func endOfDay(for date: Date) -> Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return self.date(byAdding: components, to: startOfDay(for: date))
    }
}
