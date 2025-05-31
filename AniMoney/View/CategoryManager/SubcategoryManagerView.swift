import SwiftUI
import SwiftData

// MARK: - 導航欄組件
struct SubcategoryNavigationHeader: View {
    let category: Category
    let onAddTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("子類別管理")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onAddTap) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - 子類別空狀態
struct SubcategoryEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tag.slash")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("還沒有任何子類別")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("點擊右上角的加號來新增第一個子類別")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
    }
}

// MARK: - 子類別管理區域
struct SubcategoryManagementSection: View {
    @EnvironmentObject var dataController: DataController
    let category: Category
    let onDeleteRequest: ([Subcategory]) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 子類別區域標題
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text("子類別列表")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("\(category.subcategories.count) 個子類別")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            // 子類別說明
            Text("子類別讓你更精確地分類 \"\(category.name)\" 下的不同支出類型。點擊進入詳情，左滑刪除。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            // 子類別列表
            if category.subcategories.isEmpty {
                SubcategoryEmptyState()
                    .padding(.horizontal)
            } else {
                List {
                    ForEach(category.subcategories.sorted { $0.order < $1.order }) { subcategory in
                        NavigationLink(destination: SubcategoryTransactionsView(subcategory: subcategory, parentCategory: category).environmentObject(dataController)) {
                            HStack {
                                SubcategoryListRow(subcategory: subcategory)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.clear)
                            .contentShape(Rectangle())
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                        .listRowBackground(Color(.systemBackground))
                        .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: { offsets in
                        let sortedSubcategories = category.subcategories.sorted { $0.order < $1.order }
                        let subcategoriesToDelete = offsets.map { sortedSubcategories[$0] }
                        onDeleteRequest(subcategoriesToDelete)
                    })
                }
                .listStyle(PlainListStyle())
                .scrollDisabled(true)
                .frame(minHeight: CGFloat(category.subcategories.count * 75))
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - 子類別列表行
struct SubcategoryListRow: View {
    @EnvironmentObject var dataController: DataController
    let subcategory: Subcategory
    
    // 計算子類別統計
    private var subcategoryStats: (transactions: Int, amount: Int) {
        let transactions = dataController.transactions.filter { $0.subcategory.id == subcategory.id }
        return (transactions: transactions.count, amount: transactions.reduce(0) { $0 + $1.amount })
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 子類別圖標
            VStack {
                Text(String(subcategory.name.prefix(1)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)
            .background(Color.blue)
            .clipShape(Circle())
            
            // 子類別信息
            VStack(alignment: .leading, spacing: 4) {
                Text(subcategory.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("\(subcategoryStats.transactions) 筆交易")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$\(subcategoryStats.amount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 分隔線組件
struct SectionDivider: View {
    var body: some View {
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
    }
}

// MARK: - 交易區域標題
struct CategoryTransactionHeader: View {
    @EnvironmentObject var dataController: DataController
    let category: Category
    let categoryTransactions: [Transaction]
    let categoryStats: (count: Int, total: Int)
    let filterStartDate: Date?
    let onFilterTap: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("\"\(category.name)\" 交易記錄")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if !categoryTransactions.isEmpty {
                    Text("\(categoryStats.count) 筆，$\(categoryStats.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                }
                Button(action: onFilterTap) {
                    Image(systemName: filterStartDate != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(filterStartDate != nil ? .orange : .secondary)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 篩選狀態組件
struct CategoryTransactionFilterStatus: View {
    let filterText: String
    let onClearFilter: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .foregroundColor(.orange)
            Text(filterText)
                .font(.caption)
                .foregroundColor(.orange)
            Spacer()
            Button("清除篩選", action: onClearFilter)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

// MARK: - 交易空狀態
struct CategoryTransactionEmptyState: View {
    let hasTransactions: Bool
    let categoryName: String
    
    var body: some View {
        VStack(spacing: 12) {
            if hasTransactions {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("沒有符合條件的交易")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("請調整篩選條件或清除篩選")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "list.bullet.clipboard")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("還沒有任何交易記錄")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("開始記錄 \"\(categoryName)\" 相關的支出吧！")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
    }
}

// MARK: - 交易列表組件
struct CategoryTransactionList: View {
    @EnvironmentObject var dataController: DataController
    let categoryTransactions: [Transaction]
    let allCategoryTransactions: [Transaction]
    let category: Category
    let onTransactionTap: (Transaction) -> Void
    
    var body: some View {
        if categoryTransactions.isEmpty {
            CategoryTransactionEmptyState(
                hasTransactions: !allCategoryTransactions.isEmpty,
                categoryName: category.name
            )
        } else {
            List {
                ForEach(categoryTransactions) { transaction in
                    Button {
                        onTransactionTap(transaction)
                    } label: {
                        HStack {
                            CategoryTransactionRow(transaction: transaction)
                            Spacer() // 確保右側有空白可點擊
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(Color.clear) // 恢復透明背景
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                .onDelete(perform: deleteTransactions)
            }
            .listStyle(PlainListStyle())
            .scrollDisabled(true) // 禁用 List 的滾動，使用外層 ScrollView
            .frame(height: CGFloat(categoryTransactions.count * 90)) // 根據項目數量設定固定高度
        }
    }
    
    // 刪除交易
    private func deleteTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { categoryTransactions[$0] }.forEach { transaction in
                dataController.deleteTransaction(transaction)
            }
        }
    }
}

// MARK: - 類別交易記錄區域
struct CategoryTransactionSection: View {
    @EnvironmentObject var dataController: DataController
    let category: Category
    let categoryTransactions: [Transaction]
    let categoryStats: (count: Int, total: Int)
    let filterStatusText: String?
    let allCategoryTransactions: [Transaction]
    let filterStartDate: Date?
    
    let onTransactionTap: (Transaction) -> Void
    let onFilterTap: () -> Void
    let onClearFilter: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 交易區域標題
            CategoryTransactionHeader(
                category: category,
                categoryTransactions: categoryTransactions,
                categoryStats: categoryStats,
                filterStartDate: filterStartDate,
                onFilterTap: onFilterTap
            )
            .environmentObject(dataController)
            
            // 交易說明
            Text("這裡顯示 \"\(category.name)\" 類別下所有子類別的交易記錄。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            // 篩選狀態提示
            if let filterText = filterStatusText {
                CategoryTransactionFilterStatus(
                    filterText: filterText,
                    onClearFilter: onClearFilter
                )
            }
            
            // 交易列表
            CategoryTransactionList(
                categoryTransactions: categoryTransactions,
                allCategoryTransactions: allCategoryTransactions,
                category: category,
                onTransactionTap: onTransactionTap
            )
            .environmentObject(dataController)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - 子類別管理主視圖
struct SubcategoryListView: View {
    @EnvironmentObject var dataController: DataController
    @Bindable var category: Category
    @State private var subcategoryToAction: Subcategory?
    @State private var showingSubReassignSheet = false
    @State private var targetSubcategoryIDForReassignment: PersistentIdentifier?
    @State private var showingAddSubcategorySheet = false
    
    // 批量刪除狀態
    @State private var pendingSubcategoryDeletions: [Subcategory] = []
    @State private var currentSubcategoryDeletionIndex = 0
    
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
        VStack(spacing: 0) {
            // 自定義導航欄
            SubcategoryNavigationHeader(category: category) {
                showingAddSubcategorySheet = true
            }
            
            // 主要內容
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 子類別管理區域
                    SubcategoryManagementSection(
                        category: category,
                        onDeleteRequest: { subcategories in
                            handleSubcategoryDeleteRequest(subcategories)
                        }
                    )
                    .environmentObject(dataController)
                    
                    // 分隔線區域
                    SectionDivider()
                    
                    // 類別交易記錄區域
                    CategoryTransactionSection(
                        category: category,
                        categoryTransactions: categoryTransactions,
                        categoryStats: categoryStats,
                        filterStatusText: filterStatusText,
                        allCategoryTransactions: allCategoryTransactions,
                        filterStartDate: filterStartDate
                    ) { transaction in
                        editingTransaction = transaction
                    } onFilterTap: {
                        showingDateFilter = true
                    } onClearFilter: {
                        filterStartDate = nil
                        filterEndDate = nil
                    }
                    .environmentObject(dataController)
                }
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingAddSubcategorySheet) {
            AddSubcategoryView(category: category).environmentObject(dataController)
        }
        .sheet(isPresented: $showingDateFilter) {
            DateFilterView(
                startDate: $filterStartDate,
                endDate: $filterEndDate
            )
        }
        .sheet(item: $editingTransaction) { transaction in
            EditTransactionView(transaction: transaction)
                .environmentObject(dataController)
        }
        .sheet(isPresented: $showingSubReassignSheet) {
            if let subcategory = subcategoryToAction {
                ReassignSubcategoryTransactionsView(
                    parentCategory: category,
                    subcategoryToReassignFrom: subcategory,
                    selectedTargetSubcategoryID: $targetSubcategoryIDForReassignment
                ) { success in
                    showingSubReassignSheet = false
                    if success {
                        print("✅ 子類別重新分配完成")
                        // 處理完當前項目後，繼續處理下一個
                        currentSubcategoryDeletionIndex += 1
                        processPendingSubcategoryDeletions()
                    } else {
                        print("❌ 子類別重新分配失敗或取消")
                        // 取消操作，清理所有狀態
                        cancelSubcategoryDeletion()
                    }
                }
                .environmentObject(dataController)
            } else {
                Text("子類別資料不再可用")
                    .onAppear {
                        showingSubReassignSheet = false
                        // 當前項目無效，繼續處理下一個
                        currentSubcategoryDeletionIndex += 1
                        processPendingSubcategoryDeletions()
                    }
            }
        }
    }
    
    // MARK: - 修復後的處理子類別刪除請求
    private func handleSubcategoryDeleteRequest(_ subcategories: [Subcategory]) {
        // 清空之前的狀態，重新開始
        subcategoryToAction = nil
        targetSubcategoryIDForReassignment = nil
        
        // 將要刪除的子類別加入待處理隊列
        pendingSubcategoryDeletions = subcategories
        currentSubcategoryDeletionIndex = 0
        
        // 開始處理第一個項目
        processPendingSubcategoryDeletions()
    }
    
    private func processPendingSubcategoryDeletions() {
        // 檢查是否還有待處理的項目
        guard currentSubcategoryDeletionIndex < pendingSubcategoryDeletions.count else {
            // 所有項目都處理完了，清空隊列和狀態
            cleanupSubcategoryDeletionState()
            return
        }
        
        let subcategoryToDelete = pendingSubcategoryDeletions[currentSubcategoryDeletionIndex]
        
        // 檢查子類別是否仍然存在於 category 中
        guard category.subcategories.contains(where: { $0.id == subcategoryToDelete.id }) else {
            // 子類別已經不存在，跳到下一個
            print("ℹ️ 子類別 \(subcategoryToDelete.name) 已不存在，跳過")
            currentSubcategoryDeletionIndex += 1
            processPendingSubcategoryDeletions()
            return
        }
        
        subcategoryToAction = subcategoryToDelete
        
        if dataController.hasTransactions(subcategory: subcategoryToDelete) {
            // 有交易，觸發重新分配流程
            let availableTargets = category.subcategories.filter { $0.id != subcategoryToDelete.id }
            
            if availableTargets.isEmpty {
                // 沒有可用的目標子類別，跳過這個刪除操作
                print("⚠️ 無法刪除子類別 \(subcategoryToDelete.name)：沒有其他子類別可用於重新分配交易")
                currentSubcategoryDeletionIndex += 1
                processPendingSubcategoryDeletions()
                return
            }
            
            targetSubcategoryIDForReassignment = availableTargets.first?.id
            showingSubReassignSheet = true
        } else {
            // 沒有交易，直接刪除
            withAnimation {
                dataController.deleteSubcategory(subcategoryToDelete, from: category)
            }
            print("✅ 已刪除空子類別: \(subcategoryToDelete.name)")
            
            // 處理下一個項目
            currentSubcategoryDeletionIndex += 1
            processPendingSubcategoryDeletions()
        }
    }
    
    // 清理子類別刪除相關的所有狀態
    private func cleanupSubcategoryDeletionState() {
        pendingSubcategoryDeletions.removeAll()
        currentSubcategoryDeletionIndex = 0
        subcategoryToAction = nil
        targetSubcategoryIDForReassignment = nil
    }
    
    // 取消子類別刪除操作
    private func cancelSubcategoryDeletion() {
        cleanupSubcategoryDeletionState()
        showingSubReassignSheet = false
    }
}

// MARK: - Add Subcategory View
struct AddSubcategoryView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let category: Category // Parent category

    @State private var subcategoryName: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("新增到類別: \(category.name)")) {
                    TextField("子類別名稱", text: $subcategoryName)
                }
                Button("新增子類別") {
                    if !subcategoryName.isEmpty {
                        dataController.addSubcategory(to: category, name: subcategoryName)
                        dismiss()
                    }
                }.disabled(subcategoryName.isEmpty)
            }
            .navigationTitle("新增子類別")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Reassign Subcategory Transactions View (Sheet for Subcategory reassignment)
struct ReassignSubcategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss

    let parentCategory: Category
    let subcategoryToReassignFrom: Subcategory
    @Binding var selectedTargetSubcategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void

    var availableTargetSubcategories: [Subcategory] {
        parentCategory.subcategories.filter { $0.id != subcategoryToReassignFrom.id }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("重新分配 \"\(subcategoryToReassignFrom.name)\" 的所有交易到 \"\(parentCategory.name)\" 的其他子類別：")) {
                    if availableTargetSubcategories.isEmpty {
                        Text("在 \"\(parentCategory.name)\" 中沒有其他子類別可供選擇。")
                            .foregroundColor(.orange)
                    } else {
                        Picker("目標子類別", selection: $selectedTargetSubcategoryID) {
                            Text("請選擇子類別...").tag(nil as PersistentIdentifier?)
                            ForEach(availableTargetSubcategories) { subcat in
                                Text(subcat.name).tag(subcat.id as PersistentIdentifier?)
                            }
                        }.labelsHidden()
                    }
                }
                Section {
                    Button("重新分配並刪除原子類別") {
                        handleReassignAndSubDelete()
                    }.disabled(selectedTargetSubcategoryID == nil || availableTargetSubcategories.isEmpty)
                }
            }
            .navigationTitle("選擇目標子類別")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCompletion(false)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if selectedTargetSubcategoryID == nil, let firstAvailable = availableTargetSubcategories.first {
                    selectedTargetSubcategoryID = firstAvailable.id
                }
            }
        }
    }

    private func handleReassignAndSubDelete() {
        guard let targetID = selectedTargetSubcategoryID,
              let targetSub = availableTargetSubcategories.first(where: { $0.id == targetID }) else {
            print("Error: No valid target subcategory for reassignment.")
            onCompletion(false)
            return
        }
        if dataController.reassignTransactions(from: subcategoryToReassignFrom, to: targetSub) {
            dataController.deleteSubcategory(subcategoryToReassignFrom, from: parentCategory)
            onCompletion(true)
            dismiss()
        } else {
            print("Error: Subcategory transaction reassignment failed.")
            onCompletion(false)
        }
    }
}

#Preview {
    NavigationView {
        SubcategoryListView(category: Category(name: "食品酒水", order: 0))
            .environmentObject(try! DataController())
    }
}
