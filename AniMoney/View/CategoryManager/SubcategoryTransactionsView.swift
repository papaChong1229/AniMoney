// SubcategoryTransactionsView.swift

import SwiftUI
import SwiftData

// MARK: - 顯示特定子類別的所有交易
struct SubcategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    let subcategory: Subcategory
    let parentCategory: Category
    
    @State private var editingTransaction: Transaction?
    @State private var showingDateFilterSheet = false
    @State private var filterStartDate: Date?
    @State private var filterEndDate: Date?
    
    private var allTransactionsForThisSubcategory: [Transaction] {
        dataController.transactions
            .filter { $0.subcategory.id == subcategory.id }
            .sorted { $0.date > $1.date }
    }
    
    private var transactionsToDisplay: [Transaction] {
        allTransactionsForThisSubcategory.filtered(from: filterStartDate, to: filterEndDate)
    }
    
    private var filterStatusText: String? {
        guard let start = filterStartDate, let end = filterEndDate else { return nil }
        let formatter = DateFormatter.displayFormat
        return "篩選: \(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    private var transactionStats: (count: Int, total: Int) {
        let transactions = transactionsToDisplay
        return (count: transactions.count, total: transactions.reduce(0) { $0 + $1.amount })
    }

    var body: some View {
        VStack(spacing: 0) { // <--- 頂層 VStack
            // MARK: 自定義的頁眉 (類似 CategoryManagerView)
            HStack {
                // 標題文本 (可以根據需要設計得更像大標題)
                VStack(alignment: .leading) {
                    Text(subcategory.name) // 主標題
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer() // 將按鈕推到右邊
                
                Button {
                    showingDateFilterSheet = true
                } label: {
                    Image(systemName: filterStartDate != nil || filterEndDate != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title2) // 調整圖標大小
                        .foregroundColor(filterStartDate != nil || filterEndDate != nil ? .blue : Color.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8) // 根據需要調整頂部間距
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground)) // 與 CategoryManagerView 風格一致

            // 列表內容
            List {
                // Section 1: 子類別資訊和篩選狀態 (現在可以更緊湊，因為標題在上面了)
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("類別")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(parentCategory.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("交易筆數 (篩選後)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(transactionStats.count) 筆")
                                .font(.subheadline)
                        }
                        
                        if !transactionsToDisplay.isEmpty {
                            HStack {
                                Text("總金額 (篩選後)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("$\(transactionStats.total)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if let statusText = filterStatusText {
                            Divider().padding(.vertical, 4)
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.orange)
                                Text(statusText)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Spacer()
                                Button("清除篩選") {
                                    filterStartDate = nil
                                    filterEndDate = nil
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Section 2: 交易列表
                Section(transactionsToDisplay.isEmpty ? "交易記錄" : "交易記錄 (\(transactionsToDisplay.count))") {
                    if transactionsToDisplay.isEmpty {
                        if allTransactionsForThisSubcategory.isEmpty {
                            ContentUnavailableView("尚無交易記錄", systemImage: "list.bullet.clipboard", description: Text("「\(subcategory.name)」還沒有任何交易記錄。"))
                        } else {
                            ContentUnavailableView("此日期範圍無交易", systemImage: "doc.text.magnifyingglass", description: Text("請調整篩選日期或清除篩選。"))
                        }
                    } else {
                        ForEach(transactionsToDisplay) { transaction in
                            Button {
                                editingTransaction = transaction
                            } label: {
                                SubcategoryTransactionRow(transaction: transaction)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onDelete(perform: deleteTransactions)
                    }
                }
            }
        }
        .sheet(item: $editingTransaction, onDismiss: {
            print("EditTransactionView dismissed.")
        }) { transaction in
            // 假設 EditTransactionView 已定義
            EditTransactionView(transaction: transaction)
                .environmentObject(dataController)
        }
        .sheet(isPresented: $showingDateFilterSheet) {
            DateFilterView(
                startDate: $filterStartDate,
                endDate: $filterEndDate
            )
        }
    }
    
    private func deleteTransactions(offsets: IndexSet) {
        withAnimation {
            let transactionsToDelete = offsets.map { transactionsToDisplay[$0] }
            for transaction in transactionsToDelete {
                dataController.deleteTransaction(transaction)
            }
        }
    }
}
