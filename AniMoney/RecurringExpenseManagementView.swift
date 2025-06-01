// MARK: - RecurringExpenseManagementView 固定開銷管理視圖
import SwiftUI

struct RecurringExpenseManagementView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddSheet = false
    @State private var editingExpense: RecurringExpense?
    @State private var showingDeleteAlert = false
    @State private var expenseToDelete: RecurringExpense?
    
    // 計算統計資訊
    private var stats: (total: Int, active: Int, monthlyTotal: Int) {
        dataController.getRecurringExpenseStats()
    }
    
    private var upcomingExpenses: [RecurringExpense] {
        dataController.getUpcomingRecurringExpenses()
    }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - 統計資訊區域
                Section {
                    RecurringExpenseStatsCard(
                        total: stats.total,
                        active: stats.active,
                        monthlyTotal: stats.monthlyTotal,
                        onManualCheck: {
                            dataController.manualCheckRecurringExpenses()
                        }
                    )
                }
                .listRowInsets(EdgeInsets())
                
                // MARK: - 即將到期的固定開銷
                if !upcomingExpenses.isEmpty {
                    Section(header: Text("即將到期（7天內）")) {
                        ForEach(upcomingExpenses) { expense in
                            UpcomingExpenseRow(expense: expense)
                        }
                    }
                }
                
                // MARK: - 所有固定開銷
                Section(header: HStack {
                    Text("所有固定開銷")
                    Spacer()
                    Text("\(dataController.recurringExpenses.count) 個")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }) {
                    if dataController.recurringExpenses.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("還沒有任何固定開銷")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("點擊右上角的加號來新增第一個固定開銷")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(dataController.recurringExpenses) { expense in
                            RecurringExpenseRow(
                                expense: expense,
                                onEdit: { editingExpense = expense },
                                onDelete: {
                                    expenseToDelete = expense
                                    showingDeleteAlert = true
                                },
                                onToggleActive: {
                                    dataController.toggleRecurringExpenseActive(expense)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("固定開銷")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .refreshable {
                dataController.fetchRecurringExpenses()
                dataController.manualCheckRecurringExpenses()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRecurringExpenseView()
                .environmentObject(dataController)
        }
        .sheet(item: $editingExpense) { expense in
            EditRecurringExpenseView(expense: expense)
                .environmentObject(dataController)
        }
        .alert("刪除固定開銷", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                if let expense = expenseToDelete {
                    dataController.deleteRecurringExpense(expense)
                }
            }
        } message: {
            if let expense = expenseToDelete {
                Text("確定要刪除固定開銷「\(expense.name)」嗎？此操作無法復原。")
            }
        }
        .onAppear {
            dataController.fetchRecurringExpenses()
        }
    }
}

// MARK: - 固定開銷統計卡片
struct RecurringExpenseStatsCard: View {
    let total: Int
    let active: Int
    let monthlyTotal: Int
    let onManualCheck: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("固定開銷管理")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("自動管理您的固定支出")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("立即檢查") {
                    onManualCheck()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
            }
            
            HStack(spacing: 20) {
                StatItem(title: "總數", value: "\(total)", color: .blue)
                StatItem(title: "啟用中", value: "\(active)", color: .green)
                StatItem(title: "月預估", value: "NT$\(monthlyTotal)", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - 統計項目
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 即將到期的固定開銷行
struct UpcomingExpenseRow: View {
    let expense: RecurringExpense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(expense.recurrenceDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("NT$\(expense.amount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(expense.nextExecutionDescription)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 固定開銷行
struct RecurringExpenseRow: View {
    let expense: RecurringExpense
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleActive: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(expense.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(expense.isActive ? .primary : .secondary)
                        
                        if !expense.isActive {
                            Text("已停用")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.secondary)
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack {
                        Text(expense.category.name)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                        
                        Text(expense.subcategory.name)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        
                        if let project = expense.project {
                            Text(project.name)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.2))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("NT$\(expense.amount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(expense.isActive ? .primary : .secondary)
                    
                    Text(expense.recurrenceDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("下次：\(expense.nextExecutionDescription)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastExecution = expense.lastExecutionDate {
                    Text("• 上次：\(DateFormatter.shortDate.string(from: lastExecution))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 操作按鈕
                HStack(spacing: 8) {
                    Button {
                        onToggleActive()
                    } label: {
                        Image(systemName: expense.isActive ? "pause.circle" : "play.circle")
                            .foregroundColor(expense.isActive ? .orange : .green)
                    }
                    
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                    }
                    
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash.circle")
                            .foregroundColor(.red)
                    }
                }
                .font(.title3)
            }
            
            if let note = expense.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}

// MARK: - 編輯固定開銷視圖
struct EditRecurringExpenseView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @Bindable var expense: RecurringExpense
    
    // 表單狀態
    @State private var name = ""
    @State private var amountText = ""
    @State private var note = ""
    @State private var recurrenceType: RecurrenceType = .monthlyDates
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: Subcategory?
    @State private var selectedProject: Project?
    @State private var selectedMonthlyDates: Set<Int> = []
    @State private var intervalDays = 30
    @State private var isActive = true
    
    // UI 狀態
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var activeSheet: AddRecurringExpenseView.ActiveSheet?
    
    // 表單驗證
    private var isFormValid: Bool {
        !name.isEmpty &&
        !amountText.isEmpty &&
        Double(amountText) != nil &&
        Double(amountText)! > 0 &&
        selectedCategory != nil &&
        selectedSubcategory != nil &&
        isRecurrenceValid
    }
    
    private var isRecurrenceValid: Bool {
        switch recurrenceType {
        case .monthlyDates:
            return !selectedMonthlyDates.isEmpty
        case .fixedInterval:
            return intervalDays > 0
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - 基本資訊
                Section(header: Text("基本資訊")) {
                    TextField("固定開銷名稱", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    HStack {
                        Text("NT$")
                            .foregroundColor(.secondary)
                        TextField("金額", text: $amountText)
                            .keyboardType(.numberPad)
                    }
                    
                    TextField("備註（可選）", text: $note)
                        .textInputAutocapitalization(.sentences)
                    
                    Toggle("啟用此固定開銷", isOn: $isActive)
                        .tint(.blue)
                }
                
                // MARK: - 類別選擇
                Section(header: Text("支出分類")) {
                    // 主類別
                    if let category = selectedCategory {
                        HStack {
                            Text("類別")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(category.name)
                                .foregroundColor(.primary)
                            Button("更改") {
                                activeSheet = .categoryPicker
                            }
                            .foregroundColor(.blue)
                            .font(.caption)
                        }
                    } else {
                        Button("選擇類別") {
                            activeSheet = .categoryPicker
                        }
                        .foregroundColor(.blue)
                    }
                    
                    // 子類別
                    if selectedCategory == nil {
                        Text("請先選擇類別")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else if let subcategory = selectedSubcategory {
                        HStack {
                            Text("子類別")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(subcategory.name)
                                .foregroundColor(.primary)
                            Button("更改") {
                                activeSheet = .subcategoryPicker
                            }
                            .foregroundColor(.blue)
                            .font(.caption)
                        }
                    } else {
                        Button("選擇子類別") {
                            activeSheet = .subcategoryPicker
                        }
                        .foregroundColor(.blue)
                        .disabled(selectedCategory == nil)
                    }
                }
                
                // MARK: - 專案選擇
                Section(header: Text("專案（可選）")) {
                    if let project = selectedProject {
                        HStack {
                            Text(project.name)
                                .foregroundColor(.primary)
                            Spacer()
                            Button("更改") {
                                activeSheet = .projectPicker
                            }
                            .foregroundColor(.blue)
                            .font(.caption)
                        }
                    } else {
                        Button("選擇專案") {
                            activeSheet = .projectPicker
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // MARK: - 週期設定
                Section(header: Text("週期設定")) {
                    Picker("週期類型", selection: $recurrenceType) {
                        ForEach(RecurrenceType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    switch recurrenceType {
                    case .monthlyDates:
                        MonthlyDatesSelector(selectedDates: $selectedMonthlyDates)
                    case .fixedInterval:
                        FixedIntervalSelector(intervalDays: $intervalDays)
                    }
                }
                
                // MARK: - 儲存按鈕
                Section {
                    Button(action: saveChanges) {
                        HStack {
                            Spacer()
                            Text("儲存變更")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("編輯固定開銷")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("編輯固定開銷", isPresented: $showingAlert) {
                Button("確定") {
                    if alertMessage.contains("成功") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: selectedCategory) { _, _ in
                selectedSubcategory = nil
            }
        }
        .onAppear {
            initializeFormData()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .categoryPicker:
                CategoryPickerView(selectedCategory: $selectedCategory, selectedSubcategory: $selectedSubcategory)
                    .environmentObject(dataController)
            case .subcategoryPicker:
                SubcategoryPickerView(category: selectedCategory, selectedSubcategory: $selectedSubcategory)
                    .environmentObject(dataController)
            case .projectPicker:
                ProjectPickerView(selectedProject: $selectedProject)
                    .environmentObject(dataController)
            }
        }
    }
    
    // MARK: - 初始化表單資料
    private func initializeFormData() {
        name = expense.name
        amountText = String(expense.amount)
        note = expense.note ?? ""
        recurrenceType = expense.recurrenceType
        selectedCategory = expense.category
        selectedSubcategory = expense.subcategory
        selectedProject = expense.project
        selectedMonthlyDates = Set(expense.monthlyDates)
        intervalDays = expense.intervalDays
        isActive = expense.isActive
    }
    
    // MARK: - 儲存變更
    private func saveChanges() {
        guard let amount = Double(amountText),
              amount > 0,
              let category = selectedCategory,
              let subcategory = selectedSubcategory else {
            alertMessage = "請檢查所有必填欄位"
            showingAlert = true
            return
        }
        
        dataController.updateRecurringExpense(
            expense,
            name: name,
            amount: Int(amount),
            category: category,
            subcategory: subcategory,
            recurrenceType: recurrenceType,
            monthlyDates: Array(selectedMonthlyDates),
            intervalDays: intervalDays,
            note: note.isEmpty ? nil : note,
            project: selectedProject,
            isActive: isActive
        )
        
        alertMessage = "成功更新固定開銷「\(name)」"
        showingAlert = true
    }
}
