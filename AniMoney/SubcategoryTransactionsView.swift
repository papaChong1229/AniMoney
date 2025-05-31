import SwiftUI
import SwiftData

// MARK: - 顯示特定子類別的所有交易
struct SubcategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    let subcategory: Subcategory
    let parentCategory: Category
    
    @State private var editingTransaction: Transaction?
    
    // 計算這個子類別的所有交易，按日期排序
    private var transactions: [Transaction] {
        dataController.transactions
            .filter { $0.subcategory.id == subcategory.id }
            .sorted { $0.date > $1.date } // 最新的在前面
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
                            SubcategoryTransactionRow(transaction: transaction)
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
    }
    
    private func deleteTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { transactions[$0] }.forEach { transaction in
                dataController.deleteTransaction(transaction)
            }
        }
    }
}

// MARK: - 交易列表項目
struct SubcategoryTransactionRow: View {
    let transaction: Transaction
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 日期圓形標籤
            VStack {
                Text(dayFormatter.string(from: transaction.date))
                    .font(.headline)
                    .fontWeight(.bold)
                Text(monthFormatter.string(from: transaction.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 44, height: 44)
            .background(Color.blue.opacity(0.1))
            .clipShape(Circle())
            
            // 交易內容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("$\(transaction.amount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(timeFormatter.string(from: transaction.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                
                if let project = transaction.project {
                    HStack {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                        Text(project.name)
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                // 如果有照片，顯示小圖示
                if transaction.photoData != nil {
                    HStack {
                        Image(systemName: "photo.fill")
                            .font(.caption2)
                        Text("附件")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
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
