// SubcategoryListView.swift

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
    let subcategoriesToDisplay: [Subcategory]
    let onPrepareToDelete: (Subcategory) -> Void
    let refreshID: UUID // <--- 新增參數
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                
                // 顯示從 category 物件獲取的總子類別數
                Text("\(category.subcategories.count) 個子類別")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            Text("子類別讓你更精確地分類 \"\(category.name)\" 下的不同支出類型。點擊進入詳情，左滑刪除。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            if subcategoriesToDisplay.isEmpty {
                SubcategoryEmptyState()
                    .padding(.horizontal)
            } else {
                List {
                    ForEach(subcategoriesToDisplay.sorted { $0.order < $1.order }) { subcategory in
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
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onPrepareToDelete(subcategory)
                            } label: {
                                Label("刪除", systemImage: "trash.fill")
                            }
                        }
                    }
                }
                .id(refreshID)
                .listStyle(PlainListStyle())
                .scrollDisabled(true)
                .frame(minHeight: CGFloat(subcategoriesToDisplay.count * 75)) // 75 是估計的行高
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

      
private var subcategoryStats: (transactions: Int, amount: Int) {
    let transactions = dataController.transactions.filter { $0.subcategory.id == subcategory.id }
    return (transactions: transactions.count, amount: transactions.reduce(0) { $0 + $1.amount })
}

