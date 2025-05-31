// CategoryManagementViews.swift

import SwiftUI
import SwiftData

// MARK: - Main Management View (Top Level Entry Point)
struct MainFinanceManagementView: View {
    @EnvironmentObject var dataController: DataController

    var body: some View {
        NavigationStack {
            CategoryManagerView()
        }
    }
}

struct CategoryManagerView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddCategorySheet = false
    @State private var showingAddProjectSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定義導航欄
            HStack {
                Text("分類管理")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    showingAddCategorySheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            // 主要內容
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 類別管理區域
                    VStack(alignment: .leading, spacing: 16) {
                        // 類別區域標題
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "square.grid.2x2.fill")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                                Text("類別管理")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Text("\(dataController.categories.count) 個類別")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                        
                        // 類別卡片列表
                        ForEach(dataController.categories.sorted { $0.order < $1.order }) { category in
                            CategoryCard(category: category)
                                .environmentObject(dataController)
                                .padding(.horizontal)
                        }
                    }
                    
                    // 分隔線區域
                    VStack(spacing: 12) {
                        HStack {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                            
                            Image(systemName: "circle.fill")
                                .foregroundColor(.secondary.opacity(0.5))
                                .font(.caption2)
                            
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // 專案管理區域
                    VStack(alignment: .leading, spacing: 16) {
                        // 專案區域標題
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.purple)
                                    .font(.title2)
                                Text("專案管理")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Text("\(dataController.projects.count) 個專案")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                        
                        // 專案描述
                        Text("專案讓你追蹤跨類別的相關支出，例如旅行、裝修或特殊活動的花費。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        
                        // 專案網格
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(dataController.projects.sorted { $0.name < $1.name }) { project in
                                ProjectCard(project: project)
                                    .environmentObject(dataController)
                            }
                            
                            // 新增專案按鈕
                            Button {
                                showingAddProjectSheet = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                    
                                    Text("新增專案")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.purple)
                                }
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.purple.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                    .background(Color(.systemBackground).opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingAddCategorySheet) {
            AddCategoryView()
                .environmentObject(dataController)
        }
        .sheet(isPresented: $showingAddProjectSheet) {
            AddProjectView()
                .environmentObject(dataController)
        }
    }
}

// MARK: - 類別卡片
struct CategoryCard: View {
    @EnvironmentObject var dataController: DataController
    @Bindable var category: Category
    
