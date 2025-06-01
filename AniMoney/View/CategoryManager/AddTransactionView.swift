import SwiftUI
import PhotosUI

struct AddTransactionView: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var currencyService = CurrencyService.shared
    @Environment(\.presentationMode) var presentationMode

    // 表單狀態
    @State private var amountText = ""
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: Subcategory?
    @State private var selectedProject: Project?
    @State private var transactionNote = ""
    @State private var transactionDate = Date()
    @State private var selectedCurrency: Currency = .twd
    
    // 照片相關狀態
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var selectedImage: UIImage?

    // UI 狀態
    @State private var showingCategoryPicker = false
    @State private var showingSubcategoryPicker = false
    @State private var showingProjectPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingCurrencyInfo = false

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
                // MARK: - 金額輸入
                Section(header: Text("支出金額")) {
                    HStack {
                        TextField("請輸入金額", text: $amountText)
                            .keyboardType(.decimalPad)
                        
                        // 貨幣選擇
                        Picker("貨幣", selection: $selectedCurrency) {
                            ForEach(Currency.allCases, id: \.self) { currency in
                                Text(currency.symbol).tag(currency)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // 顯示台幣等值（如果不是台幣）
                    if selectedCurrency != .twd,
                       let amount = Double(amountText),
                       amount > 0 {
                        let twdAmount = currencyService.convertToTWD(amount: amount, from: selectedCurrency)
                        HStack {
                            Text("台幣等值：")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(Currency.twd.formatAmount(twdAmount))
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                    }
                    
                    // 匯率資訊按鈕
                    if selectedCurrency != .twd {
                        Button("查看匯率資訊") {
                            showingCurrencyInfo = true
                        }
                        .foregroundColor(.blue)
                        .font(.caption)
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

                // MARK: - 項目選擇
                Section(header: Text("項目（可選）")) {
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
                        Button("選擇項目") {
                            showingProjectPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                }

                // MARK: - 照片選擇
                Section(header: Text("收據照片（可選）")) {
                    VStack(spacing: 12) {
                        // 照片選擇按鈕
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.blue)
                                Text("選擇照片")
                                    .foregroundColor(.blue)
                                Spacer()
                                if selectedImage != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // 照片預覽
                        if let image = selectedImage {
                            VStack(spacing: 8) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                                
                                Button("移除照片") {
                                    selectedPhotoItem = nil
                                    selectedPhotoData = nil
                                    selectedImage = nil
                                }
                                .foregroundColor(.red)
                                .font(.caption)
                            }
                        }
                    }
                }

                // MARK: - 備註和日期
                Section(header: Text("詳細資訊")) {
                    TextField("備註（可選）", text: $transactionNote)
                    
                    DatePicker("日期", selection: $transactionDate, displayedComponents: [.date, .hourAndMinute])
                }

                // MARK: - 儲存按鈕
                Section {
                    Button(action: saveTransaction) {
                        HStack {
                            Spacer()
                            Text("儲存支出記錄")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
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
            }
            .alert("支出記錄", isPresented: $showingAlert) {
                Button("確定") {
                    if alertMessage.contains("成功") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingCurrencyInfo) {
                CurrencyInfoView()
                    .environmentObject(currencyService)
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
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await loadSelectedPhoto(from: newItem)
                }
            }
        }
    }

    // MARK: - 加載選中的照片
    @MainActor
    private func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else {
            selectedPhotoData = nil
            selectedImage = nil
            return
        }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // 壓縮照片以節省空間
                if let image = UIImage(data: data) {
                    let compressedData = compressImage(image, maxSizeKB: 500) // 限制在 500KB 內
                    selectedPhotoData = compressedData
                    selectedImage = UIImage(data: compressedData)
                    print("📸 照片載入成功，壓縮後大小: \(compressedData.count / 1024)KB")
                } else {
                    print("❌ 無法轉換照片資料")
                }
            }
        } catch {
            print("❌ 載入照片失敗: \(error)")
        }
    }

    // MARK: - 壓縮圖片
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data {
        let maxBytes = maxSizeKB * 1024
        var quality: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: quality) ?? Data()
        
        // 如果圖片太大，逐步降低品質
        while imageData.count > maxBytes && quality > 0.1 {
            quality -= 0.1
            imageData = image.jpegData(compressionQuality: quality) ?? Data()
        }
        
        // 如果仍然太大，調整圖片尺寸
        if imageData.count > maxBytes {
            let scaleFactor = sqrt(Double(maxBytes) / Double(imageData.count))
            let newSize = CGSize(
                width: image.size.width * scaleFactor,
                height: image.size.height * scaleFactor
            )
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
            
            imageData = resizedImage.jpegData(compressionQuality: 0.8) ?? Data()
        }
        
        return imageData
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
        
        // 使用選擇的 subcategory 和照片資料調用 addTransaction 方法
        dataController.addTransaction(
            category: category,
            subcategory: subcategory,
            amount: Int(round(amountToSave)),
            date: transactionDate,
            note: transactionNote.isEmpty ? nil : transactionNote,
            photoData: selectedPhotoData, // 使用實際的照片資料
            project: selectedProject
        )

        // 顯示成功訊息
        var successMessage = "成功新增支出記錄"
        if selectedCurrency != .twd {
            let originalAmountText = selectedCurrency.formatAmount(originalAmount)
            let convertedAmountText = Currency.twd.formatAmount(amountToSave)
            successMessage += "\n原始金額：\(originalAmountText)\n台幣金額：\(convertedAmountText)"
        }
        if selectedPhotoData != nil {
            successMessage += "\n📸 包含收據照片"
        }
        
        alertMessage = successMessage
        showingAlert = true
    }

    // MARK: - 重置表單（可選功能）
    private func resetForm() {
        amountText = ""
        selectedCategory = nil
        selectedSubcategory = nil
        selectedProject = nil
        transactionNote = ""
        transactionDate = Date()
        selectedCurrency = .twd
        selectedPhotoItem = nil
        selectedPhotoData = nil
        selectedImage = nil
    }
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

// MARK: - 項目選擇器
struct ProjectPickerView: View {
    @EnvironmentObject var dataController: DataController
    @Binding var selectedProject: Project?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                // 無項目選項
                Button(action: {
                    selectedProject = nil
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text("無項目")
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedProject == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // 項目列表
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
            .navigationTitle("選擇項目")
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
