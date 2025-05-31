import SwiftUI
import PhotosUI

struct EditTransactionView: View {
    @EnvironmentObject private var dataController: DataController
    @Environment(\.dismiss) private var dismiss

    // 要編輯的交易
    @Bindable var transaction: Transaction

    // MARK: - Form State
    @State private var selectedCategoryIndex: Int = 0
    @State private var selectedSubcategoryIndex: Int = 0
    @State private var selectedProjectIndex: Int = 0  // 0 = None

    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""

    @State private var photos: [PhotosPickerItem] = []
    @State private var uiImages: [UIImage] = []
    @State private var hasExistingPhoto: Bool = false

    // 依 dataController.categories 動態產生 subcategories，並以 order 排序
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
                // 1. Category / Subcategory
                Section("類別") {
                    Picker("類別", selection: $selectedCategoryIndex) {
                        ForEach(dataController.categories.indices, id: \.self) { i in
                            Text(dataController.categories[i].name).tag(i)
                        }
                    }
                    .onChange(of: selectedCategoryIndex) { _, newValue in
                        // 當類別改變時，重置子類別選擇
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

                // 5. Photos
                Section("照片") {
                    // 顯示現有照片
                    if hasExistingPhoto {
                        if let photoData = transaction.photoData,
                           let uiImage = UIImage(data: photoData) {
                            HStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading) {
                                    Text("現有照片")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button("移除照片", role: .destructive) {
                                        hasExistingPhoto = false
                                    }
                                    .font(.caption)
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    // 選擇新照片
                    PhotosPicker(
                        selection: $photos,
                        maxSelectionCount: 1,
                        matching: .images
                    ) {
                        Text(hasExistingPhoto ? "更換照片" : "選擇照片")
                    }
                    .onChange(of: photos) { _, newItems in
                        uiImages.removeAll()
                        for item in newItems {
                            Task {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    uiImages.append(img)
                                    hasExistingPhoto = false // 新照片會替換舊照片
                                }
                            }
                        }
                    }

                    // 顯示新選擇的照片
                    if !uiImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(uiImages, id: \.self) { img in
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
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
                    .disabled(amountText.isEmpty || subcategories.isEmpty)
                }
            }
        }
        .onAppear {
            initializeFormData()
        }
    }
    
    private func initializeFormData() {
        // 初始化表單數據
        amountText = String(transaction.amount)
        date = transaction.date
        note = transaction.note ?? ""
        hasExistingPhoto = transaction.photoData != nil
        
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
        
        // 處理照片數據
        var photoData: Data? = nil
        if !uiImages.isEmpty {
            // 使用新選擇的照片
            photoData = uiImages.first?.jpegData(compressionQuality: 0.8)
        } else if hasExistingPhoto {
            // 保留現有照片
            photoData = transaction.photoData
        }
        // 如果 hasExistingPhoto 為 false 且沒有新照片，photoData 保持 nil（移除照片）
        
        // 使用 DataController 的更新方法
        dataController.updateTransaction(
            transaction,
            category: selectedCategory,
            subcategory: selectedSubcategory,
            amount: amount,
            date: date,
            note: note.isEmpty ? nil : note,
            photoData: photoData,
            project: selectedProject
        )
        
        dismiss()
    }
}

#Preview {
    EditTransactionView(transaction: Transaction(
        category: Category(name: "食品酒水", order: 0),
        subcategory: Subcategory(name: "早餐", order: 0),
        amount: 100,
        date: Date()
    ))
    .environmentObject(try! DataController())
}
