import SwiftUI
import SwiftData

// MARK: - 顯示特定子類別的所有交易
struct SubcategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    let subcategory: Subcategory
    let parentCategory: Category
    
    @State private var editingTransaction: Transaction?
    @State private var showingDateFilter = false
    @State private var filterStartDate: Date?
    @State private var filterEndDate: Date?
    
    // 計算這個子類別的所有交易，按日期排序
    private var allTransactions: [Transaction] {
        dataController.transactions
            .filter { $0.subcategory.id == subcategory.id }
            .sorted { $0.date > $1.date } // 最新的在前面
    }
    
    // 根據篩選條件顯示的交易
    private var transactions: [Transaction] {
        allTransactions.filtered(from: filterStartDate, to: filterEndDate)
    }
    
    // 篩選狀態描述
    private var filterStatusText: String? {
        guard let start = filterStartDate, let end = filterEndDate else { return nil }
        let formatter = DateFormatter.displayFormat
        return "篩選: \(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    var body: some View {
        List {
            // 顯示子類別資訊
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
                        Text("子類別")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(subcategory.name)
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("交易筆數")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(transactions.count) 筆")
                            .font(.subheadline)
                    }
                    
                    if !transactions.isEmpty {
                        HStack {
                            Text("總金額")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$\(transactions.reduce(0) { $0 + $1.amount })")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // 顯示交易列表
            Section("交易記錄") {
                if transactions.isEmpty {
                    ContentUnavailableView(
                        "尚無交易記錄",
                        systemImage: "list.bullet.clipboard",
                        description: Text("這個子類別還沒有任何交易記錄")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(transactions) { transaction in
                        Button {
                            editingTransaction = transaction
                        } label: {
                            HStack {
                                SubcategoryTransactionRow(transaction: transaction)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: deleteTransactions)
                }
            }
        }
        .navigationTitle(subcategory.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $editingTransaction) { transaction in
            EditTransactionView(transaction: transaction)
                .environmentObject(dataController)
        }
        .sheet(isPresented: $showingDateFilter) {
            DateFilterView(
                startDate: $filterStartDate,
                endDate: $filterEndDate
            )
        }
    }
    
    private func deleteTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { transactions[$0] }.forEach { transaction in
                dataController.deleteTransaction(transaction)
            }
        }
    }
}

#Preview {
    NavigationView {
        SubcategoryTransactionsView(
            subcategory: Subcategory(name: "早餐", order: 0),
            parentCategory: Category(name: "食品酒水", order: 0)
        )
        .environmentObject(try! DataController())
    }
}
