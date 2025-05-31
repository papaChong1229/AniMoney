// CategoryManagerView.swift

import SwiftUI
import SwiftData

// MARK: - Main Management View (Top Level Entry Point)
struct MainFinanceManagementView: View {
    @EnvironmentObject var dataController: DataController

    var body: some View {
        NavigationStack {
            CategoryManagerView()
        }
    }
}

struct CategoryManagerView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddCategorySheet = false
    @State private var showingAddProjectSheet = false
    
    // Category 刪除相關狀態
    @State private var categoryToAction: Category?
    @State private var showingCategoryReassignSheet = false
    @State private var targetCategoryIDForReassignment: PersistentIdentifier?
    
    // 計算屬性：排序後的類別
    private var sortedCategories: [Category] {
        dataController.categories.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定義導航欄
            HStack {
                Text("分類管理")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    showingAddCategorySheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            // 主要內容
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 類別管理區域
                    VStack(alignment: .leading, spacing: 16) {
                        // 類別區域標題
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "square.grid.2x2.fill")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                                Text("類別管理")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Text("\(dataController.categories.count) 個類別")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                        
                        // 類別說明
                        Text("類別是支出的主要分類方式。點擊進入管理子類別，左滑刪除類別。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        
                        // 類別列表
                        if dataController.categories.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "square.grid.2x2.slash")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("還沒有任何類別")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("點擊右上角的加號來新增第一個類別")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .padding(.horizontal)
                        } else {
                            List {
                                ForEach(sortedCategories) { category in
                                    NavigationLink(destination: SubcategoryListView(category: category).environmentObject(dataController)) {
                                        HStack {
                                            CategoryListRow(category: category)
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
                                .onDelete(perform: deleteCategories)
                            }
                            .listStyle(PlainListStyle())
                            .scrollDisabled(true)
                            .frame(minHeight: CGFloat(dataController.categories.count * 78))
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
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // 分隔線區域
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
                    
                    // 專案管理區域
                    VStack(alignment: .leading, spacing: 16) {
                        // 專案區域標題
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.purple)
                                    .font(.title2)
                                Text("專案管理")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Text("\(dataController.projects.count) 個專案")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal)
                        
                        // 專案描述
                        Text("專案讓你追蹤跨類別的相關支出，例如旅行、裝修或特殊活動的花費。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        
                        // 專案網格
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(dataController.projects.sorted { $0.name < $1.name }) { project in
                                ProjectCard(project: project)
                                    .environmentObject(dataController)
                            }
                            
                            // 新增專案按鈕
                            Button {
                                showingAddProjectSheet = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                    
                                    Text("新增專案")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.purple)
                                }
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.purple.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                    .background(Color(.systemBackground).opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingAddCategorySheet) {
            NavigationView {
                AddCategoryView()
                    .environmentObject(dataController)
            }
        }
        .sheet(isPresented: $showingAddProjectSheet) {
            NavigationView {
                AddProjectView()
                    .environmentObject(dataController)
            }
        }
        .sheet(isPresented: $showingCategoryReassignSheet) {
            if let category = categoryToAction {
                NavigationView {
                    ReassignCategoryTransactionsView(
                        categoryToReassignFrom: category,
                        selectedTargetCategoryID: $targetCategoryIDForReassignment
                    ) { success in
                        showingCategoryReassignSheet = false
                        if success {
                            print("Category operation completed.")
                        } else {
                            print("Category operation failed/cancelled.")
                        }
                        // 重置狀態
                        categoryToAction = nil
                        targetCategoryIDForReassignment = nil
                    }
                    .environmentObject(dataController)
                }
            } else {
                Text("Category data is no longer available.")
                    .onAppear {
                        showingCategoryReassignSheet = false
                        categoryToAction = nil
                    }
            }
        }
        .onDisappear {
            // 清理狀態
            categoryToAction = nil
            targetCategoryIDForReassignment = nil
        }
    }
    
    // MARK: - 刪除類別邏輯
    private func deleteCategories(offsets: IndexSet) {
        // 只處理第一個要刪除的項目（SwiftUI 的 onDelete 通常一次只刪除一個）
        guard let firstOffset = offsets.first,
              sortedCategories.indices.contains(firstOffset) else { return }
        
        let category = sortedCategories[firstOffset]
        categoryToAction = category
        
        if dataController.hasTransactions(category: category) {
            // 有交易，觸發重新分配流程
            let availableTargets = dataController.categories.filter { $0.id != category.id && !$0.subcategories.isEmpty }
            
            if availableTargets.isEmpty {
                // 沒有可用的目標類別，無法重新分配
                print("❌ 無法刪除類別 '\(category.name)'：沒有其他具有子類別的類別可供重新分配交易")
                // 可以顯示一個提示給用戶
            } else {
                targetCategoryIDForReassignment = availableTargets.first?.id
                showingCategoryReassignSheet = true
            }
        } else {
            // 沒有交易，直接刪除（不顯示確認訊息）
            withAnimation {
                dataController.deleteCategory(category)
            }
            print("✅ 已刪除空類別: \(category.name)")
        }
    }
}

// MARK: - 類別列表行
struct CategoryListRow: View {
    @EnvironmentObject var dataController: DataController
    let category: Category
    
    // 計算類別統計
    private var categoryStats: (transactions: Int, amount: Int) {
        let transactions = dataController.transactions.filter { $0.category.id == category.id }
        return (transactions: transactions.count, amount: transactions.reduce(0) { $0 + $1.amount })
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 類別圖標
            VStack {
                Text(String(category.name.prefix(1)))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            .background(Color.orange)
            .clipShape(Circle())
            
            // 類別信息
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("\(category.subcategories.count) 個子類別")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if categoryStats.transactions > 0 {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(categoryStats.transactions) 筆交易")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if categoryStats.amount > 0 {
                        Text("$\(categoryStats.amount)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // 移除箭頭指示器，因為 NavigationLink 會自動添加
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 專案卡片
struct ProjectCard: View {
    @EnvironmentObject var dataController: DataController
    let project: Project
    
    // 計算專案統計
    private var projectStats: (transactions: Int, amount: Int) {
        let transactions = dataController.transactions.filter { $0.project?.id == project.id }
        return (transactions: transactions.count, amount: transactions.reduce(0) { $0 + $1.amount })
    }
    
    var body: some View {
        NavigationLink(destination: ProjectDetailView(project: project).environmentObject(dataController)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.purple)
                    Spacer()
                    Text("\(projectStats.transactions)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Text(project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text("$\(projectStats.amount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 類別交易視圖
struct CategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    let category: Category
    
    private var categoryTransactions: [Transaction] {
        dataController.transactions
            .filter { $0.category.id == category.id }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List {
            ForEach(categoryTransactions) { transaction in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(transaction.subcategory.name)
                            .fontWeight(.medium)
                        Spacer()
                        Text("$\(transaction.amount)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text(DateFormatter.shortDate.string(from: transaction.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let note = transaction.note {
                            Text("• \(note)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - AddCategoryView, ReassignCategoryTransactionsView
struct AddCategoryView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var categoryName: String = ""

    var body: some View {
        Form {
            TextField("類別名稱", text: $categoryName)
            Button("新增類別") {
                if !categoryName.isEmpty {
                    dataController.addCategory(name: categoryName)
                    dismiss()
                }
            }.disabled(categoryName.isEmpty)
        }
        .navigationTitle("新增類別")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") { dismiss() }
            }
        }
    }
}

struct ReassignCategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let categoryToReassignFrom: Category
    @Binding var selectedTargetCategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void
    var availableTargetCategories: [Category] {
        dataController.categories.filter { $0.id != categoryToReassignFrom.id && !$0.subcategories.isEmpty }
    }

    var body: some View {
        Form {
            Section(header: Text("重新分配 \"\(categoryToReassignFrom.name)\" 的所有交易到：")) {
                if availableTargetCategories.isEmpty {
                    Text("沒有其他具有子類別的類別可供選擇。")
                        .foregroundColor(.orange)
                } else {
                    Picker("目標類別", selection: $selectedTargetCategoryID) {
                        Text("請選擇類別...").tag(nil as PersistentIdentifier?)
                        ForEach(availableTargetCategories) { cat in
                            Text("\(cat.name) (\(cat.subcategories.count) 個子類別)").tag(cat.id as PersistentIdentifier?)
                        }
                    }.labelsHidden()
                }
            }
            Section {
                Button("重新分配並刪除原類別") {
                    handleReassignAndDeleteCategory()
                }.disabled(selectedTargetCategoryID == nil || availableTargetCategories.isEmpty)
            }
        }
        .navigationTitle("選擇目標類別")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    onCompletion(false)
                    dismiss()
                }
            }
        }
        .onAppear {
            if selectedTargetCategoryID == nil, let first = availableTargetCategories.first {
                selectedTargetCategoryID = first.id
            }
        }
    }
    
    private func handleReassignAndDeleteCategory() {
        guard let targetCatID = selectedTargetCategoryID,
              let targetCat = availableTargetCategories.first(where: { $0.id == targetCatID }) else {
            onCompletion(false)
            return
        }
        if dataController.reassignTransactions(from: categoryToReassignFrom, to: targetCat) {
            dataController.deleteCategory(categoryToReassignFrom)
            onCompletion(true)
            dismiss()
        } else {
            onCompletion(false)
        }
    }
}

struct AddProjectView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var projectName: String = ""
    
    var body: some View {
        Form {
            TextField("專案名稱", text: $projectName)
            Button("新增專案") {
                if !projectName.isEmpty {
                    dataController.addProject(name: projectName)
                    dismiss()
                }
            }.disabled(projectName.isEmpty)
        }
        .navigationTitle("新增專案")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") { dismiss() }
            }
        }
    }
}

struct ReassignProjectTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss

    let projectToReassignFrom: Project
    @Binding var selectedTargetProjectID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void

    private let noProjectTag: PersistentIdentifier? = nil

    var availableTargetProjects: [Project] {
        dataController.projects.filter { $0.id != projectToReassignFrom.id }
    }

    var body: some View {
        Form {
            Section(header: Text("重新分配 \"\(projectToReassignFrom.name)\" 的交易到：")) {
                Picker("目標專案", selection: $selectedTargetProjectID) {
                    Text("無專案（清除專案欄位）").tag(noProjectTag)
                    ForEach(availableTargetProjects) { proj in
                        Text(proj.name).tag(proj.id as PersistentIdentifier?)
                    }
                }
            }
            Section {
                Button("套用變更並刪除原專案") {
                    handleReassignAndDeleteProject()
                }
            }
        }
        .navigationTitle("選擇目標專案")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    onCompletion(false)
                    dismiss()
                }
            }
        }
        .onAppear {
            if selectedTargetProjectID == nil {
                selectedTargetProjectID = availableTargetProjects.first?.id ?? noProjectTag
            }
        }
    }

    private func handleReassignAndDeleteProject() {
        var operationSuccess = false
        if let targetID = selectedTargetProjectID {
            if let targetProj = availableTargetProjects.first(where: { $0.id == targetID }) {
                operationSuccess = dataController.reassignTransactions(from: projectToReassignFrom, to: targetProj)
            } else {
                print("Error: Selected target project for reassignment not found.")
                onCompletion(false)
                return
            }
        } else {
            operationSuccess = dataController.clearProjectFromTransactions(of: projectToReassignFrom)
        }

        if operationSuccess {
            dataController.deleteProject(projectToReassignFrom)
            onCompletion(true)
            dismiss()
        } else {
            print("Error: Project transaction operation (reassign to other or nil) failed.")
            onCompletion(false)
        }
    }
}
