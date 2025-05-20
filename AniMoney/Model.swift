//
//  Model.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/21.
//

import Foundation

/// 小類別
struct Subcategory: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var name: String
}

/// 大類別
struct Category: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var name: String
    /// 底下包含的小類
    var subcategories: [Subcategory]
}

struct Project: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var name: String
}

struct Transaction {
    /// 所屬大類、小類
    var category: Category
    var subcategory: Subcategory
    
    /// 金額，使用 Decimal 避免浮點誤差
    var amount: Int
    
    /// 交易日期
    var date: Date
    
    /// 備註或說明（可為空）
    var note: String?
    
    /// 照片清單（存 URL 或本地檔案路徑；可為空）
    var photoURLs: [URL]?
    
    /// 可選專案
    var project: Project?
}
