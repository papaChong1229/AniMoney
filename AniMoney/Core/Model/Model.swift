//
//  Model.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/21.
//

import Foundation
import SwiftData

@Model
final class Subcategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var order: Int

    init(name: String, order: Int) {
        // 把 id、name 都放到這裡初始化
        self.id = UUID()
        self.name = name
        self.order = order
    }
}

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var order: Int

    @Relationship(deleteRule: .cascade)
    var subcategories: [Subcategory]

    init(name: String, order: Int, subcategories: [Subcategory] = []) {
        // 同樣在 init 裡設預設
        self.id = UUID()
        self.name = name
        self.subcategories = subcategories
        self.order = order
    }
}

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var name: String
    var order: Int

    init(name: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.order = order
    }
}

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID

    @Relationship var category: Category
    @Relationship var subcategory: Subcategory

    var amount: Int
    var date: Date
    var note: String?
    
    // 改為陣列來儲存多張照片
    var photosData: [Data]? // 改為可選的 Data 陣列

    @Relationship var project: Project?

    init(
        category: Category,
        subcategory: Subcategory,
        amount: Int,
        date: Date,
        note: String? = nil,
        photosData: [Data]? = nil, // 更新參數
        project: Project? = nil
    ) {
        self.id = UUID()
        self.category = category
        self.subcategory = subcategory
        self.amount = amount
        self.date = date
        self.note = note
        self.photosData = photosData
        self.project = project
    }
    
    // 便利屬性：檢查是否有照片
    var hasPhotos: Bool {
        return photosData?.isEmpty == false
    }
    
    // 便利屬性：照片數量
    var photoCount: Int {
        return photosData?.count ?? 0
    }
}

// 週期類型枚舉
enum RecurrenceType: String, Codable, CaseIterable {
    case monthlyDates = "monthlyDates"    // 每月固定日期
    case fixedInterval = "fixedInterval"  // 固定天數間隔
    
    var displayName: String {
        switch self {
        case .monthlyDates: return "每月固定日期"
        case .fixedInterval: return "固定天數間隔"
        }
    }
}

@Model
final class RecurringExpense {
    @Attribute(.unique) var id: UUID
    var name: String                    // 固定開銷名稱
    var amount: Int                     // 金額（台幣）
    var note: String?                   // 備註
    var isActive: Bool                  // 是否啟用
    
    // 週期設定
    var recurrenceType: RecurrenceType  // 週期類型
    var monthlyDates: [Int]             // 每月的哪幾號（1-31）
    var intervalDays: Int               // 間隔天數
    
    // 時間管理
    var nextExecutionDate: Date         // 下次執行日期
    var lastExecutionDate: Date?        // 上次執行日期
    var createdDate: Date               // 建立日期
    
    // 關聯的分類和子分類
    @Relationship var category: Category
    @Relationship var subcategory: Subcategory
    @Relationship var project: Project?  // 可選的專案
    
    init(
        name: String,
        amount: Int,
        category: Category,
        subcategory: Subcategory,
        recurrenceType: RecurrenceType,
        monthlyDates: [Int] = [],
        intervalDays: Int = 30,
        note: String? = nil,
        project: Project? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.category = category
        self.subcategory = subcategory
        self.recurrenceType = recurrenceType
        self.monthlyDates = monthlyDates
        self.intervalDays = intervalDays
        self.note = note
        self.project = project
        self.isActive = true
        self.createdDate = Date()
        self.lastExecutionDate = nil
        
        // 計算下次執行日期
        self.nextExecutionDate = Self.calculateNextExecutionDate(
            type: recurrenceType,
            monthlyDates: monthlyDates,
            intervalDays: intervalDays,
            from: Date()
        )
    }
    
    // MARK: - 計算下次執行日期
    static func calculateNextExecutionDate(
        type: RecurrenceType,
        monthlyDates: [Int],
        intervalDays: Int,
        from date: Date
    ) -> Date {
        let calendar = Calendar.current
        
        switch type {
        case .monthlyDates:
            return calculateNextMonthlyDate(dates: monthlyDates, from: date)
        case .fixedInterval:
            return calendar.date(byAdding: .day, value: intervalDays, to: date) ?? date
        }
    }
    
    private static func calculateNextMonthlyDate(dates: [Int], from date: Date) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let currentDay = calendar.component(.day, from: today)
        
        // 排序日期
        let sortedDates = dates.sorted()
        
        // 找到本月剩餘的日期
        if let nextDateThisMonth = sortedDates.first(where: { $0 > currentDay }) {
            if let nextDate = calendar.date(bySetting: .day, value: nextDateThisMonth, of: today) {
                return nextDate
            }
        }
        
        // 如果本月沒有剩餘日期，找下個月的第一個日期
        if let firstDateNextMonth = sortedDates.first,
           let nextMonth = calendar.date(byAdding: .month, value: 1, to: today) {
            if let nextDate = calendar.date(bySetting: .day, value: firstDateNextMonth, of: nextMonth) {
                return nextDate
            }
        }
        
        // 備用方案：下個月同一天
        return calendar.date(byAdding: .month, value: 1, to: today) ?? today
    }
    
    // MARK: - 更新下次執行日期
    func updateNextExecutionDate() {
        self.nextExecutionDate = Self.calculateNextExecutionDate(
            type: self.recurrenceType,
            monthlyDates: self.monthlyDates,
            intervalDays: self.intervalDays,
            from: Date()
        )
    }
    
    // MARK: - 執行固定開銷（創建交易）
    func execute() -> Transaction {
        let transaction = Transaction(
            category: self.category,
            subcategory: self.subcategory,
            amount: self.amount,
            date: Date(),
            note: self.note.map { "【固定開銷】\($0)" } ?? "【固定開銷】\(self.name)",
            photosData: nil,
            project: self.project
        )
        
        // 更新執行記錄
        self.lastExecutionDate = Date()
        self.updateNextExecutionDate()
        
        return transaction
    }
    
    // MARK: - 檢查是否應該執行
    var shouldExecute: Bool {
        guard isActive else { return false }
        return Date() >= nextExecutionDate
    }
    
    // MARK: - 顯示用的週期描述
    var recurrenceDescription: String {
        switch recurrenceType {
        case .monthlyDates:
            if monthlyDates.isEmpty {
                return "未設定日期"
            } else if monthlyDates.count == 1 {
                return "每月 \(monthlyDates[0]) 號"
            } else {
                let datesString = monthlyDates.sorted().map { "\($0)" }.joined(separator: ", ")
                return "每月 \(datesString) 號"
            }
        case .fixedInterval:
            return "每 \(intervalDays) 天"
        }
    }
    
    // MARK: - 下次執行時間描述
    var nextExecutionDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let calendar = Calendar.current
        if calendar.isDateInToday(nextExecutionDate) {
            return "今天"
        } else if calendar.isDateInTomorrow(nextExecutionDate) {
            return "明天"
        } else {
            return formatter.string(from: nextExecutionDate)
        }
    }
}
