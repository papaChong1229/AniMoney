// SubcategoryListView.swift - 完整修復版本

import SwiftUI
import SwiftData

struct SubcategoryListView: View {
    @EnvironmentObject var dataController: DataController
    let category: Category
    @State private var showingAddSubcategorySheet = false
    
    // Subcategory 刪除相關狀態
    @State private var subcategoryToAction: Subcategory?
    @State private var showingSubcategoryReassignSheet = false
    @State private var targetSubcategoryIDForReassignment: PersistentIdentifier?
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定義導航欄
            HStack {
                Text(category.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    showingAddSubcategorySheet = true
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
                    // 子類別管理區域
                    SubcategoryManagementSection(
                        category: category,
                        onDeleteRequest: { subcategory in
                            handleSubcategoryDeleteRequest(subcategory)
                        }
                    )
                    .environmentObject(dataController)
                }
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddSubcategorySheet) {
            NavigationView {
                AddSubcategoryView(category: category)
                    .environmentObject(dataController)
            }
        }
        .sheet(isPresented: $showingSubcategoryReassignSheet) {
            if let subcategory = subcategoryToAction {
                NavigationView {
                    ReassignSubcategoryTransactionsView(
                        subcategoryToReassignFrom: subcategory,
                        parentCategory: category,
                        selectedTargetSubcategoryID: $targetSubcategoryIDForReassignment
                    ) { success in
                        showingSubcategoryReassignSheet = false
                        if success {
                            print("✅ 子類別重新分配完成")
                        } else {
                            print("❌ 子類別重新分配失敗或取消")
                        }
                    }
                    .environmentObject(dataController)
                }
            } else {
                Text("子類別資料不再可用")
                    .onAppear {
                        showingSubcategoryReassignSheet = false
                    }
            }
        }
    }
    
    // MARK: - 處理子類別刪除請求
    private func handleSubcategoryDeleteRequest(_ subcategory: Subcategory) {
        subcategoryToAction = subcategory
        
        if dataController.hasTransactions(subcategory: subcategory) {
            // 有交易，觸發重新分配流程
            let availableTargets = category.subcategories.filter { $0.id != subcategory.id }
            targetSubcategoryIDForReassignment = availableTargets.first?.id
            showingSubcategoryReassignSheet = true
        } else {
            // 沒有交易，直接刪除（不顯示確認訊息）
            withAnimation {
                dataController.deleteSubcategory(subcategory)
            }
            print("✅ 已刪除空子類別: \(subcategory.name)")
        }
    }
}

// MARK: - 修復後的子類別管理區域
struct SubcategoryManagementSection: View {
    @EnvironmentObject var dataController: DataController
    let category: Category
    let onDeleteRequest: (Subcategory) -> Void
    
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
            Text("子類別讓你更精確地分類 \"\(category.name)\" 下的不同支出類型。點擊進入詳情，左滑刪除。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            // 子類別列表
            if category.subcategories.isEmpty {
                SubcategoryEmptyState()
                    .padding(.horizontal)
            } else {
                List {
                    ForEach(category.subcategories.sorted { $0.order < $1.order }) { subcategory in
                        NavigationLink(destination: SubcategoryTransactionsView(subcategory: subcategory, parentCategory: category).environmentObject(dataController)) {
                            HStack {
                                SubcategoryListRow(subcategory: subcategory)
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
                    .onDelete(perform: { offsets in
                        deleteSubcategories(offsets: offsets)
                    })
                }
                .listStyle(PlainListStyle())
                .scrollDisabled(true)
                .frame(minHeight: CGFloat(category.subcategories.count * 70))
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
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - 刪除子類別邏輯
    private func deleteSubcategories(offsets: IndexSet) {
        let subcategoriesToDelete = offsets.map { category.subcategories.sorted { $0.order < $1.order }[$0] }
        
        for subcategory in subcategoriesToDelete {
            onDeleteRequest(subcategory)
        }
    }
}

// MARK: - 修復後的子類別列表行（移除重複箭頭）
struct SubcategoryListRow: View {
    @EnvironmentObject var dataController: DataController
    let subcategory: Subcategory
    
    // 計算子類別統計
    private var subcategoryStats: (transactions: Int, amount: Int) {
        let transactions = dataController.transactions.filter { $0.subcategory.id == subcategory.id }
        return (transactions: transactions.count, amount: transactions.reduce(0) { $0 + $1.amount })
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 子類別圖標
            VStack {
                Text(String(subcategory.name.prefix(1)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)
            .background(Color.blue)
            .clipShape(Circle())
            
            // 子類別信息
            VStack(alignment: .leading, spacing: 4) {
                Text(subcategory.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("\(subcategoryStats.transactions) 筆交易")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if subcategoryStats.amount > 0 {
                        Text("$\(subcategoryStats.amount)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // 移除箭頭指示器，因為 NavigationLink 會自動添加
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 子類別重新分配視圖
struct ReassignSubcategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    let subcategoryToReassignFrom: Subcategory
    let parentCategory: Category
    @Binding var selectedTargetSubcategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void
    
    var availableTargetSubcategories: [Subcategory] {
        parentCategory.subcategories.filter { $0.id != subcategoryToReassignFrom.id }
    }
    
    var body: some View {
        Form {
            Section(header: Text("重新分配 \"\(subcategoryToReassignFrom.name)\" 的所有交易到：")) {
                if availableTargetSubcategories.isEmpty {
                    Text("沒有其他子類別可供選擇。")
                        .foregroundColor(.orange)
                } else {
                    Picker("目標子類別", selection: $selectedTargetSubcategoryID) {
                        Text("請選擇子類別...").tag(nil as PersistentIdentifier?)
                        ForEach(availableTargetSubcategories) { subcat in
                            Text(subcat.name).tag(subcat.id as PersistentIdentifier?)
                        }
                    }
                    .labelsHidden()
                }
            }
            
            Section {
                Button("重新分配並刪除原子類別") {
                    handleReassignAndDeleteSubcategory()
                }
                .disabled(selectedTargetSubcategoryID == nil || availableTargetSubcategories.isEmpty)
            }
        }
        .navigationTitle("選擇目標子類別")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    onCompletion(false)
                    dismiss()
                }
            }
        }
        .onAppear {
            if selectedTargetSubcategoryID == nil, let first = availableTargetSubcategories.first {
                selectedTargetSubcategoryID = first.id
            }
        }
    }
    
    private func handleReassignAndDeleteSubcategory() {
        guard let targetSubcatID = selectedTargetSubcategoryID,
              let targetSubcat = availableTargetSubcategories.first(where: { $0.id == targetSubcatID }) else {
            onCompletion(false)
            return
        }
        
        if dataController.reassignTransactions(from: subcategoryToReassignFrom, to: targetSubcat) {
            dataController.deleteSubcategory(subcategoryToReassignFrom)
            onCompletion(true)
            dismiss()
        } else {
            onCompletion(false)
        }
    }
}

// MARK: - 新增子類別視圖
struct AddSubcategoryView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let category: Category
    @State private var subcategoryName: String = ""
    
    var body: some View {
        Form {
            TextField("子類別名稱", text: $subcategoryName)
            
            Button("新增子類別") {
                if !subcategoryName.isEmpty {
                    dataController.addSubcategory(to: category, name: subcategoryName)
                    dismiss()
                }
            }
            .disabled(subcategoryName.isEmpty)
        }
        .navigationTitle("新增子類別")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") { dismiss() }
            }
        }
    }
}

// MARK: - 空狀態視圖
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
    }
}
