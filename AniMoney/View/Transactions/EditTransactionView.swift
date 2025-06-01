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

    // 照片管理狀態 - 採用類似 AddTransactionView 的分離方式
    @State private var selectedPhotoItems: [PhotosPickerItem] = [] // PhotosPicker 需要的狀態
    @State private var cameraImages: [UIImage] = [] // 拍照的照片
    @State private var cameraPhotosData: [Data] = [] // 拍照的照片數據
    @State private var pickerImages: [UIImage] = [] // 相簿選擇的照片
    @State private var pickerPhotosData: [Data] = [] // 相簿選擇的照片數據
    @State private var existingImages: [UIImage] = [] // 原有照片
    @State private var existingPhotosData: [Data] = [] // 原有照片數據
    @State private var isLoadingPhotos = false

    // 計算屬性：合併所有照片
    private var allImages: [UIImage] {
        return existingImages + cameraImages + pickerImages
    }
    
    private var allPhotosData: [Data] {
        return existingPhotosData + cameraPhotosData + pickerPhotosData
    }

    // UI 狀態 - 統一的 sheet 管理
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
                    VStack(spacing: 16) {
                        // 原有照片區域
                        if !existingImages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("原有照片")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(existingImages.count) 張")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    ForEach(Array(existingImages.enumerated()), id: \.offset) { index, image in
                                        ExistingPhotoCard(
                                            image: image,
                                            index: index,
                                            onRemove: { removeExistingPhoto(at: index) }
                                        )
                                        .id("existing-\(index)")
                                    }
                                }
                            }
                        }
                        
                        // 拍照的照片區域
                        if !cameraImages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("拍照 (\(cameraImages.count) 張)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    ForEach(Array(cameraImages.enumerated()), id: \.offset) { index, image in
                                        CameraPhotoCard(
                                            image: image,
                                            index: index,
                                            onRemove: { removeCameraPhoto(at: index) }
                                        )
                                        .id("camera-\(index)")
                                    }
                                }
                            }
                        }
                        
                        // 相簿選擇的照片區域
                        if !pickerImages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("相簿 (\(pickerImages.count) 張)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Spacer()
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    ForEach(Array(pickerImages.enumerated()), id: \.offset) { index, image in
                                        PickerPhotoCard(
                                            image: image,
                                            index: index,
                                            onRemove: { removePickerPhoto(at: index) }
                                        )
                                        .id("picker-\(index)")
                                    }
                                }
                            }
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
                                    selection: $selectedPhotoItems,
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
                        
                        // 修復「清除所有照片」按鈕
                        if !allImages.isEmpty {
                            HStack {
                                Spacer()
                                Button("清除所有照片") {
                                    clearAllPhotos()
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
                        
                        // 照片數量提示
                        if !allImages.isEmpty {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("總共 \(allImages.count) 張照片")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if allImages.count >= 5 {
                                    Text("已達上限")
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
                    
                    DatePicker("日期", selection: $date, displayedComponents: [.date])
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
        .onChange(of: selectedPhotoItems) { _, newItems in
            Task {
                await loadSelectedPhotos(from: newItems)
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
    
    // MARK: - 處理拍照結果
    private func handleCameraPhoto(_ image: UIImage) {
        print("📸 拍照完成，添加到拍照照片列表")
        
        // 壓縮圖片
        let compressedData = compressImage(image, maxSizeKB: 500)
        
        // 添加到拍照陣列
        cameraImages.append(image)
        cameraPhotosData.append(compressedData)
        
        print("📸 成功添加相機拍攝的照片，拍照總數: \(cameraImages.count)，總照片數: \(allImages.count)")
        
        // 關閉 sheet
        activeSheet = nil
    }
    
    // MARK: - 載入相簿選擇的照片（修復版 - 只替換相簿照片）
    @MainActor
    private func loadSelectedPhotos(from items: [PhotosPickerItem]) async {
        print("📸 開始載入相簿選擇的照片，當前拍照 \(cameraImages.count) 張，相簿 \(pickerImages.count) 張")
        
        guard !items.isEmpty else {
            print("📸 沒有選擇任何照片，清空相簿照片")
            pickerImages.removeAll()
            pickerPhotosData.removeAll()
            return
        }
        
        isLoadingPhotos = true
        
        // 清空相簿照片（但保留拍照照片和原有照片）
        pickerImages.removeAll()
        pickerPhotosData.removeAll()
        
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    if let image = UIImage(data: data) {
                        let compressedData = compressImage(image, maxSizeKB: 500)
                        pickerPhotosData.append(compressedData)
                        pickerImages.append(image)
                    }
                }
            } catch {
                print("❌ 載入相簿照片失敗: \(error)")
            }
        }
        
        isLoadingPhotos = false
        print("📸 成功載入 \(pickerImages.count) 張相簿照片，總照片數: \(allImages.count) 張")
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
        existingPhotosData.removeAll()
        
        if let photosData = transaction.photosData {
            for photoData in photosData {
                if let image = UIImage(data: photoData) {
                    existingImages.append(image)
                    existingPhotosData.append(photoData)
                }
            }
        }
        
        print("📸 載入了 \(existingImages.count) 張現有照片")
    }

    // MARK: - 移除現有照片
    private func removeExistingPhoto(at index: Int) {
        guard index < existingImages.count else { return }
        
        withAnimation {
            existingImages.remove(at: index)
            if index < existingPhotosData.count {
                existingPhotosData.remove(at: index)
            }
        }
        print("🗑️ 移除現有照片 index: \(index)，剩餘 \(existingImages.count) 張")
    }
    
    // MARK: - 移除拍照照片
    private func removeCameraPhoto(at index: Int) {
        guard index < cameraImages.count else { return }
        
        withAnimation {
            cameraImages.remove(at: index)
            if index < cameraPhotosData.count {
                cameraPhotosData.remove(at: index)
            }
        }
        print("🗑️ 移除拍照照片 index: \(index)，剩餘 \(cameraImages.count) 張")
    }
    
    // MARK: - 移除相簿照片
    private func removePickerPhoto(at index: Int) {
        guard index < pickerImages.count else { return }
        
        withAnimation {
            pickerImages.remove(at: index)
            if index < pickerPhotosData.count {
                pickerPhotosData.remove(at: index)
            }
            
            // 同時移除對應的 PhotosPickerItem
            if index < selectedPhotoItems.count {
                selectedPhotoItems.remove(at: index)
            }
        }
        print("🗑️ 移除相簿照片 index: \(index)，剩餘 \(pickerImages.count) 張")
    }
    
    // MARK: - 清除所有照片
    private func clearAllPhotos() {
        withAnimation {
            selectedPhotoItems.removeAll()
            cameraImages.removeAll()
            cameraPhotosData.removeAll()
            pickerImages.removeAll()
            pickerPhotosData.removeAll()
            existingImages.removeAll()
            existingPhotosData.removeAll()
        }
        print("🗑️ 清除所有照片")
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
        
        // 合併所有照片的資料（原有 + 拍照 + 相簿選擇）
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

// MARK: - 現有照片卡片（修復點擊區域版）
struct ExistingPhotoCard: View {
    let image: UIImage
    let index: Int
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 照片主體
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
            
            // 刪除按鈕 - 嚴格限制點擊區域
            Button {
                print("🗑️ ExistingPhotoCard 刪除按鈕被點擊，index: \(index)")
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                    )
                    .font(.system(size: 16)) // 固定大小
            }
            .buttonStyle(PlainButtonStyle()) // 重要：移除預設按鈕樣式
            .contentShape(Circle()) // 嚴格限制為圓形點擊區域
            .frame(width: 24, height: 24) // 明確設定按鈕框架大小
            .offset(x: 8, y: -8) // 調整位置，確保不重疊
            .zIndex(1) // 確保按鈕在最上層
        }
        .contentShape(RoundedRectangle(cornerRadius: 8)) // 限制整個卡片的互動區域
    }
}

// MARK: - 拍照照片卡片（修復點擊區域版）
struct CameraPhotoCard: View {
    let image: UIImage
    let index: Int
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 照片主體
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
                .overlay(
                    // 拍照照片標記
                    VStack {
                        Spacer()
                        HStack {
                            Text("拍照")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.blue)
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(4)
                    }
                )
            
            // 刪除按鈕 - 嚴格限制點擊區域
            Button {
                print("🗑️ CameraPhotoCard 刪除按鈕被點擊，index: \(index)")
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                    )
                    .font(.system(size: 16)) // 固定大小
            }
            .buttonStyle(PlainButtonStyle()) // 重要：移除預設按鈕樣式
            .contentShape(Circle()) // 嚴格限制為圓形點擊區域
            .frame(width: 24, height: 24) // 明確設定按鈕框架大小
            .offset(x: 8, y: -8) // 調整位置，確保不重疊
            .zIndex(1) // 確保按鈕在最上層
        }
        .contentShape(RoundedRectangle(cornerRadius: 8)) // 限制整個卡片的互動區域
    }
}

// MARK: - 相簿照片卡片（修復點擊區域版）
struct PickerPhotoCard: View {
    let image: UIImage
    let index: Int
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 照片主體
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
                .overlay(
                    // 相簿照片標記
                    VStack {
                        Spacer()
                        HStack {
                            Text("相簿")
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
            
            // 刪除按鈕 - 嚴格限制點擊區域
            Button {
                print("🗑️ PickerPhotoCard 刪除按鈕被點擊，index: \(index)")
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                    )
                    .font(.system(size: 16)) // 固定大小
            }
            .buttonStyle(PlainButtonStyle()) // 重要：移除預設按鈕樣式
            .contentShape(Circle()) // 嚴格限制為圓形點擊區域
            .frame(width: 24, height: 24) // 明確設定按鈕框架大小
            .offset(x: 8, y: -8) // 調整位置，確保不重疊
            .zIndex(1) // 確保按鈕在最上層
        }
        .contentShape(RoundedRectangle(cornerRadius: 8)) // 限制整個卡片的互動區域
    }
}