    // 計算類別統計
    private var categoryStats: (transactions: Int, amount: Int) {
        let transactions = dataController.transactions.filter { $0.category.id == category.id }
        return (transactions: transactions.count, amount: transactions.reduce(0) { $0 + $1.amount })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 類別標題和統計
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(category.subcategories.count) 個子類別")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(categoryStats.transactions) 筆")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("$\(categoryStats.amount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            // 子類別預覽
            if !category.subcategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(category.subcategories.sorted { $0.order < $1.order }.prefix(5)) { subcategory in
                            Text(subcategory.name)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                        
                        if category.subcategories.count > 5 {
                            Text("+\(category.subcategories.count - 5)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // 操作按鈕
            HStack {
                NavigationLink(destination: SubcategoryListView(category: category).environmentObject(dataController)) {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                        Text("管理子類別")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                NavigationLink(destination: CategoryTransactionsView(category: category).environmentObject(dataController)) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("查看交易")
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 專案卡片
struct ProjectCard: View {
    @EnvironmentObject var dataController: DataController
    let project: Project
    
    // 計算專案統計
    private var projectStats: (transactions: Int, amount: Int) {
        let transactions = dataController.transactions.filter { $0.project?.id == project.id }
        return (transactions: transactions.count, amount: transactions.reduce(0) { $0 + $1.amount })
    }
    
    var body: some View {
        NavigationLink(destination: ProjectDetailView(project: project).environmentObject(dataController)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.purple)
                    Spacer()
                    Text("\(projectStats.transactions)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text("$\(projectStats.amount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 類別交易視圖（如果還沒有的話）
struct CategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    let category: Category
    
    private var categoryTransactions: [Transaction] {
        dataController.transactions
            .filter { $0.category.id == category.id }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List {
            ForEach(categoryTransactions) { transaction in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(transaction.subcategory.name)
                            .fontWeight(.medium)
                        Spacer()
                        Text("$\(transaction.amount)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text(DateFormatter.shortDate.string(from: transaction.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let note = transaction.note {
                            Text("• \(note)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.large)
    }
}


// MARK: - AddCategoryView, ReassignCategoryTransactionsView (largely same as before)
struct AddCategoryView: View { /* ... (same as previous version) ... */
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var categoryName: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Category Name", text: $categoryName)
                Button("Add Category") {
                    if !categoryName.isEmpty {
                        dataController.addCategory(name: categoryName)
                        dismiss()
                    }
                }.disabled(categoryName.isEmpty)
            }
            .navigationTitle("New Category")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct ReassignCategoryTransactionsView: View { /* ... (same as previous version) ... */
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let categoryToReassignFrom: Category
    @Binding var selectedTargetCategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void
    var availableTargetCategories: [Category] { dataController.categories.filter { $0.id != categoryToReassignFrom.id && !$0.subcategories.isEmpty } }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign ALL transactions from \"\(categoryToReassignFrom.name)\" (and its subcategories) to a subcategory of:")) {
                    if availableTargetCategories.isEmpty { Text("No other categories with subcategories available.").foregroundColor(.orange) }
                    else {
                        Picker("Target Category", selection: $selectedTargetCategoryID) {
                            Text("Select a category...").tag(nil as PersistentIdentifier?)
                            ForEach(availableTargetCategories) { cat in Text("\(cat.name) (\(cat.subcategories.count) subs)").tag(cat.id as PersistentIdentifier?) }
                        }.labelsHidden()
                    }
                }
                Section { Button("Reassign and Delete Original Category") { handleReassignAndDeleteCategory() }.disabled(selectedTargetCategoryID == nil || availableTargetCategories.isEmpty) }
            }
            .navigationTitle("Select Target for Category Tx")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onCompletion(false); dismiss() } } }
            .onAppear { if selectedTargetCategoryID == nil, let first = availableTargetCategories.first { selectedTargetCategoryID = first.id } }
        }
    }
    private func handleReassignAndDeleteCategory() {
        guard let targetCatID = selectedTargetCategoryID, let targetCat = availableTargetCategories.first(where: { $0.id == targetCatID }) else { onCompletion(false); return }
        if dataController.reassignTransactions(from: categoryToReassignFrom, to: targetCat) {
            dataController.deleteCategory(categoryToReassignFrom); onCompletion(true); dismiss()
        } else { onCompletion(false) }
    }
}

// MARK: - SubcategoryListView (更新版本，加入導航到交易詳情)
struct SubcategoryListView: View {
    @EnvironmentObject var dataController: DataController
    @Bindable var category: Category
    @State private var subcategoryToAction: Subcategory?
    @State private var showingSubConfirmDirectDeleteDialog = false
    @State private var showingSubReassignSheet = false
    @State private var targetSubcategoryIDForReassignment: PersistentIdentifier?
    @State private var showingAddSubcategorySheet = false
    
    @State private var editingTransaction: Transaction?
    @State private var showingDateFilter = false
    @State private var filterStartDate: Date?
    @State private var filterEndDate: Date?

    // 計算該類別的所有交易，按日期排序
    private var allCategoryTransactions: [Transaction] {
        dataController.transactions
            .filter { $0.category.id == category.id }
            .sorted { $0.date > $1.date } // 最新的在前面
    }
    
    // 根據篩選條件顯示的交易
    private var categoryTransactions: [Transaction] {
        allCategoryTransactions.filtered(from: filterStartDate, to: filterEndDate)
    }
    
    // 篩選狀態描述
    private var filterStatusText: String? {
        guard let start = filterStartDate, let end = filterEndDate else { return nil }
        let formatter = DateFormatter.displayFormat
        return "篩選: \(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    // 計算該類別的統計資訊（使用篩選後的數據）
    private var categoryStats: (count: Int, total: Int) {
        let transactions = categoryTransactions
        return (count: transactions.count, total: transactions.reduce(0) { $0 + $1.amount })
    }

    var body: some View {
        List {
            // 類別統計資訊卡片
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("類別名稱")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(category.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("子類別數量")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(category.subcategories.count) 個")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("交易筆數")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(categoryStats.count) 筆")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    if categoryStats.count > 0 {
                        HStack {
                            Text("總金額")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$\(categoryStats.total)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        // 平均每筆交易金額
                        HStack {
                            Text("平均每筆")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$\(categoryStats.count > 0 ? categoryStats.total / categoryStats.count : 0)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // 子類別列表區塊
            Section(header: Text("子類別管理")) {
                if category.subcategories.isEmpty {
                    Text("No subcategories yet.").foregroundColor(.secondary)
                }
                ForEach(category.subcategories.sorted(by: { $0.order < $1.order }), id: \.id) { subcategory in
                    // 使用 NavigationLink 讓子類別可以點擊
                    NavigationLink(destination: SubcategoryTransactionsView(
                        subcategory: subcategory,
                        parentCategory: category
                    ).environmentObject(dataController)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subcategory.name)
                                    .font(.headline)
                                
                                // 顯示這個子類別的交易統計
                                let transactionCount = dataController.transactions.filter { $0.subcategory.id == subcategory.id }.count
                                let totalAmount = dataController.transactions
                                    .filter { $0.subcategory.id == subcategory.id }
                                    .reduce(0) { $0 + $1.amount }
                                
                                if transactionCount > 0 {
                                    Text("\(transactionCount) 筆交易，總計 $\(totalAmount)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("尚無交易記錄")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // 狀態指示器
                            VStack {
                                Text("(\(dataController.hasTransactions(subcategory: subcategory) ? "Has Tx" : "No Tx"))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                
                                // 箭頭圖示表示可以點擊
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            self.subcategoryToAction = subcategory
                            if dataController.hasTransactions(subcategory: subcategory) {
                                targetSubcategoryIDForReassignment = category.subcategories.first(where: { $0.id != subcategory.id })?.id
                                self.showingSubReassignSheet = true
                            } else {
                                self.showingSubConfirmDirectDeleteDialog = true
                            }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            
            // 該類別的所有交易記錄區塊
            Section(header: HStack {
                Text("All Transactions in \"\(category.name)\"")
                Spacer()
                HStack(spacing: 8) {
                    if !categoryTransactions.isEmpty {
                        Text("\(categoryStats.count) 筆，$\(categoryStats.total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Button {
                        showingDateFilter = true
                    } label: {
                        Image(systemName: filterStartDate != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(filterStartDate != nil ? .blue : .secondary)
                            .font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }) {
                // 篩選狀態提示
                if let filterText = filterStatusText {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                        Text(filterText)
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                        Button("清除篩選") {
                            filterStartDate = nil
                            filterEndDate = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.blue.opacity(0.05))
                }
                
                if categoryTransactions.isEmpty {
                    if allCategoryTransactions.isEmpty {
                        ContentUnavailableView(
                            "尚無交易記錄",
                            systemImage: "list.bullet.clipboard",
                            description: Text("這個類別還沒有任何交易記錄")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ContentUnavailableView(
                            "沒有符合條件的交易",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("請調整篩選條件或清除篩選")
                        )
                        .listRowBackground(Color.clear)
                    }
                } else {
                    ForEach(categoryTransactions) { transaction in
                        Button {
                            editingTransaction = transaction
                        } label: {
                            CategoryTransactionRow(transaction: transaction)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: deleteCategoryTransactions)
                }
            }
        }
        .navigationTitle("Manage Subcategories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddSubcategorySheet = true } label: {
                    Label("Add Subcategory", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSubcategorySheet) {
            AddSubcategoryView(category: category).environmentObject(dataController)
        }
        .sheet(isPresented: $showingDateFilter) {
            DateFilterView(
                startDate: $filterStartDate,
                endDate: $filterEndDate
            )
        }
        .confirmationDialog("Delete Subcategory: \"\(subcategoryToAction?.name ?? "")\"?", isPresented: $showingSubConfirmDirectDeleteDialog, presenting: subcategoryToAction) { subcatAction in
            Button("Delete Subcategory", role: .destructive) {
                dataController.deleteSubcategory(subcatAction, from: category)
                subcategoryToAction = nil
            }
            Button("Cancel", role: .cancel) { subcategoryToAction = nil }
        } message: { subcatAction in
            Text("Are you sure? \"\(subcatAction.name)\" has no transactions.")
        }
        .sheet(isPresented: $showingSubReassignSheet) {
            if let subFrom = subcategoryToAction {
                ReassignSubcategoryTransactionsView(
                    parentCategory: category,
                    subcategoryToReassignFrom: subFrom,
                    selectedTargetSubcategoryID: $targetSubcategoryIDForReassignment
                ) { success in
                    showingSubReassignSheet = false
                    if success { print("Subcategory reassigned/deleted.") }
                    else { print("Subcategory reassignment failed.") }
                    subcategoryToAction = nil
                }.environmentObject(dataController)
            }
        }
        .sheet(item: $editingTransaction) { transaction in
            EditTransactionView(transaction: transaction)
                .environmentObject(dataController)
        }
    }
    
    // 刪除該類別的交易
    private func deleteCategoryTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { categoryTransactions[$0] }.forEach { transaction in
                dataController.deleteTransaction(transaction)
            }
        }
    }
}

// MARK: - 類別交易列表項目（簡化版）
struct CategoryTransactionRow: View {
    let transaction: Transaction
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 日期圓形標籤（稍小一些）
            VStack {
                Text(dayFormatter.string(from: transaction.date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(monthFormatter.string(from: transaction.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 36, height: 36)
            .background(Color.orange.opacity(0.1))
            .clipShape(Circle())
            
            // 交易內容
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    // 子類別標籤
                    Text(transaction.subcategory.name)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text("$\(transaction.amount)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(timeFormatter.string(from: transaction.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let project = transaction.project {
                        HStack {
                            Image(systemName: "folder.fill")
                                .font(.caption2)
                            Text(project.name)
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    if transaction.photoData != nil {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.caption2)
                            Text("圖片")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 6)
    }
}
struct AddSubcategoryView: View { /* ... (same as previous version) ... */
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let category: Category
    @State private var subcategoryName: String = ""
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Adding to: \(category.name)")) { TextField("New Subcategory Name", text: $subcategoryName) }
                Button("Add Subcategory") { if !subcategoryName.isEmpty { dataController.addSubcategory(to: category, name: subcategoryName); dismiss() } }.disabled(subcategoryName.isEmpty)
            }
            .navigationTitle("New Subcategory").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct ReassignSubcategoryTransactionsView: View { /* ... (same as previous version) ... */
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let parentCategory: Category
    let subcategoryToReassignFrom: Subcategory
    @Binding var selectedTargetSubcategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void
    var availableTargetSubcategories: [Subcategory] { parentCategory.subcategories.filter { $0.id != subcategoryToReassignFrom.id } }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign transactions from \"\(subcategoryToReassignFrom.name)\" to another subcategory in \"\(parentCategory.name)\":")) {
                    if availableTargetSubcategories.isEmpty { Text("No other subcategories available.").foregroundColor(.orange) }
                    else {
                        Picker("Target Subcategory", selection: $selectedTargetSubcategoryID) {
                            Text("Select...").tag(nil as PersistentIdentifier?); ForEach(availableTargetSubcategories) { subcat in Text(subcat.name).tag(subcat.id as PersistentIdentifier?) }
                        }.labelsHidden()
                    }
                }
                Section { Button("Reassign and Delete Original Subcategory") { handleReassignAndSubDelete() }.disabled(selectedTargetSubcategoryID == nil || availableTargetSubcategories.isEmpty) }
            }
            .navigationTitle("Select Target Subcategory").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onCompletion(false); dismiss() } } }
            .onAppear { if selectedTargetSubcategoryID == nil, let first = availableTargetSubcategories.first { selectedTargetSubcategoryID = first.id } }
        }
    }
    private func handleReassignAndSubDelete() {
        guard let targetID = selectedTargetSubcategoryID, let targetSub = availableTargetSubcategories.first(where: { $0.id == targetID }) else { onCompletion(false); return }
        if dataController.reassignTransactions(from: subcategoryToReassignFrom, to: targetSub) {
            dataController.deleteSubcategory(subcategoryToReassignFrom, from: parentCategory); onCompletion(true); dismiss()
        } else { onCompletion(false) }
    }
}

struct AddProjectView: View { /* ... (same as previous version) ... */
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var projectName: String = ""
    var body: some View {
        NavigationView {
            Form { TextField("Project Name", text: $projectName)
                Button("Add Project") { if !projectName.isEmpty { dataController.addProject(name: projectName); dismiss() } }.disabled(projectName.isEmpty)
            }
            .navigationTitle("New Project").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct ReassignProjectTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss

    let projectToReassignFrom: Project
    @Binding var selectedTargetProjectID: PersistentIdentifier? // This is an Optional<PersistentIdentifier>
    var onCompletion: (Bool) -> Void

    private let noProjectTag: PersistentIdentifier? = nil // Explicit nil for "No Project" option

    var availableTargetProjects: [Project] {
        dataController.projects.filter { $0.id != projectToReassignFrom.id }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign transactions from \"\(projectToReassignFrom.name)\" to:")) {
                    Picker("Target Project", selection: $selectedTargetProjectID) {
                        Text("No Project (Clear Project Field)").tag(noProjectTag) // "None" option
                        ForEach(availableTargetProjects) { proj in
                            Text(proj.name).tag(proj.id as PersistentIdentifier?) // Tag with optional ID
                        }
                    }
                }
                Section {
                    Button("Apply Change and Delete Original Project") {
                        handleReassignAndDeleteProject()
                    }
                    // Button is always enabled because "No Project" is a valid selection
                }
            }
            .navigationTitle("Select Target for Project Tx")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onCompletion(false); dismiss() } } }
            .onAppear {
                // If no pre-selection, default to "No Project" or first available
                if selectedTargetProjectID == nil { // Only if not already set by caller
                    selectedTargetProjectID = availableTargetProjects.first?.id ?? noProjectTag
                }
            }
        }
    }

    private func handleReassignAndDeleteProject() {
        var operationSuccess = false
        if let targetID = selectedTargetProjectID { // A specific project is chosen
            if let targetProj = availableTargetProjects.first(where: { $0.id == targetID }) {
                operationSuccess = dataController.reassignTransactions(from: projectToReassignFrom, to: targetProj)
            } else {
                print("Error: Selected target project for reassignment not found.")
                onCompletion(false); return
            }
        } else { // "No Project" (nil) was chosen
            operationSuccess = dataController.clearProjectFromTransactions(of: projectToReassignFrom)
        }

        if operationSuccess {
            dataController.deleteProject(projectToReassignFrom) // Now delete the original project
            onCompletion(true); dismiss()
        } else {
            print("Error: Project transaction operation (reassign to other or nil) failed.")
            onCompletion(false)
        }
    }
}
