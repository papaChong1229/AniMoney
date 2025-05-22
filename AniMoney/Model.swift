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
    var photoData: Data?

    @Relationship var project: Project?

    init(
        category: Category,
        subcategory: Subcategory,
        amount: Int,
        date: Date,
        note: String? = nil,
        photoData: Data? = nil,
        project: Project? = nil
    ) {
        self.id = UUID()
        self.category = category
        self.subcategory = subcategory
        self.amount = amount
        self.date = date
        self.note = note
        self.photoData = photoData
        self.project = project
    }
}
