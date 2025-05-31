import SwiftUI
import SwiftData

// MARK: - Project Views (增強版專案詳情頁面)
struct ProjectDetailView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @Bindable var project: Project

    @State private var showingConfirmDirectDeleteProjectDialog = false
    @State private var showingReassignProjectSheet = false
    @State private var targetProjectIDForReassignment: PersistentIdentifier? // Can be nil for "No Project"
    
    @State private var editingTransaction: Transaction?
    @State private var showingDateFilter = false
    @State private var filterStartDate: Date?
    @State private var filterEndDate: Date?

    // 計算該專案的所有交易，按日期排序
    private var allProjectTransactions: [Transaction] {
        dataController.transactions
            .filter { $0.project?.id == project.id }
            .sorted { $0.date > $1.date } // 最新的在前面
    }
    
    // 根據篩選條件顯示的交易
    private var projectTransactions: [Transaction] {
        allProjectTransactions.filtered(from: filterStartDate, to: filterEndDate)
    }
    
    // 篩選狀態描述
    private var filterStatusText: String? {
        guard let start = filterStartDate, let end = filterEndDate else { return nil }
        let formatter = DateFormatter.displayFormat
        return "篩選: \(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    // 計算該專案的統計資訊（使用篩選後的數據）
    private var projectStats: (count: Int, total: Int) {
        let transactions = projectTransactions
        return (count: transactions.count, total: transactions.reduce(0) { $0 + $1.amount })
    }
    
    // 計算涉及的類別數量（使用篩選後的數據）
    private var involvedCategoriesCount: Int {
        Set(projectTransactions.map { $0.category.id }).count
    }

    var body: some View {
        List {
            // 專案統計資訊卡片
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("專案名稱")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(project.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("涉及類別")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(involvedCategoriesCount) 個")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("交易筆數")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(projectStats.count) 筆")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    if projectStats.count > 0 {
                        HStack {
                            Text("總金額")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$\(projectStats.total)")
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
                            Text("$\(projectStats.count > 0 ? projectStats.total / projectStats.count : 0)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        // 專案期間（從第一筆到最後一筆交易）- 使用篩選後的數據
                        if let firstDate = projectTransactions.last?.date,
                           let lastDate = projectTransactions.first?.date {
                            HStack {
                                Text("專案期間")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(DateFormatter.shortDate.string(from: firstDate))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("至")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(DateFormatter.shortDate.string(from: lastDate))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // 專案交易記錄
            Section(header: HStack {
                Text("專案交易記錄")
                Spacer()
                HStack(spacing: 8) {
                    if !projectTransactions.isEmpty {
                        Text("\(projectStats.count) 筆，$\(projectStats.total)")
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
                
                if projectTransactions.isEmpty {
                    if allProjectTransactions.isEmpty {
                        ContentUnavailableView(
                            "尚無交易記錄",
                            systemImage: "folder.badge.questionmark",
                            description: Text("這個專案還沒有任何交易記錄")
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
                    ForEach(projectTransactions) { transaction in
                        Button {
                            editingTransaction = transaction
                        } label: {
                            ProjectTransactionRow(transaction: transaction)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete(perform: deleteProjectTransactions)
                }
            }
            
            // 專案管理操作
            Section("專案管理") {
                Button("刪除專案", role: .destructive) {
                    if dataController.hasTransactions(project: project) {
                        targetProjectIDForReassignment = dataController.projects.first(where: { $0.id != project.id })?.id // Pre-select or default to nil in sheet
                        self.showingReassignProjectSheet = true
                    } else {
                        self.showingConfirmDirectDeleteProjectDialog = true
                    }
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
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
        .confirmationDialog("Delete Project: \"\(project.name)\"?", isPresented: $showingConfirmDirectDeleteProjectDialog) {
            Button("Delete Project", role: .destructive) {
                dataController.deleteProject(project)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure? \"\(project.name)\" has no transactions.")
        }
        .sheet(isPresented: $showingReassignProjectSheet) {
            // Ensure 'project' is still valid (e.g., not deleted by another process if app is complex)
             if let currentProject = dataController.projects.first(where: {$0.id == project.id}) {
                 ReassignProjectTransactionsView(projectToReassignFrom: currentProject, selectedTargetProjectID: $targetProjectIDForReassignment) { success in
                    showingReassignProjectSheet = false
                    if success { print("Project operation completed."); dismiss() } else { print("Project operation failed/cancelled.") }
                 }.environmentObject(dataController)
             } else {
                 // Handle case where project might have been deleted in the meantime
                 Text("Project data is no longer available.")
                     .onAppear {
                         showingReassignProjectSheet = false // Dismiss sheet if project is gone
                         dismiss() // Dismiss detail view
                     }
             }
        }
        .sheet(item: $editingTransaction) { transaction in
            EditTransactionView(transaction: transaction)
                .environmentObject(dataController)
        }
    }
    
    // 刪除專案交易
    private func deleteProjectTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { projectTransactions[$0] }.forEach { transaction in
                dataController.deleteTransaction(transaction)
            }
        }
    }
}
