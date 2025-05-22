import SwiftUI
import SwiftData

@MainActor
final class DataController: ObservableObject {
    /// 持有 SwiftData 容器
    let container: ModelContainer

    /// 暴露给 UI 的数据
    @Published private(set) var categories:   [Category]    = []
    @Published private(set) var projects:     [Project]     = []
    @Published private(set) var transactions: [Transaction] = []

    init() {
        // 1. 建立 container（variadic 參數，非陣列）
        container = try! ModelContainer(
            for: Category.self,
                 Subcategory.self,
                 Project.self,
                 Transaction.self
        )

        // 2. 種子初始化：首次啟動時塞入預設資料
        seedDefaultDataIfNeeded()

        // 3. 把所有資料 load 到 Published 屬性
        fetchAll()
    }

    // MARK: - Seed 預設資料
    private func seedDefaultDataIfNeeded() {
        // 先用簡單的 FetchDescriptor 檢查是否已有 Category 或 Project
        let catCount = (try? container.mainContext.fetch(
            FetchDescriptor<Category>()
        ).count) ?? 0
        let projCount = (try? container.mainContext.fetch(
            FetchDescriptor<Project>()
        ).count) ?? 0

        // 若都還沒資料，就插入預設
        guard catCount == 0, projCount == 0 else {
            return
        }

        // 建立預設大類 + 小類
        let food = Category(
            name: "食品酒水",
            order: 0,
            subcategories: [
                Subcategory(name: "早餐", order: 0),
                Subcategory(name: "午餐", order: 1),
                Subcategory(name: "晚餐", order: 2),
                Subcategory(name: "點心", order: 3),
            ]
        )
        let transport = Category(
            name: "交通出行",
            order: 1,
            subcategories: [
                Subcategory(name: "公車", order: 0),
                Subcategory(name: "捷運", order: 1),
                Subcategory(name: "計程車", order: 2),
            ]
        )

        // 建立預設專案
        let projA = Project(name: "專案 A", order: 0)
        let projB = Project(name: "專案 B", order: 1)

        // 插入到 context → SwiftData 會自動儲存到底層
        let ctx = container.mainContext
        ctx.insert(food)
        ctx.insert(transport)
        ctx.insert(projA)
        ctx.insert(projB)
    }

    /// 从数据库读取最新数据
    func fetchAll() {
        do {
            let catDesc = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.order)])
            let projDesc = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.order)])
            let txDesc = FetchDescriptor<Transaction>(
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )

            categories   = try container.mainContext.fetch(catDesc)
            projects     = try container.mainContext.fetch(projDesc)
            transactions = try container.mainContext.fetch(txDesc)
        } catch {
            print("⚠️ DataController.fetchAll error:", error)
        }
    }

    // MARK: — CRUD for Category
    func addCategory(name: String) {
        let nextOrder = (categories.map(\.order).max() ?? -1) + 1
        let cat = Category(name: name, order: nextOrder)
        container.mainContext.insert(cat)
        fetchAll()
    }

    func deleteCategory(_ cat: Category) {
        container.mainContext.delete(cat)
        fetchAll()
    }
    
    func addSubcategory(to category: Category, name: String) {
        let nextOrder = (category.subcategories.map(\.order).max() ?? -1) + 1
        let sub = Subcategory(name: name, order: nextOrder)
        // 把它 append 到關聯裡，並 insert
        category.subcategories.append(sub)
        container.mainContext.insert(sub)
        fetchAll()
    }

    // MARK: — CRUD for Project
    func addProject(name: String) {
        let nextOrder = (projects.map(\.order).max() ?? -1) + 1
        let proj = Project(name: name, order: nextOrder)
        container.mainContext.insert(proj)
        fetchAll()
    }

    func deleteProject(_ proj: Project) {
        container.mainContext.delete(proj)
        fetchAll()
    }

    // MARK: — CRUD for Transaction
    func addTransaction(
        category: Category,
        subcategory: Subcategory,
        amount: Int,
        date: Date,
        note: String?,
        project: Project?
    ) {
        let tx = Transaction(
            category:    category,
            subcategory: subcategory,
            amount:      amount,
            date:        date,
            note:        note,
            project:     project
        )
        container.mainContext.insert(tx)
        fetchAll()
    }

    func deleteTransaction(_ tx: Transaction) {
        container.mainContext.delete(tx)
        fetchAll()
    }
}
