import SwiftUI
import PhotosUI

struct EditTransactionView: View {
    @EnvironmentObject private var dataController: DataController
    @ObservedObject var currencyService = CurrencyService.shared
    @Environment(\.dismiss) private var dismiss

    @Bindable var transaction: Transaction

    // MARK: - Form State
    @State private var amountText: String = ""
    @State private var selectedCurrency: Currency = .twd
    @State private var date: Date = Date()
    @State private var note: String = ""

    // Category & Subcategory & Project selection
    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: Subcategory?
    @State private var selectedProject: Project?

    // 多張照片相關狀態
    @State private var newPhotoItems: [PhotosPickerItem] = []
    @State private var newImages: [UIImage] = []
    @State private var existingImages: [UIImage] = []
    @State private var isLoadingPhotos = false
    
    // 相機相關狀態
    @State private var showingCamera = false

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
        selectedSubcategory != nil
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

                // MARK: - 多張照片編輯區域（改進版）
                Section(header: Text("收據照片（可選）")) {
                    VStack(spacing: 12) {
                        // 顯示現有照片
                        if !existingImages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("現有照片")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(existingImages.count) 張")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(Array(existingImages.enumerated()), id: \.offset) { index, image in
                                        ExistingPhotoCard(
                                            image: image,
                                            index: index,
                                            onRemove: { removeExistingPhoto(at: index) }
                                        )
                                    }
                                }
                                
