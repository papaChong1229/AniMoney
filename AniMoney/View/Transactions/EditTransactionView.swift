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

    // UI 狀態 - 修正多個 sheet 同時呈現的問題
    @State private var activeSheet: ActiveSheet?
    
    enum ActiveSheet: Identifiable {
        case currencyInfo
        case categoryPicker
        case subcategoryPicker
        case projectPicker
        case camera
        
        var id: Int {
            hashValue
        }
    }

    @State private var showingAlert = false
    @State private var alertMessage = ""

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
                            activeSheet = .currencyInfo
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
                                activeSheet = .categoryPicker
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button("選擇類別") {
                            activeSheet = .categoryPicker
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
                                activeSheet = .subcategoryPicker
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button("選擇子類別") {
                            activeSheet = .subcategoryPicker
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
                                activeSheet = .projectPicker
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        Button("選擇項目") {
                            activeSheet = .projectPicker
                        }
                        .foregroundColor(.blue)
                    }
                }

                // MARK: - 多張照片編輯區域（修復版）
                Section(header: Text("收據照片（可選）")) {
                    VStack(spacing: 16) { // 增加間距，避免按鈕過於接近
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
                                
                                // 修復「移除所有現有照片」按鈕
                                HStack {
                                    Spacer()
                                    Button("移除所有現有照片") {
                                        withAnimation {
                                            existingImages.removeAll()
                                        }
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .buttonStyle(PlainButtonStyle()) // 重要：限制按鈕樣式
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                                    .contentShape(Rectangle()) // 限制點擊區域
                                    Spacer()
                                }
                                .padding(.top, 8) // 與上方內容保持距離
                            }
                            .padding(.bottom, 8) // 與下方按鈕保持距離
                        }
                        
                        // 分隔線
                        if !existingImages.isEmpty && (!newImages.isEmpty || !newPhotoItems.isEmpty) {
                            Divider()
                        }
                        
                        // 照片選擇按鈕區域（修復點擊區域版）
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                // 拍照按鈕 - 完全限制點擊區域
                                Button {
                                    activeSheet = .camera
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.blue)
                                            .font(.subheadline)
                                        Text("拍照")
                                            .foregroundColor(.blue)
                                            .fontWeight(.medium)
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44) // 固定高度
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle()) // 移除預設按鈕樣式
                                .contentShape(RoundedRectangle(cornerRadius: 8)) // 嚴格限制點擊區域
                                .disabled(isLoadingPhotos)
                                
                                // 選擇照片按鈕（PhotosPicker）- 限制點擊區域
                                PhotosPicker(
                                    selection: $newPhotoItems,
                                    maxSelectionCount: 5,
                                    matching: .images
                                ) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo.on.rectangle")
                                            .foregroundColor(.green)
                                            .font(.subheadline)
                                        Text("選擇照片")
                                            .foregroundColor(.green)
                                            .fontWeight(.medium)
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44) // 固定高度
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle()) // 移除預設按鈕樣式
                                .contentShape(RoundedRectangle(cornerRadius: 8)) // 嚴格限制點擊區域
                                .disabled(isLoadingPhotos)
                            }
                            
                            // 載入指示器
                            if isLoadingPhotos {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("載入照片中...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
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
                                
                                // 修復「清除新增照片」按鈕
                                HStack {
                                    Spacer()
                                    Button("清除新增照片") {
                                        clearNewPhotos()
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .buttonStyle(PlainButtonStyle()) // 重要：限制按鈕樣式
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                                    .contentShape(Rectangle()) // 限制點擊區域
                                    Spacer()
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // 照片總數提示
                        let totalPhotoCount = existingImages.count + newImages.count
                        if totalPhotoCount > 0 {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("總共 \(totalPhotoCount) 張照片")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if totalPhotoCount > 5 {
                                    Text("⚠️ 超過建議的5張")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                }

                // MARK: - 備註和日期
                Section(header: Text("詳細資訊")) {
                    TextField("備註（可選）", text: $note)
                    
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
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
        }
        .onAppear {
            initializeFormData()
        }
        // 修正 onChange 回調，防止意外清空現有照片
        .onChange(of: newPhotoItems) { oldValue, newItems in
            // 只在實際有變化時處理
            if oldValue != newItems {
                print("📸 PhotosPicker 選擇變化，當前現有照片數量：\(existingImages.count)")
                Task {
                    await loadNewPhotos(from: newItems)
                }
            }
        }
        // 使用統一的 sheet 管理
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .currencyInfo:
                CurrencyInfoView()
                    .environmentObject(currencyService)
            case .categoryPicker:
                CategoryPickerView(selectedCategory: $selectedCategory, selectedSubcategory: $selectedSubcategory)
                    .environmentObject(dataController)
            case .subcategoryPicker:
                SubcategoryPickerView(
                    category: selectedCategory,
                    selectedSubcategory: $selectedSubcategory
                )
                .environmentObject(dataController)
            case .projectPicker:
                ProjectPickerView(selectedProject: $selectedProject)
                    .environmentObject(dataController)
            case .camera:
                CameraView { image in
                    handleCameraPhoto(image)
                }
            }
        }
    }
    
    // MARK: - 處理拍照結果（修復版）
    private func handleCameraPhoto(_ image: UIImage) {
        print("📸 拍照完成，處理前現有照片數量：\(existingImages.count)")
        
        // 壓縮圖片
        let compressedData = compressImage(image, maxSizeKB: 500)
        if let compressedImage = UIImage(data: compressedData) {
            // 只添加到新照片陣列，不要動現有照片
            newImages.append(compressedImage)
            print("📸 成功添加相機拍攝的照片，目前新照片共 \(newImages.count) 張")
            print("📸 處理後現有照片數量：\(existingImages.count)")
        }
        
        // 關閉 sheet
        activeSheet = nil
    }
    
    // MARK: - 初始化表單數據
    private func initializeFormData() {
        print("🔍 初始化表單數據")
        
        // 初始化基本資料
        amountText = String(transaction.amount)
        selectedCurrency = .twd // 編輯時預設為台幣（因為儲存時已轉換）
        date = transaction.date
        note = transaction.note ?? ""
        
        // 初始化類別選擇
        selectedCategory = transaction.category
        selectedSubcategory = transaction.subcategory
        selectedProject = transaction.project
        
        // 載入現有照片（只在初始化時調用一次）
        loadExistingPhotos()
    }
    
    // MARK: - 載入現有照片（修復版）
    private func loadExistingPhotos() {
        print("🔍 loadExistingPhotos 被調用")
        
        // 清空現有陣列
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
    
    // MARK: - 載入新選擇的照片（修復版）
    @MainActor
    private func loadNewPhotos(from items: [PhotosPickerItem]) async {
        print("📸 開始載入新照片，當前現有照片數量：\(existingImages.count)")
        
        isLoadingPhotos = true
        
        // 只清空新照片陣列
        newImages.removeAll()
        
        for item in items {
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
        print("📸 載入後現有照片數量：\(existingImages.count)")
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

// MARK: - 簡單的相機視圖
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // 相機取消時不做任何事
        }
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
