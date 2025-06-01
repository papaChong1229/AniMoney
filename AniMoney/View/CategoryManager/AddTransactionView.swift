// AddTransactionView.swift - 支援多幣種版本

import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var dataController: DataController
    @StateObject private var currencyService = CurrencyService.shared
    @Environment(\.presentationMode) var presentationMode
    
    // 表單狀態
    @State private var amountText = ""
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: Subcategory?
    @State private var selectedProject: Project?
    @State private var transactionNote = ""
    @State private var transactionDate = Date()
    @State private var selectedCurrency: Currency = .twd
    
    // UI 狀態
    @State private var showingCategoryPicker = false
    @State private var showingSubcategoryPicker = false
    @State private var showingProjectPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingCurrencyInfo = false
    
    // 計算轉換後的台幣金額
    private var convertedTWDAmount: Double {
        guard let originalAmount = Double(amountText), originalAmount > 0 else { return 0 }
        return currencyService.convertToTWD(amount: originalAmount, from: selectedCurrency)
    }
    
    // 檢查表單是否有效
    private var isFormValid: Bool {
        !amountText.isEmpty &&
        Double(amountText) != nil &&
        Double(amountText)! > 0 &&
        selectedCategory != nil &&
        selectedSubcategory != nil  // 確保子類別也已選擇
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: - 貨幣選擇區域
                Section(header: Text("貨幣設定")) {
                    // 貨幣選擇器
                    Picker("選擇貨幣", selection: $selectedCurrency) {
                        ForEach(Currency.allCases) { currency in
                            HStack {
                                Text(currency.flag)
                                Text(currency.displayName)
                            }
                            .tag(currency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // 匯率資訊
                    if selectedCurrency != .twd {
                        HStack {
                            Text("匯率")
                            Spacer()
                            Group {
                                if currencyService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("1 TWD = \(currencyService.getDisplayRate(for: selectedCurrency)) \(selectedCurrency.rawValue)")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Button(action: {
                                showingCurrencyInfo = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // 上次更新時間
                        if let lastUpdated = currencyService.lastUpdated {
                            HStack {
                                Text("更新時間")
                                Spacer()
                                Text(DateFormatter.timeOnly.string(from: lastUpdated))
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // MARK: - 金額輸入區域
                Section(header: Text("交易金額")) {
                    HStack {
                        Text(selectedCurrency.flag)
                        TextField("輸入金額", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                        Text(selectedCurrency.rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    // 顯示轉換後的台幣金額（如果不是台幣）
                    if selectedCurrency != .twd && !amountText.isEmpty && convertedTWDAmount > 0 {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                            Text("約等於")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(Currency.twd.formatAmount(convertedTWDAmount))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                // MARK: - 類別選擇
                Section(header: Text("支出類別")) {
                    if let category = selectedCategory {
                        HStack {
                            Text(category.name)
                                .font(.headline)
                            Spacer()
                            Button("更改") {
                                showingCategoryPicker = true
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button("選擇類別") {
                            showingCategoryPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                }

                // MARK: - 子類別選擇
                Section(header: Text("子類別")) {
                    if selectedCategory == nil {
                        Text("請先選擇類別")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else if let subcategory = selectedSubcategory {
                        HStack {
                            Text(subcategory.name)
                                .font(.headline)
                            Spacer()
                            Button("更改") {
                                showingSubcategoryPicker = true
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button("選擇子類別") {
                            showingSubcategoryPicker = true
                        }
                        .foregroundColor(.blue)
                        .disabled(selectedCategory == nil)
                    }
                }

                // MARK: - 專案選擇 (可選)
                Section(header: Text("關聯專案 (可選)")) {
                    if let project = selectedProject {
                        HStack {
                            Text(project.name)
                                .font(.headline)
                            Spacer()
                            Button("更改") {
                                showingProjectPicker = true
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button("選擇專案") {
                            showingProjectPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                }

                // MARK: - 備註
                Section(header: Text("備註 (可選)")) {
                    TextField("輸入備註", text: $transactionNote, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                // MARK: - 交易日期
                Section(header: Text("交易日期")) {
                    DatePicker("選擇日期", selection: $transactionDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                }
                
                // MARK: - 錯誤訊息
                if let errorMessage = currencyService.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("新增支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveTransaction()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory, selectedSubcategory: $selectedSubcategory)
                    .environmentObject(dataController)
            }
            .sheet(isPresented: $showingSubcategoryPicker) {
                SubcategoryPickerView(
                    category: selectedCategory,
                    selectedSubcategory: $selectedSubcategory
                )
                .environmentObject(dataController)
            }
            .sheet(isPresented: $showingProjectPicker) {
                ProjectPickerView(selectedProject: $selectedProject)
                    .environmentObject(dataController)
            }
            .alert("匯率資訊", isPresented: $showingCurrencyInfo) {
                Button("重新整理匯率") {
                    Task {
                        await currencyService.fetchExchangeRates()
                    }
                }
                Button("確認", role: .cancel) { }
            } message: {
                Text("匯率資料每小時自動更新一次。點擊「重新整理匯率」可立即更新最新匯率。")
            }
            .alert("儲存結果", isPresented: $showingAlert) {
                Button("確認") {
                    if !alertMessage.contains("錯誤") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
        .task {
            // 頁面載入時自動更新匯率
            await currencyService.updateRatesIfNeeded()
        }
        .onChange(of: selectedCurrency) { _, _ in
            // 切換貨幣時嘗試更新匯率
            Task {
                await currencyService.updateRatesIfNeeded()
            }
        }
    }

    // MARK: - 儲存交易
    private func saveTransaction() {
        guard let originalAmount = Double(amountText),
              originalAmount > 0,
              let category = selectedCategory,
              let subcategory = selectedSubcategory else {
            alertMessage = "請檢查輸入的金額、類別和子類別"
            showingAlert = true
            return
        }

        // 計算要儲存的台幣金額
        let amountToSave = currencyService.convertToTWD(amount: originalAmount, from: selectedCurrency)
        
        // 使用選擇的 subcategory 直接調用 addTransaction 方法
        dataController.addTransaction(
            category: category,
            subcategory: subcategory,
            amount: Int(round(amountToSave)),
            date: transactionDate,
            note: transactionNote.isEmpty ? nil : transactionNote,
            photoData: nil,
            project: selectedProject
        )

        // 顯示成功訊息
        if selectedCurrency == .twd {
            alertMessage = "成功新增支出記錄"
        } else {
            let originalAmountText = selectedCurrency.formatAmount(originalAmount)
            let convertedAmountText = Currency.twd.formatAmount(amountToSave)
            alertMessage = "成功新增支出記錄\n原始金額：\(originalAmountText)\n台幣金額：\(convertedAmountText)"
        }
        
        showingAlert = true
    }
}

// MARK: - 日期格式化器擴展
extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - 類別選擇器
struct CategoryPickerView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var selectedCategory: Category?
    @Binding var selectedSubcategory: Subcategory?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(dataController.categories, id: \.id) { category in
                    Button(action: {
                        selectedCategory = category
                        selectedSubcategory = nil // 選擇新類別時重置子類別
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(category.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("選擇類別")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 子類別選擇器
struct SubcategoryPickerView: View {
    @EnvironmentObject var dataController: DataController
    let category: Category?
    @Binding var selectedSubcategory: Subcategory?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                if let category = category {
                    ForEach(category.subcategories, id: \.id) { subcategory in
                        Button(action: {
                            selectedSubcategory = subcategory
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(subcategory.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedSubcategory?.id == subcategory.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    
                    if category.subcategories.isEmpty {
                        Text("此類別暫無子類別")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                } else {
                    Text("請先選擇類別")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
            .navigationTitle("選擇子類別")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 專案選擇器
struct ProjectPickerView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var selectedProject: Project?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                // 無專案選項
                Button(action: {
                    selectedProject = nil
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text("無專案")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedProject == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }

                ForEach(dataController.projects, id: \.id) { project in
                    Button(action: {
                        selectedProject = project
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(project.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedProject?.id == project.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("選擇專案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