                                Button("移除所有現有照片") {
                                    withAnimation {
                                        existingImages.removeAll()
                                    }
                                }
                                .foregroundColor(.red)
                                .font(.caption)
                            }
                        }
                        
                        // 分隔線（當有現有照片且要新增照片時）
                        if !existingImages.isEmpty && (!newImages.isEmpty || !newPhotoItems.isEmpty) {
                            Divider()
                        }
                        
                        // 照片選擇選項按鈕
                        HStack(spacing: 12) {
                            // 相簿選擇按鈕
                            PhotosPicker(
                                selection: $newPhotoItems,
                                maxSelectionCount: 5,
                                matching: .images
                            ) {
                                HStack {
                                    Image(systemName: existingImages.isEmpty ? "camera.fill" : "photo.badge.plus")
                                        .foregroundColor(.blue)
                                    Text(existingImages.isEmpty ? "選擇照片" : "新增照片")
                                        .foregroundColor(.blue)
                                    Spacer()
                                    if !newImages.isEmpty {
                                        Text("+\(newImages.count)")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.green)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.vertical, 12)  // 增加垂直填充
                                .padding(.horizontal, 16) // 增加水平填充
                                .frame(maxWidth: .infinity, minHeight: 44) // 確保最小點擊高度
                                .contentShape(Rectangle()) // 明確設定點擊區域為整個矩形
                                .background(Color.blue.opacity(0.05)) // 添加淺色背景便於識別點擊區域
                                .cornerRadius(8) // 圓角
                            }
                            .disabled(isLoadingPhotos)
                            .buttonStyle(PlainButtonStyle()) // 使用純淨按鈕樣式
                            
                            // 相機拍照按鈕
                            Button {
                                showingCamera = true
                            } label: {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.green)
                                    Text("拍照")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(isLoadingPhotos || totalPhotoCount >= 5)
                        }
                        
                        // 載入指示器
                        if isLoadingPhotos {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("處理照片中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // 顯示新選擇的照片
                        if !newImages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("新增照片")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(newImages.count) 張")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(Array(newImages.enumerated()), id: \.offset) { index, image in
                                        NewPhotoCard(
                                            image: image,
                                            index: index,
                                            onRemove: { removeNewPhoto(at: index) }
                                        )
                                    }
                                }
                                
                                Button("清除新增照片") {
                                    clearNewPhotos()
                                }
                                .foregroundColor(.red)
                                .font(.caption)
                            }
                        }
                        
                        // 照片總數提示
                        if totalPhotoCount > 0 {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("總共 \(totalPhotoCount) 張照片")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if totalPhotoCount >= 5 {
                                    Text("已達上限")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                } else {
                                    Text("最多5張")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }

                // MARK: - 備註和日期（移除時間選擇）
                Section(header: Text("詳細資訊")) {
                    TextField("備註（可選）", text: $note)
                    
                    // 只選擇日期，不包含時間
                    DatePicker("日期", selection: $date, displayedComponents: .date)
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
                    .disabled(!isFormValid || isLoadingPhotos)
                }
            }
            .navigationTitle("編輯交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("編輯交易", isPresented: $showingAlert) {
                Button("確定") {
                    if alertMessage.contains("成功") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    addCameraPhoto(image)
                }
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
        }
        .onAppear {
            initializeFormData()
        }
        .onChange(of: newPhotoItems) { _, newItems in
            Task {
                await loadNewPhotos(from: newItems)
            }
        }
    }
    
    // MARK: - 計算屬性
    private var totalPhotoCount: Int {
        existingImages.count + newImages.count
    }
    
    private func calculateMaxSelection() -> Int {
        max(0, 5 - existingImages.count)
    }
    
    // MARK: - 加入相機拍攝的照片
    private func addCameraPhoto(_ image: UIImage) {
        withAnimation {
            // 檢查是否已達到最大數量
            guard totalPhotoCount < 5 else {
                alertMessage = "最多只能選擇 5 張照片"
                showingAlert = true
                return
            }
            
            let compressedData = compressImage(image, maxSizeKB: 500)
            if let compressedImage = UIImage(data: compressedData) {
                newImages.append(compressedImage)
            }
        }
        
        print("📸 成功添加相機拍攝的照片，目前共 \(totalPhotoCount) 張")
    }
    
    // MARK: - 初始化表單數據
    private func initializeFormData() {
        // 初始化基本資料
        amountText = String(transaction.amount)
        selectedCurrency = .twd // 編輯時預設為台幣（因為儲存時已轉換）
        date = transaction.date
        note = transaction.note ?? ""
        
        // 初始化類別選擇
        selectedCategory = transaction.category
        selectedSubcategory = transaction.subcategory
        selectedProject = transaction.project
        
        // 載入現有照片
        loadExistingPhotos()
    }
    
    // MARK: - 載入現有照片
    private func loadExistingPhotos() {
        existingImages.removeAll()
        
        if let photosData = transaction.photosData {
            for photoData in photosData {
                if let image = UIImage(data: photoData) {
                    existingImages.append(image)
                }
            }
        }
        
        print("📸 載入了 \(existingImages.count) 張現有照片")
    }
    
    // MARK: - 載入新選擇的照片
    @MainActor
    private func loadNewPhotos(from items: [PhotosPickerItem]) async {
        isLoadingPhotos = true
        
        // 計算可以加入的照片數量
        let remainingSlots = 5 - existingImages.count
        let itemsToProcess = Array(items.prefix(remainingSlots))
        
        if items.count > remainingSlots {
            alertMessage = "最多只能選擇 5 張照片，已自動選取前 \(remainingSlots) 張"
            showingAlert = true
        }
        
        // 清除之前的新照片
        newImages.removeAll()
        
        for item in itemsToProcess {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    if let image = UIImage(data: data) {
                        let compressedData = compressImage(image, maxSizeKB: 500)
                        if let compressedImage = UIImage(data: compressedData) {
                            newImages.append(compressedImage)
                        }
                    }
                }
            } catch {
                print("❌ 載入新照片失敗: \(error)")
            }
        }
        
        isLoadingPhotos = false
        print("📸 成功載入 \(newImages.count) 張新照片")
    }
    
    // MARK: - 移除現有照片
    private func removeExistingPhoto(at index: Int) {
        guard index < existingImages.count else { return }
        withAnimation {
            existingImages.remove(at: index)
        }
    }
    
    // MARK: - 移除新照片
    private func removeNewPhoto(at index: Int) {
        guard index < newImages.count else { return }
        withAnimation {
            newImages.remove(at: index)
            if index < newPhotoItems.count {
                newPhotoItems.remove(at: index)
            }
        }
    }
    
    // MARK: - 清除新照片
    private func clearNewPhotos() {
        withAnimation {
            newPhotoItems.removeAll()
            newImages.removeAll()
        }
    }
    
    // MARK: - 壓縮圖片
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data {
        let maxBytes = maxSizeKB * 1024
        var quality: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: quality) ?? Data()
        
        while imageData.count > maxBytes && quality > 0.1 {
            quality -= 0.1
            imageData = image.jpegData(compressionQuality: quality) ?? Data()
        }
        
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
    
    // MARK: - 儲存變更
    private func saveChanges() {
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
        
        // 合併現有照片和新照片的資料
        var allPhotosData: [Data] = []
        
        // 加入保留的現有照片
        for existingImage in existingImages {
            if let data = existingImage.jpegData(compressionQuality: 0.8) {
                allPhotosData.append(data)
            }
        }
        
        // 加入新選擇的照片
        for newImage in newImages {
            let compressedData = compressImage(newImage, maxSizeKB: 500)
            allPhotosData.append(compressedData)
        }
        
        // 如果沒有照片，傳 nil
        let finalPhotosData = allPhotosData.isEmpty ? nil : allPhotosData
        
        dataController.updateTransaction(
            transaction,
            category: category,
            subcategory: subcategory,
            amount: Int(round(amountToSave)),
            date: date,
            note: note.isEmpty ? nil : note,
            photosData: finalPhotosData,
            project: selectedProject
        )
        
        // 顯示成功訊息
        var successMessage = "成功更新交易記錄"
        if selectedCurrency != .twd {
            let originalAmountText = selectedCurrency.formatAmount(originalAmount)
            let convertedAmountText = Currency.twd.formatAmount(amountToSave)
            successMessage += "\n原始金額：\(originalAmountText)\n台幣金額：\(convertedAmountText)"
        }
        if !allPhotosData.isEmpty {
            successMessage += "\n📸 包含 \(allPhotosData.count) 張收據照片"
        }
        
        alertMessage = successMessage
        showingAlert = true
    }
}

// MARK: - 現有照片卡片
struct ExistingPhotoCard: View {
    let image: UIImage
    let index: Int
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
                .overlay(
                    // 現有照片標記
                    VStack {
                        Spacer()
                        HStack {
                            Text("原有")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.orange)
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(4)
                    }
                )
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .offset(x: 5, y: -5)
        }
    }
}

// MARK: - 新照片卡片
struct NewPhotoCard: View {
    let image: UIImage
    let index: Int
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
                .overlay(
                    // 新照片標記
                    VStack {
                        Spacer()
                        HStack {
                            Text("新增")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.green)
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(4)
                    }
                )
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .offset(x: 5, y: -5)
        }
    }
}

// MARK: - 相機視圖（共用）
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.onImageCaptured(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.onImageCaptured(originalImage)
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


