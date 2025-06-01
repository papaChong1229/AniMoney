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
    
    // 分離拍照和相簿選擇的照片
    @State private var selectedPhotoItems: [PhotosPickerItem] = [] // PhotosPicker 需要的狀態
    @State private var cameraImages: [UIImage] = [] // 拍照的照片
    @State private var cameraPhotosData: [Data] = [] // 拍照的照片數據
    @State private var pickerImages: [UIImage] = [] // 相簿選擇的照片
    @State private var pickerPhotosData: [Data] = [] // 相簿選擇的照片數據
    @State private var isLoadingPhotos = false

    // 計算屬性：合併所有照片
    private var allImages: [UIImage] {
        return cameraImages + pickerImages
    }
    
    private var allPhotosData: [Data] {
        return cameraPhotosData + pickerPhotosData
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

                // MARK: - 多張照片選擇區域（修復版）
                Section(header: Text("收據照片（可選）")) {
                    VStack(spacing: 16) { // 增加間距，避免按鈕過於接近
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
                        
                        // 照片預覽網格
                        if !allImages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("已選擇照片")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(allImages.count) 張")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // 拍照的照片
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
                                
                                // 相簿選擇的照片
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
                                
                                // 修復「清除所有照片」按鈕
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
                        }
                        
                        // 照片數量提示
                        if !allImages.isEmpty {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("已選擇 \(allImages.count) 張照片")
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
                    TextField("備註（可選）", text: $transactionNote)
                    
                    DatePicker("日期", selection: $transactionDate, displayedComponents: [.date])
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
                    .disabled(!isFormValid || isLoadingPhotos)
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
        
        // 清空相簿照片（但保留拍照照片）
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

        let amountToSave = currencyService.convertToTWD(amount: originalAmount, from: selectedCurrency)
        
        // 傳遞合併後的照片陣列（如果為空則傳 nil）
        let photosToSave = allPhotosData.isEmpty ? nil : allPhotosData
        
        dataController.addTransaction(
            category: category,
            subcategory: subcategory,
            amount: Int(round(amountToSave)),
            date: transactionDate,
            note: transactionNote.isEmpty ? nil : transactionNote,
            photosData: photosToSave,
            project: selectedProject
        )

        // 顯示成功訊息
        var successMessage = "成功新增支出記錄"
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

// MARK: - 照片預覽卡片（修復點擊區域版，保留作為備用）
struct AddPhotoCard: View {
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
            
            // 刪除按鈕 - 嚴格限制點擊區域
            Button {
                print("🗑️ AddPhotoCard 刪除按鈕被點擊，index: \(index)")
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

// MARK: - 照片預覽卡片
struct PhotoPreviewCard: View {
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
            
            // 移除按鈕
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
