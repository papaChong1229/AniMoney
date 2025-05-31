//
//  ProjectDetailView.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/31.
//

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
    
    @State private var selectedTransaction: Transaction?
    @State private var showingEditSheet = false

    // 計算該專案的所有交易，按日期排序
    private var projectTransactions: [Transaction] {
        dataController.transactions
            .filter { $0.project?.id == project.id }
            .sorted { $0.date > $1.date } // 最新的在前面
    }
    
    // 計算該專案的統計資訊
    private var projectStats: (count: Int, total: Int) {
        let transactions = projectTransactions
        return (count: transactions.count, total: transactions.reduce(0) { $0 + $1.amount })
    }
    
    // 計算涉及的類別數量
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
                        
                        // 專案期間（從第一筆到最後一筆交易）
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
                if !projectTransactions.isEmpty {
                    Text("\(projectStats.count) 筆，$\(projectStats.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }) {
                if projectTransactions.isEmpty {
                    ContentUnavailableView(
                        "尚無交易記錄",
                        systemImage: "folder.badge.questionmark",
                        description: Text("這個專案還沒有任何交易記錄")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(projectTransactions) { transaction in
                        Button {
                            selectedTransaction = transaction
                            showingEditSheet = true
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
        .sheet(isPresented: $showingEditSheet) {
            if let transaction = selectedTransaction {
                EditTransactionView(transaction: transaction)
                    .environmentObject(dataController)
            }
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

// MARK: - 專案交易列表項目
struct ProjectTransactionRow: View {
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
            // 日期圓形標籤
            VStack {
                Text(dayFormatter.string(from: transaction.date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(monthFormatter.string(from: transaction.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 36, height: 36)
            .background(Color.purple.opacity(0.1))
            .clipShape(Circle())
            
            // 交易內容
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    // 類別/子類別標籤
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.category.name)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.purple.opacity(0.7))
                            .clipShape(Capsule())
                        
                        Text(transaction.subcategory.name)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(transaction.amount)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(timeFormatter.string(from: transaction.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                
                if transaction.photoData != nil {
                    HStack {
                        Image(systemName: "photo.fill")
                            .font(.caption2)
                        Text("附件")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
