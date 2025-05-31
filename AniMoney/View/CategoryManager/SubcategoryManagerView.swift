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
            Text("子類別讓你更精確地分類 \"\(category.name)\" 下的不同支出類型。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            // 子類別卡片
            if category.subcategories.isEmpty {
                SubcategoryEmptyState()
            } else {
                ForEach(category.subcategories.sorted { $0.order < $1.order }) { subcategory in
                    SubcategoryCard(subcategory: subcategory, parentCategory: category)
                        .environmentObject(dataController)
                        .padding(.horizontal)
                }
            }
        }
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
            ForEach(categoryTransactions) { transaction in
                Button {
                    onTransactionTap(transaction)
                } label: {
                    CategoryTransactionRow(transaction: transaction)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                
                if transaction.id != categoryTransactions.last?.id {
                    Divider()
                        .padding(.horizontal)
                }
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
        VStack(spacing: 0) {
            // 自定義導航欄
            SubcategoryNavigationHeader(category: category) {
                showingAddSubcategorySheet = true
            }
            
            // 主要內容
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 子類別管理區域
                    SubcategoryManagementSection(category: category)
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
        .confirmationDialog("Delete Subcategory: \"\(subcategoryToAction?.name ?? "")\"?", isPresented: $showingSubConfirmDirectDeleteDialog) {
            Button("Delete Subcategory", role: .destructive) {
                if let subcategory = subcategoryToAction {
                    dataController.deleteSubcategory(subcategory, from: category)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure? \"\(subcategoryToAction?.name ?? "")\" has no transactions.")
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
                        print("Subcategory operation completed.")
                    } else {
                        print("Subcategory operation failed/cancelled.")
                    }
                }
                .environmentObject(dataController)
            } else {
                Text("Subcategory data is no longer available.")
                    .onAppear {
                        showingSubReassignSheet = false
                    }
            }
        }
    }
}

// MARK: - 子類別卡片
struct SubcategoryCard: View {
    @EnvironmentObject var dataController: DataController
    let subcategory: Subcategory
    let parentCategory: Category
    @State private var showingDeleteConfirmation = false
    
    // 計算子類別統計
    private var subcategoryStats: (transactions: Int, amount: Int) {
        let transactions = dataController.transactions.filter { $0.subcategory.id == subcategory.id }
        return (transactions: transactions.count, amount: transactions.reduce(0) { $0 + $1.amount })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 子類別標題和統計
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subcategory.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("順序: \(subcategory.order)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(subcategoryStats.transactions) 筆")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    Text("$\(subcategoryStats.amount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            // 操作按鈕
            HStack {
                NavigationLink(destination: SubcategoryTransactionsView(subcategory: subcategory, parentCategory: parentCategory).environmentObject(dataController)) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("查看交易")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                if subcategoryStats.transactions == 0 {
                    Button("刪除") {
                        showingDeleteConfirmation = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Capsule())
                } else {
                    Text("有 \(subcategoryStats.transactions) 筆交易")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .confirmationDialog("刪除子類別: \"\(subcategory.name)\"?", isPresented: $showingDeleteConfirmation) {
            Button("刪除", role: .destructive) {
                dataController.deleteSubcategory(subcategory, from: parentCategory)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("確定要刪除 \"\(subcategory.name)\"？此操作無法復原。")
        }
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let displayFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}


#Preview {
    NavigationView {
        SubcategoryListView(category: Category(name: "食品酒水", order: 0))
            .environmentObject(try! DataController())
    }
}
