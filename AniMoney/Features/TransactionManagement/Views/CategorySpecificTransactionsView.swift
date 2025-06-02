// CategorySpecificTransactionsView.swift (修改自你的 CategoryTransactionsView)

import SwiftUI
import SwiftData

struct CategorySpecificTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    let category: Category
    let initialStartDate: Date? // 從父視圖傳入
    let initialEndDate: Date?   // 從父視圖傳入

    // 本地日期篩選狀態
    @State private var localFilterStartDate: Date?
    @State private var localFilterEndDate: Date?
    @State private var showingDateFilterSheet = false

    // 編輯交易狀態
    @State private var editingTransaction: Transaction?

    // 1. 先獲取該類別的所有交易
    private var allTransactionsForCategory: [Transaction] {
        dataController.transactions
            .filter { $0.category.id == category.id }
            .sorted { $0.date > $1.date }
    }

    // 2. 然後根據本地日期篩選來過濾
    private var transactionsToDisplay: [Transaction] {
        allTransactionsForCategory.filtered(from: localFilterStartDate, to: localFilterEndDate)
    }
    
    // 篩選狀態描述
    private var filterStatusText: String? {
        guard let start = localFilterStartDate, let end = localFilterEndDate else { return nil }
        if Calendar.current.isDate(start, inSameDayAs: end) { // 如果是同一天
            return "\(DateFormatter.longDate.string(from: start))"
        }
        return "篩選: \(DateFormatter.shortDate.string(from: start)) - \(DateFormatter.shortDate.string(from: end))"
    }
    
    // 篩選後的統計
    private var transactionStats: (count: Int, total: Int) {
        let transactions = transactionsToDisplay
        return (count: transactions.count, total: transactions.reduce(0) { $0 + $1.amount })
    }

    var body: some View {
        List {
            // Section 1: 篩選信息和統計
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let statusText = filterStatusText {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.orange)
                            Spacer()
                            Button("清除") {
                                // 清除本地篩選，會讓列表顯示 initialStartDate/EndDate 或所有
                                self.localFilterStartDate = nil // 或者設回 initialStartDate
                                self.localFilterEndDate = nil   // 或者設回 initialEndDate
                                // 如果希望清除後顯示所有此類別交易，則都設為 nil
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.bottom, 5)
                    }
                    
                    HStack {
                        Text("期間總消費")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(transactionStats.total)")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    Text("共 \(transactionStats.count) 筆交易")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }

            // Section 2: 交易列表
            Section("交易明細") {
                if transactionsToDisplay.isEmpty {
                    // 根據是否有任何交易（忽略日期篩選）來決定顯示哪個空狀態
                    if allTransactionsForCategory.isEmpty {
                        ContentUnavailableView(
                            "尚無交易記錄",
                            systemImage: "list.bullet.clipboard",
                            description: Text("「\(category.name)」類別下還沒有任何交易記錄。")
                        )
                    } else {
                        ContentUnavailableView(
                            "此條件無交易記錄",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("在「\(category.name)」類別下，選定的日期範圍內沒有交易記錄。")
                        )
                    }
                } else {
                    ForEach(transactionsToDisplay) { transaction in
                        Button { // 使用 Button 使整行可點擊以編輯
                            editingTransaction = transaction
                        } label: {
                            // 使用你原來的行 UI
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(transaction.subcategory.name) // 顯示子類別
                                        .fontWeight(.medium)
                                    if let project = transaction.project { // 顯示專案
                                        Text("(\(project.name))")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    }
                                    Spacer()
                                    Text("$\(transaction.amount)")
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text(DateFormatter.shortDate.string(from: transaction.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let note = transaction.note, !note.isEmpty {
                                        Text("• \(note)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.vertical, 6) // 稍微增加行間距
                            .contentShape(Rectangle()) // 確保空白區域可點擊
                        }
                        .buttonStyle(PlainButtonStyle()) // 移除按鈕樣式
                    }
                    .onDelete(perform: deleteTransactions)
                }
            }
        }
        .navigationTitle(category.name) // 標題是類別名稱
        .navigationBarTitleDisplayMode(.large) // 可以根據喜好調整
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingDateFilterSheet = true
                } label: {
                    Image(systemName: localFilterStartDate != nil || localFilterEndDate != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(localFilterStartDate != nil || localFilterEndDate != nil ? .blue : Color.primary)
                }
            }
        }
        .onAppear {
            // 初始化本地篩選日期為從父視圖傳入的日期
            self.localFilterStartDate = initialStartDate
            self.localFilterEndDate = initialEndDate
            print("CategorySpecificTransactionsView appeared for \(category.name). Initial dates: \(String(describing: initialStartDate)) to \(String(describing: initialEndDate))")
        }
        .sheet(isPresented: $showingDateFilterSheet) {
            DateFilterView( // 確保 DateFilterView 已定義
                startDate: $localFilterStartDate,
                endDate: $localFilterEndDate
            )
        }
        .sheet(item: $editingTransaction) { transaction in
            // 確保 EditTransactionView 已定義
            EditTransactionView(transaction: transaction).environmentObject(dataController)
        }
    }
    
    private func deleteTransactions(offsets: IndexSet) {
        withAnimation {
            let transactionsToDelete = offsets.map { transactionsToDisplay[$0] }
            for transaction in transactionsToDelete {
                dataController.deleteTransaction(transaction)
            }
            // dataController.deleteTransaction 應觸發其 transactions 數組更新，
            // 從而使 allTransactionsForCategory 和 transactionsToDisplay 重新計算。
        }
    }
}
