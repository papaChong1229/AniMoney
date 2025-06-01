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
    
    @State private var categoryForReassignmentSheet: Category?
    @State private var targetCategoryIDForReassignment: PersistentIdentifier?
    
    // 新增一個狀態來控制警告提示
    @State private var showingCannotDeleteAlert = false
    @State private var alertMessage = ""
    
    private var sortedCategories: [Category] {
        dataController.categories.sorted { $0.order < $1.order }
    }
    
    private let estimatedRowHeight: CGFloat = 78
    @State private var listRefreshID = UUID()
    @State private var categoriesForListDisplay: [Category] = []
    
    var body: some View {
        VStack(spacing: 0) {
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

            ScrollView {
                LazyVStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
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
                        
                        Text("類別是支出的主要分類方式。點擊進入管理子類別，左滑刪除類別。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 4)

                        if categoriesForListDisplay.isEmpty {
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
                                ForEach(categoriesForListDisplay) { category in
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
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            self.updateCategoriesForListDisplay()
                                            prepareForCategoryDelete(category) // <--- 調用修改後的函數
                                        } label: {
                                            Label("刪除", systemImage: "trash.fill")
                                        }
                                    }
                                }
                            }
                            .id(listRefreshID)
                            .listStyle(PlainListStyle())
                            .scrollDisabled(true)
                            .frame(minHeight: calculateListHeightForDisplay())
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
                    
                    // ... (分隔線和專案管理區域不變) ...
                    VStack(spacing: 12) {
                        HStack {
                            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                            Image(systemName: "circle.fill").foregroundColor(.secondary.opacity(0.5)).font(.caption2)
                            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                        }.padding(.horizontal, 40)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill").foregroundColor(.purple).font(.title2)
                                Text("專案管理").font(.title2).fontWeight(.bold).foregroundColor(.primary)
                            }
                            Spacer()
                            Text("\(dataController.projects.count) 個專案").font(.caption).foregroundColor(.secondary).padding(.horizontal, 8).padding(.vertical, 4).background(Color.purple.opacity(0.1)).clipShape(Capsule())
                        }.padding(.horizontal)
                        
                        Text("專案讓你追蹤跨類別的相關支出，例如旅行、裝修或特殊活動的花費。").font(.caption).foregroundColor(.secondary).padding(.horizontal).padding(.bottom, 4)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(dataController.projects.sorted { $0.name < $1.name }) { project in
                                ProjectCard(project: project).environmentObject(dataController)
                            }
                            Button { showingAddProjectSheet = true } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(.purple)
                                    Text("新增專案").font(.caption).fontWeight(.medium).foregroundColor(.purple)
                                }.frame(maxWidth: .infinity, minHeight: 80).background(Color.purple.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5])))
                            }.buttonStyle(PlainButtonStyle())
                        }.padding(.horizontal)
                    }.padding(.vertical, 20).background(Color(.systemBackground).opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.2), lineWidth: 1)).padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                            Image(systemName: "circle.fill").foregroundColor(.secondary.opacity(0.5)).font(.caption2)
                            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                        }.padding(.horizontal, 40)
                    }
                    
                    RecurringExpenseSection()
                        .environmentObject(dataController)

                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            updateCategoriesForListDisplay()
            print("CategoryManagerView onAppear. Initializing categoriesForListDisplay.")
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingAddCategorySheet, onDismiss: {
            updateCategoriesForListDisplay()
        }) {
            NavigationView { AddCategoryView().environmentObject(dataController) }
        }
        .sheet(isPresented: $showingAddProjectSheet) {
            NavigationView { AddProjectView().environmentObject(dataController) }
        }
        .sheet(item: $categoryForReassignmentSheet, onDismiss: {
            targetCategoryIDForReassignment = nil
            print("Reassignment sheet dismissed.")
        }) { categoryToActUpon in
            NavigationView {
                ReassignCategoryTransactionsView(
                    categoryToReassignFrom: categoryToActUpon,
                    selectedTargetCategoryID: $targetCategoryIDForReassignment
                ) { success in
                    if success {
                        print("Reassign/Delete successful in callback.")
                        self.updateCategoriesForListDisplay()
                    } else {
                        print("Reassign/Delete cancelled or failed in callback.")
                        // 如果失敗或取消，也可以考慮是否刷新，但通常數據未變則不需要
                    }
                }
                .environmentObject(dataController)
            }
        }
        .alert("無法刪除類別", isPresented: $showingCannotDeleteAlert) { // 新增 Alert
            Button("確認", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onDisappear {
            categoryForReassignmentSheet = nil
            targetCategoryIDForReassignment = nil
        }
    }
    
    private func updateCategoriesForListDisplay() {
        // 這裡的 sortedCategories 應該基於最新的 dataController.categories
        self.categoriesForListDisplay = dataController.categories.sorted { $0.order < $1.order }
        // 同時，也更新 listRefreshID，確保 List 使用新的 displayCategories 重繪
        self.listRefreshID = UUID()
        print("Updated categoriesForListDisplay, count: \(self.categoriesForListDisplay.count), new listRefreshID: \(self.listRefreshID)")
    }
    
    private func calculateListHeight() -> CGFloat {
        let minHeight: CGFloat = estimatedRowHeight
        let calculatedHeight = CGFloat(sortedCategories.count) * estimatedRowHeight
        return max(minHeight, calculatedHeight)
    }
    
    private func calculateListHeightForDisplay() -> CGFloat {
        let minHeight: CGFloat = estimatedRowHeight
        let calculatedHeight = CGFloat(categoriesForListDisplay.count) * estimatedRowHeight
        return max(minHeight, calculatedHeight)
    }
    
    // 重命名，表示準備刪除，實際刪除在 sheet 回調後
   private func prepareForCategoryDelete(_ categoryToDelete: Category) {
       print("Preparing to delete category: \(categoryToDelete.name)")
       let availableTargets = dataController.categories.filter {
           $0.id != categoryToDelete.id && !$0.subcategories.isEmpty
       }
       
       if availableTargets.isEmpty {
           if dataController.categories.count == 1 && dataController.categories.first?.id == categoryToDelete.id {
               if !dataController.hasTransactions(category: categoryToDelete) && categoryToDelete.subcategories.isEmpty {
                   print("Attempting to delete last empty category directly: \(categoryToDelete.name)")
                   dataController.deleteCategory(categoryToDelete) // DataController 應 fetchAll
                   self.updateCategoriesForListDisplay() // 更新顯示並刷新 List

                   self.categoryForReassignmentSheet = nil // 確保 sheet 狀態清除
                   self.targetCategoryIDForReassignment = nil
                   return
               }
           }
           
           self.alertMessage = "無法刪除類別「\(categoryToDelete.name)」..."
           self.showingCannotDeleteAlert = true

           // 重置可能已設定的狀態
           self.targetCategoryIDForReassignment = nil
           self.categoryForReassignmentSheet = nil
           return
       } else {
           self.targetCategoryIDForReassignment = availableTargets.first?.id
           self.categoryForReassignmentSheet = categoryToDelete // 觸發 sheet
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

// MARK: - 固定開銷管理區域組件
struct RecurringExpenseSection: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingRecurringExpenseSheet = false
    @State private var showingAddRecurringExpenseSheet = false
    
    // 計算統計
    private var stats: (total: Int, active: Int, monthlyTotal: Int) {
        dataController.getRecurringExpenseStats()
    }
    
    private var upcomingExpenses: [RecurringExpense] {
        Array(dataController.getUpcomingRecurringExpenses().prefix(3)) // 只顯示前3個
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題和統計
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text("固定開銷")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stats.active)/\(stats.total) 啟用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("月預估 NT$\(stats.monthlyTotal)")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .clipShape(Capsule())
            }
            .padding(.horizontal)
            
            Text("自動管理週期性支出，讓記帳更輕鬆。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            // 即將到期的固定開銷（縮略版）
            if !upcomingExpenses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("即將到期")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        Spacer()
                        Text("7天內")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 6) {
                        ForEach(upcomingExpenses) { expense in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(expense.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Text(expense.nextExecutionDescription)
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                                
                                Spacer()
                                
                                Text("NT$\(expense.amount)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 操作按鈕
            HStack(spacing: 12) {
                // 檢視所有固定開銷
                Button {
                    showingRecurringExpenseSheet = true
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.caption)
                        Text("管理全部")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // 新增固定開銷
                Button {
                    showingAddRecurringExpenseSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("新增固定開銷")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // 立即檢查
                Button {
                    dataController.manualCheckRecurringExpenses()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.caption)
                        Text("立即檢查")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(Color(.systemBackground).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showingRecurringExpenseSheet) {
            RecurringExpenseManagementView()
                .environmentObject(dataController)
        }
        .sheet(isPresented: $showingAddRecurringExpenseSheet) {
            AddRecurringExpenseView()
                .environmentObject(dataController)
        }
    }
}

// MARK: - 固定開銷卡片（縮略版）
struct RecurringExpenseCompactCard: View {
    @EnvironmentObject var dataController: DataController
    let expense: RecurringExpense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(expense.category.name)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                    
                    Text(expense.recurrenceDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("NT$\(expense.amount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(expense.nextExecutionDescription)
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}
