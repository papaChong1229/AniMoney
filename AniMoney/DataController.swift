import SwiftUI
import SwiftData

@MainActor
final class DataController: ObservableObject {
    let container: ModelContainer

    @Published private(set) var categories:   [Category]    = []
    @Published private(set) var projects:     [Project]     = []
    @Published private(set) var transactions: [Transaction] = []

    init() throws {
        // 確保所有 Model 都已註冊
        container = try ModelContainer(
            for: Category.self, Subcategory.self, Project.self, Transaction.self
        )
        seedDefaultDataIfNeeded()
        fetchAll()
    }

    private func seedDefaultDataIfNeeded() {
        let ctx = container.mainContext
        guard ((try? ctx.fetch(FetchDescriptor<Category>()).count) ?? 0) == 0,
              ((try? ctx.fetch(FetchDescriptor<Project>()).count) ?? 0) == 0 else { return }

        // --- Seed Data ---
        // 創建 Subcategories
        let breakfast = Subcategory(name: "早餐", order: 0)
        let lunch = Subcategory(name: "午餐", order: 1)
        let dinner = Subcategory(name: "晚餐", order: 2)
        let snack = Subcategory(name: "點心", order: 3)

        // 創建 Category 並關聯 Subcategories
        let food = Category(name: "食品酒水", order: 0, subcategories: [breakfast, lunch, dinner, snack])

        let bus = Subcategory(name: "公車", order: 0)
        let mrt = Subcategory(name: "捷運", order: 1)
        let taxi = Subcategory(name: "計程車", order: 2)
        let transport = Category(name: "交通出行", order: 1, subcategories: [bus, mrt, taxi])
        
        let projA = Project(name: "專案 A", order: 0)
        let projB = Project(name: "專案 B", order: 1)
        // --- End Seed Data ---

        // 插入到 Context
        // 因為 Category 的 subcategories 關係是 .cascade，插入 Category 時，其包含的 Subcategory 也會被插入
        ctx.insert(food)
        ctx.insert(transport)
        ctx.insert(projA)
        ctx.insert(projB)
        
        do {
            try ctx.save()
            print("🌱 Default data seeded and context saved.")
        } catch {
            print("❌ DataController.seedDefaultDataIfNeeded: Failed to save context after seeding: \(error)")
        }
    }

