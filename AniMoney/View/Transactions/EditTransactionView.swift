import SwiftUI
import PhotosUI

struct EditTransactionView: View {
    @EnvironmentObject private var dataController: DataController
    @Environment(\.dismiss) private var dismiss

    @Bindable var transaction: Transaction

    // MARK: - Form State
    @State private var selectedCategoryIndex: Int = 0
    @State private var selectedSubcategoryIndex: Int = 0
    @State private var selectedProjectIndex: Int = 0

    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""

    // 多張照片相關狀態
    @State private var newPhotoItems: [PhotosPickerItem] = []
    @State private var newImages: [UIImage] = []
    @State private var existingImages: [UIImage] = []
    @State private var isLoadingPhotos = false

    private var subcategories: [Subcategory] {
        guard dataController.categories.indices.contains(selectedCategoryIndex) else {
            return []
        }
        return dataController.categories[selectedCategoryIndex]
                 .subcategories
                 .sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationView {
            Form {
                // ... 類別、金額、日期、備註等其他 Section 保持不變 ...
                
                // 1. Category / Subcategory
                Section("類別") {
                    Picker("類別", selection: $selectedCategoryIndex) {
                        ForEach(dataController.categories.indices, id: \.self) { i in
                            Text(dataController.categories[i].name).tag(i)
                        }
                    }
                    .onChange(of: selectedCategoryIndex) { _, newValue in
                        selectedSubcategoryIndex = 0
                    }
                    
                    Picker("子類別", selection: $selectedSubcategoryIndex) {
                        ForEach(subcategories.indices, id: \.self) { j in
                            Text(subcategories[j].name).tag(j)
                        }
                    }
                }

                // 2. Amount
                Section("金額") {
                    TextField("0", text: $amountText)
                        .keyboardType(.numberPad)
                }

                // 3. Date
                Section("日期") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                // 4. Note
                Section("備註") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }

                // 5. 多張照片編輯
                Section("照片") {
                    VStack(spacing: 12) {
                        // 顯示現有照片
                        if !existingImages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("現有照片")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
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
                                
                                if !existingImages.isEmpty {
                                    Button("移除所有現有照片") {
                                        existingImages.removeAll()
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                        }
                        
                        // 選擇新照片
                        PhotosPicker(
                            selection: $newPhotoItems,
                            maxSelectionCount: 5,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "photo.badge.plus")
                                    .foregroundColor(.blue)
                                Text("新增照片")
                                    .foregroundColor(.blue)
                                Spacer()
                                if !newImages.isEmpty {
                                    Text("+\(newImages.count)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .disabled(isLoadingPhotos)
                        
                        // 載入指示器
                        if isLoadingPhotos {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("載入照片中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // 顯示新選擇的照片
                        if !newImages.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("新增照片")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
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
                        let totalPhotoCount = existingImages.count + newImages.count
                        if totalPhotoCount > 0 {
                            HStack {
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
                        }
                    }
                }

                // 6. Project
                Section("專案") {
                    Picker("專案", selection: $selectedProjectIndex) {
                        Text("無").tag(0)
                        ForEach(dataController.projects.indices, id: \.self) { k in
                            Text(dataController.projects[k].name).tag(k + 1)
                        }
                    }
                }
            }
            .navigationTitle("編輯交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        saveChanges()
                    }
                    .disabled(amountText.isEmpty || subcategories.isEmpty || isLoadingPhotos)
                }
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
    
    // MARK: - 初始化表單數據
    private func initializeFormData() {
        amountText = String(transaction.amount)
        date = transaction.date
        note = transaction.note ?? ""
        
        // 載入現有照片
        loadExistingPhotos()
        
        // 設定類別選擇
        if let categoryIndex = dataController.categories.firstIndex(where: { $0.id == transaction.category.id }) {
            selectedCategoryIndex = categoryIndex
        }
        
        // 設定子類別選擇
        DispatchQueue.main.async {
            if let subcategoryIndex = self.subcategories.firstIndex(where: { $0.id == self.transaction.subcategory.id }) {
                self.selectedSubcategoryIndex = subcategoryIndex
            }
        }
        
        // 設定專案選擇
        if let project = transaction.project,
           let projectIndex = dataController.projects.firstIndex(where: { $0.id == project.id }) {
            selectedProjectIndex = projectIndex + 1
        } else {
            selectedProjectIndex = 0
        }
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
    }
    
    // MARK: - 載入新選擇的照片
    @MainActor
    private func loadNewPhotos(from items: [PhotosPickerItem]) async {
        isLoadingPhotos = true
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
        guard let amount = Int(amountText),
              dataController.categories.indices.contains(selectedCategoryIndex),
              subcategories.indices.contains(selectedSubcategoryIndex) else {
            return
        }
        
        let selectedCategory = dataController.categories[selectedCategoryIndex]
        let selectedSubcategory = subcategories[selectedSubcategoryIndex]
        let selectedProject: Project? = selectedProjectIndex > 0
            ? dataController.projects[selectedProjectIndex - 1]
            : nil
        
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
            category: selectedCategory,
            subcategory: selectedSubcategory,
            amount: amount,
            date: date,
            note: note.isEmpty ? nil : note,
            photosData: finalPhotosData,
            project: selectedProject
        )
        
        dismiss()
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
                                .background(Color.blue)
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
