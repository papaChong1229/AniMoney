// MARK: - AddRecurringExpenseView 新增固定開銷視圖
import SwiftUI

struct AddRecurringExpenseView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    // 表單狀態
    @State private var name = ""
    @State private var amountText = ""
    @State private var note = ""
    @State private var recurrenceType: RecurrenceType = .monthlyDates
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: Subcategory?
    @State private var selectedProject: Project?
    
    // 每月固定日期設定
    @State private var selectedMonthlyDates: Set<Int> = []
    
    // 固定間隔設定
    @State private var intervalDays = 30
    
    // UI 狀態
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var activeSheet: ActiveSheet?
    
    enum ActiveSheet: Identifiable {
        case categoryPicker
        case subcategoryPicker
        case projectPicker
        
        var id: Int { hashValue }
    }
    
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
                
                // MARK: - 預覽
                if isFormValid {
                    Section(header: Text("預覽")) {
                        RecurringExpensePreview(
                            name: name,
                            amount: Int(amountText) ?? 0,
                            recurrenceType: recurrenceType,
                            monthlyDates: Array(selectedMonthlyDates),
                            intervalDays: intervalDays
                        )
                    }
                }
                
                // MARK: - 儲存按鈕
                Section {
                    Button(action: saveRecurringExpense) {
                        HStack {
                            Spacer()
                            Text("建立固定開銷")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("新增固定開銷")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("建立固定開銷", isPresented: $showingAlert) {
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
    
    // MARK: - 儲存固定開銷
    private func saveRecurringExpense() {
        guard let amount = Double(amountText),
              amount > 0,
              let category = selectedCategory,
              let subcategory = selectedSubcategory else {
            alertMessage = "請檢查所有必填欄位"
            showingAlert = true
            return
        }
        
        dataController.addRecurringExpense(
            name: name,
            amount: Int(amount),
            category: category,
            subcategory: subcategory,
            recurrenceType: recurrenceType,
            monthlyDates: Array(selectedMonthlyDates),
            intervalDays: intervalDays,
            note: note.isEmpty ? nil : note,
            project: selectedProject
        )
        
        alertMessage = "成功建立固定開銷「\(name)」"
        showingAlert = true
    }
}

// MARK: - 每月固定日期選擇器
struct MonthlyDatesSelector: View {
    @Binding var selectedDates: Set<Int>
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("選擇每月的哪幾天")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...31, id: \.self) { day in
                    Button("\(day)") {
                        if selectedDates.contains(day) {
                            selectedDates.remove(day)
                        } else {
                            selectedDates.insert(day)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(selectedDates.contains(day) ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedDates.contains(day) ? .white : .primary)
                    .clipShape(Circle())
                    .font(.caption)
                }
            }
            
            if !selectedDates.isEmpty {
                let sortedDates = selectedDates.sorted()
                Text("已選擇：\(sortedDates.map { "\($0)" }.joined(separator: ", ")) 號")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - 固定間隔選擇器
struct FixedIntervalSelector: View {
    @Binding var intervalDays: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("間隔天數")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("每")
                TextField("天數", value: $intervalDays, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                Text("天執行一次")
            }
            
            // 常用選項
            HStack(spacing: 12) {
                ForEach([7, 14, 30, 60, 90], id: \.self) { days in
                    Button("\(days)天") {
                        intervalDays = days
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(intervalDays == days ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(intervalDays == days ? .white : .primary)
                    .clipShape(Capsule())
                    .font(.caption)
                }
            }
        }
    }
}

// MARK: - 固定開銷預覽
struct RecurringExpensePreview: View {
    let name: String
    let amount: Int
    let recurrenceType: RecurrenceType
    let monthlyDates: [Int]
    let intervalDays: Int
    
    private var nextExecutionDate: Date {
        RecurringExpense.calculateNextExecutionDate(
            type: recurrenceType,
            monthlyDates: monthlyDates,
            intervalDays: intervalDays,
            from: Date()
        )
    }
    
    private var recurrenceDescription: String {
        switch recurrenceType {
        case .monthlyDates:
            if monthlyDates.count == 1 {
                return "每月 \(monthlyDates[0]) 號"
            } else {
                let sortedDates = monthlyDates.sorted()
                return "每月 \(sortedDates.map { "\($0)" }.joined(separator: ", ")) 號"
            }
        case .fixedInterval:
            return "每 \(intervalDays) 天"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.headline)
                Spacer()
                Text("NT$\(amount)")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("週期：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(recurrenceDescription)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("下次執行：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(DateFormatter.shortDate.string(from: nextExecutionDate))
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