var body: some View {
    HStack(alignment: .center, spacing: 12) {
        VStack {
            Text(String(subcategory.name.prefix(1)))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: 36, height: 36)
        .background(Color.blue)
        .clipShape(Circle())
        
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
    let categoryTransactions: [Transaction] // 篩選後的交易
    let categoryStats: (count: Int, total: Int) // 基於篩選後交易的統計
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
                // 只有當篩選後的交易不為空時才顯示統計
                if !categoryTransactions.isEmpty || (filterStartDate == nil && categoryStats.count > 0) {
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
                        .font(.title3) // 稍微放大一點
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
    let hasAnyTransactionsAtAll: Bool // 是否完全沒有任何交易記錄
    let categoryName: String
    
    
    var body: some View {
        VStack(spacing: 12) {
            if hasAnyTransactionsAtAll { // 有交易記錄，但篩選後為空
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("沒有符合目前篩選條件的交易")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("請調整篩選條件或清除篩選")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else { // 完全沒有任何交易記錄
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
    let categoryTransactions: [Transaction] // 篩選後要顯示的交易
    let allCategoryTransactions: [Transaction] // 父類別下的所有交易（用於判斷空狀態）
    let category: Category // 父類別
    let onTransactionTap: (Transaction) -> Void
    
    
    var body: some View {
        // 使用 allCategoryTransactions 來判斷是否 *完全* 沒有交易
        if categoryTransactions.isEmpty {
            CategoryTransactionEmptyState(
                hasAnyTransactionsAtAll: !allCategoryTransactions.isEmpty,
                categoryName: category.name
            )
        } else {
            List {
                ForEach(categoryTransactions) { transaction in
                    Button {
                        onTransactionTap(transaction)
                    } label: {
                        HStack {
                            // 你可能需要一個 TransactionRowView
                            // 為了簡化，這裡直接用文字，實際應有更豐富的行視圖
                            VStack(alignment: .leading) {
                                Text(transaction.subcategory.name)
                                    .font(.headline)
                                Text("$\(transaction.amount) - \(transaction.date, formatter: DateFormatter.shortDate)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let note = transaction.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear) // 或者 .listRowBackground(Color(.systemBackground)) 如果需要背景
                }
                .onDelete(perform: deleteTransactions)
            }
            .listStyle(PlainListStyle())
            .scrollDisabled(true)
            .frame(height: CGFloat(categoryTransactions.count * 70)) // 估計行高
        }
    }
    
    private func deleteTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { categoryTransactions[$0] }.forEach { transaction in
                dataController.deleteTransaction(transaction)
                // 注意：這裡也需要一種機制來刷新 SubcategoryListView 的交易列表，
                // 例如通過更新一個 refreshID，或者確保 DataController 的 transactions 更新能被觀察到
            }
        }
    }
}

// MARK: - 類別交易記錄區域
struct CategoryTransactionSection: View {
    @EnvironmentObject var dataController: DataController
    let category: Category
    let categoryTransactions: [Transaction] // 篩選後的交易
    let categoryStats: (count: Int, total: Int)
    let filterStatusText: String?
    let allCategoryTransactions: [Transaction] // 用於判斷空狀態
    let filterStartDate: Date?
    
    
    let onTransactionTap: (Transaction) -> Void
    let onFilterTap: () -> Void
    let onClearFilter: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CategoryTransactionHeader(
                category: category,
                categoryTransactions: categoryTransactions,
                categoryStats: categoryStats,
                filterStartDate: filterStartDate,
                onFilterTap: onFilterTap
            )
            .environmentObject(dataController)
            
            Text("這裡顯示 \"\(category.name)\" 類別下所有子類別的交易記錄。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            if let filterText = filterStatusText {
                CategoryTransactionFilterStatus(
                    filterText: filterText,
                    onClearFilter: onClearFilter
                )
            }
            
            CategoryTransactionList(
                categoryTransactions: categoryTransactions,
                allCategoryTransactions: allCategoryTransactions, // 傳遞所有交易
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

// MARK: - 子類別管理主視圖 (SubcategoryListView)
struct SubcategoryListView: View {
    @EnvironmentObject var dataController: DataController
    let category: Category // 傳入的父類別

    // 子類別刪除與重新分配相關狀態
    // @State private var subcategoryToAction: Subcategory? // 被 subcategoryForItemSheet 取代
    // @State private var showingSubReassignSheet = false  // 被 subcategoryForItemSheet 取代
    @State private var subcategoryForItemSheet: Subcategory? // <--- 新增：用於 .sheet(item:)
    @State private var targetSubcategoryIDForReassignment: PersistentIdentifier?
    
    @State private var showingAddSubcategorySheet = false
    
    // 列表刷新相關狀態
    @State private var listRefreshID = UUID()
    @State private var subcategoriesForListDisplay: [Subcategory] = []

    // 交易篩選相關狀態
    @State private var editingTransaction: Transaction?
    @State private var showingDateFilter = false
    @State private var filterStartDate: Date?
    @State private var filterEndDate: Date?
    
    @State private var showingCannotDeleteSubcategoryAlert = false
    @State private var subcategoryAlertMessage = ""

    // 計算屬性
    private var allCategoryTransactions: [Transaction] {
        dataController.transactions
            .filter { $0.category.id == category.id }
            .sorted { $0.date > $1.date }
    }
    
    private var categoryTransactions: [Transaction] { // 篩選後的交易
        allCategoryTransactions.filtered(from: filterStartDate, to: filterEndDate)
    }
    
    private var filterStatusText: String? {
        guard let start = filterStartDate, let end = filterEndDate else { return nil }
        let formatter = DateFormatter.displayFormat // 確保 DateFormatter.displayFormat 已定義
        return "篩選: \(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    private var categoryStats: (count: Int, total: Int) { // 基於篩選後交易的統計
        let transactions = categoryTransactions
        return (count: transactions.count, total: transactions.reduce(0) { $0 + $1.amount })
    }
    private let estimatedRowHeight: CGFloat = 75

    var body: some View {
        VStack(spacing: 0) {
            SubcategoryNavigationHeader(category: category) {
                showingAddSubcategorySheet = true
            }
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    SubcategoryManagementSection(
                        category: category,
                        subcategoriesToDisplay: subcategoriesForListDisplay,
                        onPrepareToDelete: { subcategory in
                            self.prepareForSubcategoryDelete(subcategory)
                        },
                        refreshID: listRefreshID
                    )
                    .environmentObject(dataController)
                    
                    SectionDivider()
                    
                    CategoryTransactionSection(
                        category: category,
                        categoryTransactions: categoryTransactions,
                        categoryStats: categoryStats,
                        filterStatusText: filterStatusText,
                        allCategoryTransactions: allCategoryTransactions,
                        filterStartDate: filterStartDate,
                        onTransactionTap: { transaction in editingTransaction = transaction },
                        onFilterTap: { showingDateFilter = true },
                        onClearFilter: {
                            filterStartDate = nil
                            filterEndDate = nil
                        }
                    )
                    .environmentObject(dataController)
                }
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            print("SubcategoryListView onAppear for category: \(category.name)")
            updateSubcategoriesForListDisplay()
        }
        .sheet(isPresented: $showingAddSubcategorySheet, onDismiss: {
            print("AddSubcategorySheet dismissed. Updating display list.")
            updateSubcategoriesForListDisplay()
        }) {
            // 假設 AddSubcategoryView 已定義
            AddSubcategoryView(category: category).environmentObject(dataController)
        }
        .sheet(isPresented: $showingDateFilter) {
            // 假設 DateFilterView 已定義
            // DateFilterView(startDate: $filterStartDate, endDate: $filterEndDate)
             Text("Date Filter Placeholder") // Placeholder
        }
        .sheet(item: $editingTransaction, onDismiss: {
            print("EditTransactionView dismissed.")
        }) { transaction in
            // 假設 EditTransactionView 已定義
            // EditTransactionView(transaction: transaction)
            //    .environmentObject(dataController)
            Text("Edit Transaction Placeholder for \(transaction.id)") // Placeholder
        }
        // MARK: 修改 Reassign Sheet 的呈現方式
        .sheet(item: $subcategoryForItemSheet, onDismiss: {
            // 當 sheet 關閉時 (無論何種方式)，item 會被設為 nil
            // 這是清理 targetSubcategoryIDForReassignment 的好地方
            print("ReassignSubcategory sheet (item-driven) dismissed. Resetting targetSubcategoryID.")
            self.targetSubcategoryIDForReassignment = nil
        }) { subcategoryToReassign in // subcategoryToReassign 是非可選的 Subcategory
            NavigationView { // 確保 sheet 內容有 NavigationView
                ReassignSubcategoryTransactionsView(
                    parentCategory: category, // 確保 category 是最新的
                    subcategoryToReassignFrom: subcategoryToReassign, // 使用 item
                    selectedTargetSubcategoryID: $targetSubcategoryIDForReassignment
                ) { success in
                    // onCompletion 回調仍然有用，用於在操作完成後觸發列表刷新
                    // sheet 的關閉現在由 subcategoryForItemSheet = nil 自動處理
                    if success {
                        print("✅ 子類別重新分配/刪除完成。Updating display list.")
                        self.updateSubcategoriesForListDisplay()
                    } else {
                        print("❌ 子類別重新分配失敗或取消。")
                    }
                    // subcategoryForItemSheet 會在 ReassignSubcategoryTransactionsView 的父視圖
                    // (此處是 SubcategoryListView) 的 onCompletion 回調執行完畢後，
                    // 且 ReassignSubcategoryTransactionsView 的 dismiss() 被調用時（如果它自己調用），
                    // 或此 sheet 的 item 綁定變為 nil 時自動關閉。
                    // targetSubcategoryIDForReassignment 在 sheet 的 onDismiss 中清理。
                }
                .environmentObject(dataController)
            }
        }
        .alert("無法刪除子類別", isPresented: $showingCannotDeleteSubcategoryAlert) {
            Button("確認", role: .cancel) { }
        } message: {
            Text(subcategoryAlertMessage)
        }
    }
    
    private func updateSubcategoriesForListDisplay() {
        if let freshCategory = dataController.categories.first(where: { $0.id == category.id }) {
            self.subcategoriesForListDisplay = freshCategory.subcategories.sorted { $0.order < $1.order }
        } else {
            self.subcategoriesForListDisplay = []
            print("⚠️ Parent category \(category.name) not found in DataController during subcategory display update.")
        }
        self.listRefreshID = UUID()
        print("SubcategoriesForListDisplay updated for category '\(category.name)'. Count: \(self.subcategoriesForListDisplay.count). New listRefreshID: \(self.listRefreshID)")
    }

    private func prepareForSubcategoryDelete(_ subcategoryToDelete: Subcategory) {
        print("Preparing to delete subcategory: \(subcategoryToDelete.name) from category: \(category.name)")
        
        guard let currentCategoryInDC = dataController.categories.first(where: { $0.id == category.id }) else {
            print("❌ Parent category \(category.name) not found in DataController. Aborting delete.")
            updateSubcategoriesForListDisplay()
            return
        }
        guard currentCategoryInDC.subcategories.contains(where: { $0.id == subcategoryToDelete.id }) else {
            print("❌ Subcategory \(subcategoryToDelete.name) no longer exists in \(currentCategoryInDC.name). Aborting delete.")
            updateSubcategoriesForListDisplay()
            return
        }

        // 重置 targetID，以防上次操作遺留
        self.targetSubcategoryIDForReassignment = nil
        
        if dataController.hasTransactions(subcategory: subcategoryToDelete) {
            let availableTargets = currentCategoryInDC.subcategories.filter { $0.id != subcategoryToDelete.id }
            
            if availableTargets.isEmpty {
                print("⚠️ 無法刪除子類別 \(subcategoryToDelete.name)：在 \"\(currentCategoryInDC.name)\" 中沒有其他子類別可用於重新分配交易")
                self.subcategoryAlertMessage = "無法刪除子類別「\(subcategoryToDelete.name)」，因為在「\(currentCategoryInDC.name)」中沒有其他子類別可供其交易重新分配。"
                self.showingCannotDeleteSubcategoryAlert = true
                // 此處不設置 subcategoryForItemSheet，所以 sheet 不會彈出
                return
            }
            
            self.targetSubcategoryIDForReassignment = availableTargets.first?.id
            // MARK: 觸發 item-driven sheet
            self.subcategoryForItemSheet = subcategoryToDelete // <--- 設置 item 來觸發 sheet
            print("Set subcategoryForItemSheet to \(subcategoryToDelete.name) to show reassign sheet.")
            
            DispatchQueue.main.async {
                 print(">>> Swipe action triggered sheet, attempting to refresh list display immediately.")
                 self.updateSubcategoriesForListDisplay()
            }
        } else {
            print("✅ Deleting empty subcategory: \(subcategoryToDelete.name)")
            dataController.deleteSubcategory(subcategoryToDelete, from: currentCategoryInDC)
            self.updateSubcategoriesForListDisplay()
            // 此處不需要操作 subcategoryForItemSheet，因為沒有 sheet 要顯示
        }
    }
    
    private func calculateListHeightForDisplay() -> CGFloat {
        let minHeight: CGFloat = estimatedRowHeight
        let calculatedHeight = CGFloat(subcategoriesForListDisplay.count) * estimatedRowHeight
        return max(minHeight, calculatedHeight)
    }
}
// MARK: - Add Subcategory View
struct AddSubcategoryView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let category: Category
    
    @State private var subcategoryName: String = ""
    
    var body: some View {
        NavigationView { // 每個 sheet 都應該有自己的 NavigationView (如果需要導航欄)
            Form {
                Section(header: Text("新增到類別: \(category.name)")) {
                    TextField("子類別名稱", text: $subcategoryName)
                }
                Button("新增子類別") {
                    if !subcategoryName.isEmpty {
                        // 確保傳遞給 dataController 的 category 是最新的
                        // 但通常情況下，如果 category 是從父視圖傳來的，且父視圖正確管理其狀態，
                        // 這裡的 category 應該是有效的。
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

// MARK: - Reassign Subcategory Transactions View
struct ReassignSubcategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    let parentCategory: Category // 傳入最新的父類別實例
    let subcategoryToReassignFrom: Subcategory
    @Binding var selectedTargetSubcategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void
    
    // 從傳入的 parentCategory (應為最新) 中獲取可選目標
    var availableTargetSubcategories: [Subcategory] {
        parentCategory.subcategories.filter { $0.id != subcategoryToReassignFrom.id }
    }
    
    var body: some View {
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
            // 確保 selectedTargetSubcategoryID 被正確初始化
            if selectedTargetSubcategoryID == nil, let firstAvailable = availableTargetSubcategories.first {
                selectedTargetSubcategoryID = firstAvailable.id
            }
        }
    }
    
    private func handleReassignAndSubDelete() {
        guard let targetID = selectedTargetSubcategoryID,
              // 從最新的 parentCategory 實例中查找目標子類別
              let targetSub = parentCategory.subcategories.first(where: { $0.id == targetID }) else {
            print("Error: No valid target subcategory for reassignment in \(parentCategory.name).")
            onCompletion(false)
            dismiss()
            return
        }
        
        // 確保 parentCategory 是最新的
        if dataController.reassignTransactions(from: subcategoryToReassignFrom, to: targetSub) {
            dataController.deleteSubcategory(subcategoryToReassignFrom, from: parentCategory)
            onCompletion(true)
            dismiss()
        } else {
            print("Error: Subcategory transaction reassignment or deletion failed.")
            onCompletion(false)
            dismiss()
        }
    }
}
