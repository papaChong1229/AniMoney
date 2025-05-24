//
//  HomePageView.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/21.
//

import SwiftUI
import SwiftData

struct HomePageView: View {
    // 從環境中獲取 DataController
    @EnvironmentObject var dataController: DataController
    // 如果需要手動操作 context（例如刪除），仍然可以獲取
    // @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView { // 或者 NavigationStack
            VStack {
                // 使用 dataController.transactions
                if dataController.transactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions Yet",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Tap the '+' button to add your first transaction.")
                    )
                } else {
                    List {
                        // 對 dataController.transactions 進行排序，如果 DataController 中的 fetchAll 沒有排序的話
                        // 或者確保 DataController.fetchAll() 獲取時已經排序
                        // 這裡假設 DataController.transactions 已經是期望的順序 (例如，fetchAll 中 sortBy date reverse)
                        ForEach(dataController.transactions) { tx in
                            TransactionRow(transaction: tx)
                        }
                        // 如果需要刪除功能，可以添加 .onDelete
                        // .onDelete(perform: deleteTransactionsViaDataController)
                    }
                }
            }
            .navigationTitle("All Transactions")
            // .toolbar {
            //     ToolbarItem(placement: .navigationBarTrailing) {
            //         Button {
            //             // 導航到 AddTransactionView 或彈出 Sheet
            //             // 動作應該是調用 DataController 的方法
            //         } label: {
            //             Label("Add Transaction", systemImage: "plus.circle.fill")
            //         }
            //     }
            // }
            // .onAppear {
            //     // 如果需要在視圖出現時強制刷新 (通常 DataController 的 @Published 會自動處理)
            //     // dataController.fetchAll()
            // }
        }
    }

    // 範例：通過 DataController 刪除交易
    // func deleteTransactionsViaDataController(offsets: IndexSet) {
    //     withAnimation {
    //         offsets.map { dataController.transactions[$0] }.forEach { transaction in
    //             dataController.deleteTransaction(transaction) // DataController 內部會調用 save 和 fetchAll
    //         }
    //     }
    // }
}

// TransactionRow 保持不變
struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(transaction.category.name) / \(transaction.subcategory.name)")
                    .font(.headline)
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                if let project = transaction.project {
                    Text("Project: \(project.name)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            Spacer()
            Text("\(transaction.amount)")
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomePageView()
}