    func fetchAll() {
        do {
            // Fetch Categories with their subcategories pre-fetched if needed (though usually automatic)
            var catDesc  = FetchDescriptor<Category>(sortBy: [SortDescriptor(\Category.order)])
            // catDesc.relationshipKeyPathsForPrefetching = [\.subcategories] // Optional: explicitly prefetch

            let projDesc = FetchDescriptor<Project>(sortBy: [SortDescriptor(\Project.order)])
            let txDesc   = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\Transaction.date, order: .reverse)])

            categories   = try container.mainContext.fetch(catDesc)
            projects     = try container.mainContext.fetch(projDesc)
            transactions = try container.mainContext.fetch(txDesc)
            print("🔁 Data fetched. Categories: \(categories.count), Projects: \(projects.count), Transactions: \(transactions.count)")
        } catch {
            print("⚠️ DataController.fetchAll error: \(error)")
        }
    }

    private func saveContext() -> Bool {
        // Check for unsaved changes before attempting to save
        if container.mainContext.hasChanges {
            do {
                try container.mainContext.save()
                print("✅ Context saved successfully.")
                return true
            } catch {
                print("❌ DataController: Failed to save context: \(error)")
                // container.mainContext.rollback() // Consider if appropriate for your error handling strategy
                return false
            }
        } else {
            print("ℹ️ Context has no changes to save.")
            return true // No changes, so "saving" is trivially successful
        }
    }

    // MARK: - Category CRUD & Reassignment
    func addCategory(name: String) {
        let nextOrder = (categories.map(\.order).max() ?? -1) + 1
        let cat = Category(name: name, order: nextOrder) // Subcategories is empty by default
        container.mainContext.insert(cat)
        if saveContext() {
            fetchAll()
        }
    }

    func reassignTransactions(from oldCat: Category, to newCat: Category) -> Bool {
        let oldCatID = oldCat.id
        let txDesc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.category.id == oldCatID })
        
        do {
            let relatedTransactions = try container.mainContext.fetch(txDesc)
            if relatedTransactions.isEmpty {
                return saveContext() // No transactions, "success"
            }

            // IMPORTANT: Since Subcategory doesn't have a direct backlink to Category in your model,
            // we assume newCat.subcategories are correctly managed and fetched.
            guard let firstSubcategoryOfNewCat = newCat.subcategories.sorted(by: { $0.order < $1.order }).first else {
                print("❌ Error: Target category '\(newCat.name)' has no subcategories. Transactions cannot be reassigned without a subcategory.")
                return false
            }

            for tx in relatedTransactions {
                tx.category = newCat // Reassign category
                tx.subcategory = firstSubcategoryOfNewCat // Reassign to the first subcategory of the new category
            }
            
            if saveContext() {
                print("✅ Transactions reassigned from '\(oldCat.name)' to '\(newCat.name)'.")
                // fetchAll() might be called by subsequent delete or view update
                return true
            }
            return false
        } catch {
            print("❌ Error fetching/reassigning transactions for category: \(error)")
            return false
        }
    }

    // Deletes category and its subcategories (due to .cascade) AND related transactions
    func deleteCategoryWithCascade(_ category: Category) {
        let categoryID = category.id
        // First, delete transactions related to this category
        let txDesc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.category.id == categoryID })
        do {
            let relatedTransactions = try container.mainContext.fetch(txDesc)
            for tx in relatedTransactions {
                container.mainContext.delete(tx)
            }
        } catch {
            print("❌ Error fetching/deleting transactions for cascade delete of category '\(category.name)': \(error)")
            // Decide if you want to proceed with category deletion if transactions fail
        }
        
        // Then delete the category itself. Its subcategories will be deleted due to the .cascade rule.
        container.mainContext.delete(category)
        
        if saveContext() {
            fetchAll()
        }
    }
    
    // Deletes category and its subcategories (due to .cascade).
    // Assumes transactions are handled separately (e.g., reassigned).
    func deleteCategory(_ category: Category) {
        container.mainContext.delete(category) // Subcategories deleted by .cascade
        if saveContext() {
            fetchAll()
        }
    }

    // MARK: - Subcategory CRUD & Reassignment
    func addSubcategory(to category: Category, name: String) {
        // Find the managed instance of the category
        guard let managedCategory = categories.first(where: { $0.id == category.id }) ?? container.mainContext.model(for: category.persistentModelID) as? Category else {
            print("❌ Error: Category not found for adding subcategory.")
            return
        }
        
        let nextOrder = (managedCategory.subcategories.map(\.order).max() ?? -1) + 1
        let newSub = Subcategory(name: name, order: nextOrder)
        // SwiftData automatically handles inserting `newSub` when it's added to a managed `Category`'s relationship collection.
        // No need to explicitly insert `newSub` if it's added to `managedCategory.subcategories` *before* save.
        managedCategory.subcategories.append(newSub)
        
        if saveContext() {
            fetchAll() // Re-fetch to update UI, including the category's subcategories list
        }
    }

    func reassignTransactions(from oldSub: Subcategory, to newSub: Subcategory) -> Bool {
        let oldSubID = oldSub.id
        let txDesc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.subcategory.id == oldSubID })
        do {
            let relatedTransactions = try container.mainContext.fetch(txDesc)
            if relatedTransactions.isEmpty { return saveContext() } // No transactions, "success"
            
            for tx in relatedTransactions {
                tx.subcategory = newSub
            }
            if saveContext() {
                print("✅ Transactions reassigned for subcategory.")
                return true
            }
            return false
        } catch {
            print("❌ Error reassigning transactions for subcategory: \(error)")
            return false
        }
    }
    
    // Deletes a specific subcategory AND its related transactions.
    // Also removes it from its parent category's list.
    func deleteSubcategoryAndRelatedTransactions(from category: Category, subcategoryToDelete: Subcategory) {
        let subcategoryID = subcategoryToDelete.id
        // Delete related transactions
        let txDesc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.subcategory.id == subcategoryID })
        do {
            let relatedTransactions = try container.mainContext.fetch(txDesc)
            for tx in relatedTransactions {
                container.mainContext.delete(tx)
            }
        } catch {
            print("❌ Error fetching/deleting transactions for subcategory: \(error)")
        }

        // Remove subcategory from parent category's list and delete the subcategory instance
        if let managedCategory = categories.first(where: { $0.id == category.id }) ?? container.mainContext.model(for: category.persistentModelID) as? Category {
            managedCategory.subcategories.removeAll { $0.id == subcategoryID }
            // Deleting the subcategory instance itself.
            // If it was only referenced by this category, SwiftData's cascade from Category to Subcategory
            // would also handle it if the *Category* was deleted, but here we are deleting a specific Subcategory.
            // If `Subcategory` instances are unique and not shared, this is fine.
            // The `.cascade` on `Category.subcategories` means if the `Category` is deleted, `Subcategory` is deleted.
            // It does *not* mean if a `Subcategory` is removed from the array, it's automatically deleted from the store.
            // So, we need to explicitly delete it.
            if let subToDeleteInContext = container.mainContext.model(for: subcategoryToDelete.persistentModelID) as? Subcategory {
                 container.mainContext.delete(subToDeleteInContext)
            } else {
                // If it's already been deleted or not found, we can just ensure it's removed from the array.
                 print("ℹ️ Subcategory to delete not found in context, might have been already processed.")
            }
        } else {
            print("❌ Parent category not found for deleting subcategory.")
        }
        
        if saveContext() {
            fetchAll()
        }
    }
    
    // Deletes a subcategory. Assumes transactions are handled.
    // Removes it from its parent category's list.
    func deleteSubcategory(_ subcategoryToDelete: Subcategory, from category: Category) {
         if let managedCategory = categories.first(where: { $0.id == category.id }) ?? container.mainContext.model(for: category.persistentModelID) as? Category {
            managedCategory.subcategories.removeAll { $0.id == subcategoryToDelete.id }
             if let subToDeleteInContext = container.mainContext.model(for: subcategoryToDelete.persistentModelID) as? Subcategory {
                 container.mainContext.delete(subToDeleteInContext)
             }
        }
        if saveContext() {
            fetchAll()
        }
    }


    // MARK: - Project CRUD (similar logic for saveContext and fetchAll)
    func addProject(name: String) {
        let nextOrder = (projects.map(\.order).max() ?? -1) + 1
        let proj = Project(name: name, order: nextOrder)
        container.mainContext.insert(proj)
        if saveContext() { fetchAll() }
    }

    func reassignTransactions(from oldProj: Project, to newProj: Project) -> Bool {
        let oldProjID = oldProj.id
        let txDesc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.project?.id == oldProjID })
        do {
            let relatedTransactions = try container.mainContext.fetch(txDesc)
            if relatedTransactions.isEmpty { return saveContext() }
            for tx in relatedTransactions { tx.project = newProj }
            return saveContext()
        } catch { print("❌ Error reassigning transactions for project: \(error)"); return false }
    }

    func deleteProjectAndNilOutTransactions(_ project: Project) {
        let projectID = project.id
        let txDesc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.project?.id == projectID })
        do {
            let relatedTransactions = try container.mainContext.fetch(txDesc)
            for tx in relatedTransactions { tx.project = nil }
        } catch { print("❌ Error niling transactions for project: \(error)") }
        container.mainContext.delete(project)
        if saveContext() { fetchAll() }
    }

    func deleteProjectWithCascade(_ project: Project) { // Deletes project AND its transactions
        let projectID = project.id
        let txDesc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.project?.id == projectID })
        do {
            let relatedTransactions = try container.mainContext.fetch(txDesc)
            for tx in relatedTransactions { container.mainContext.delete(tx) }
        } catch { print("❌ Error deleting transactions for project cascade: \(error)") }
        container.mainContext.delete(project)
        if saveContext() { fetchAll() }
    }
    
    func deleteProject(_ project: Project) { // Deletes project, assumes transactions handled
        container.mainContext.delete(project)
        if saveContext() { fetchAll() }
    }

    // MARK: - Transaction CRUD
    // MARK: - Transaction CRUD
    func addTransaction(
        category: Category,
        subcategory: Subcategory,
        amount: Int,
        date: Date,
        note: String? = nil,
        photoData: Data? = nil, // <--- 在這裡加上 photoData 參數
        project: Project? = nil
    ) {
        // Ensure we are using managed instances for relationships
        guard let managedCategory = categories.first(where: { $0.id == category.id }) ?? container.mainContext.model(for: category.persistentModelID) as? Category else {
            print("❌ AddTransaction Error: Category not managed."); return
        }
        // Crucially, check if the subcategory belongs to THIS managedCategory instance's subcategories array.
        guard let managedSubcategory = managedCategory.subcategories.first(where: { $0.id == subcategory.id }) else {
            print("❌ AddTransaction Error: Subcategory '\(subcategory.name)' does not belong to category '\(managedCategory.name)' or is not managed correctly.")
            if let _ = container.mainContext.model(for: subcategory.persistentModelID) as? Subcategory {
                print("ℹ️ Subcategory exists in context but not in parent's list. This indicates a data integrity issue or incorrect usage.")
            }
            return
        }
        
        var managedProject: Project? = nil
        if let proj = project {
            managedProject = projects.first(where: { $0.id == proj.id }) ?? container.mainContext.model(for: proj.persistentModelID) as? Project
            if managedProject == nil { print("⚠️ AddTransaction Warning: Project not found in managed context, transaction will have nil project."); }
        }

        let tx = Transaction(
            category: managedCategory,
            subcategory: managedSubcategory,
            amount: amount,
            date: date,
            note: note,
            photoData: photoData, // <--- 在這裡傳遞 photoData 給 Transaction 的 init
            project: managedProject
        )
        container.mainContext.insert(tx)
        if saveContext() {
            fetchAll()
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        container.mainContext.delete(transaction)
        if saveContext() {
            fetchAll()
        }
    }
    
    // MARK: - Helper Predicates (No change needed here from previous version)
    func hasTransactions(category: Category) -> Bool {
        let categoryID = category.id
        let desc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.category.id == categoryID })
        let count = (try? container.mainContext.fetchCount(desc)) ?? 0
        return count > 0
    }

    func hasTransactions(subcategory: Subcategory) -> Bool {
        let subcategoryID = subcategory.id
        let desc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.subcategory.id == subcategoryID })
        let count = (try? container.mainContext.fetchCount(desc)) ?? 0
        return count > 0
    }
    
    func hasTransactions(project: Project) -> Bool {
        let projectID = project.id
        let desc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.project?.id == projectID })
        let count = (try? container.mainContext.fetchCount(desc)) ?? 0
        return count > 0
    }
    
    func clearProjectFromTransactions(of projectToClear: Project) -> Bool {
        let projectID = projectToClear.id
        let txDesc = FetchDescriptor<Transaction>(predicate: #Predicate<Transaction> { $0.project?.id == projectID })
        do {
            let relatedTransactions = try container.mainContext.fetch(txDesc)
            if relatedTransactions.isEmpty {
                // No transactions to nil, but we still need to ensure context is saved if there were other pending changes.
                // If saveContext only saves if there are changes, this is fine.
                // Or, we can consider this a success if there's nothing to do.
                return true // Or return saveContext() if you want to ensure any other pending changes are saved
            }
            for tx in relatedTransactions {
                tx.project = nil
            }
            return saveContext() // Save changes (nilling out projects)
        } catch {
            print("❌ DataController: Error clearing project from transactions for project '\(projectToClear.name)': \(error)")
            return false
        }
    }
}
