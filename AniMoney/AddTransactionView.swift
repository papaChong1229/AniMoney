//
//  AddTransactionView.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/21.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Category.order, order: .forward) private var categories: [Category]
    @Query(sort: \Project.order, order: .forward) private var projects:   [Project]
    
    // MARK: - Form State
    @State private var selectedCategoryIndex = 0
    @State private var selectedSubcategoryIndex = 0
    @State private var selectedProjectIndex = 0   // 0 表示 “None”
    
    @State private var amountText: String = ""
    @State private var date = Date()
    @State private var note: String = ""
    
    @State private var photos: [PhotosPickerItem] = []
    @State private var uiImages: [UIImage] = []
    
    // 動態取得當前大類底下的小類
    private var subcategories: [Subcategory] {
        guard categories.indices.contains(selectedCategoryIndex) else {
            // 当 categories 为空，或者索引越界
            return []
        }
        return categories[selectedCategoryIndex].subcategories.sorted{$0.order < $1.order}
    }

    
    var body: some View {
        NavigationView {
            Form {
                // MARK: 1. 分類選擇
                Section("Category") {
                    Picker("Category", selection: $selectedCategoryIndex) {
                        ForEach(categories.indices, id: \.self) { i in
                            Text(categories[i].name).tag(i)
                        }
                    }
                    Picker("Subcategory", selection: $selectedSubcategoryIndex) {
                        ForEach(subcategories.indices, id: \.self) { j in
                            Text(subcategories[j].name).tag(j)
                        }
                    }
                }
                
                // MARK: 2. 金額
                Section("Amount") {
                    TextField("0", text: $amountText)
                        .keyboardType(.numberPad)
                }
                
                // MARK: 3. 日期
                Section("Date") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                
                // MARK: 4. 備註
                Section("Note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
                
                // MARK: 5. 照片（可多選）
                Section("Photos") {
                    PhotosPicker(
                        selection: $photos,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Text("Select Photos")
                    }
                    .onChange(of: photos) { oldItems, newItems in
                        // 把 PhotosPickerItem 轉成 UIImage
                        uiImages.removeAll()
                        for item in newItems {
                            Task {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let img = UIImage(data: data) {
                                    uiImages.append(img)
                                }
                            }
                        }
                    }
                    
                    // 顯示已選照片縮圖
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
                
                // MARK: 6. 專案（可選）
                Section("Project") {
                    Picker("Project", selection: $selectedProjectIndex) {
                        Text("None").tag(0)
                        ForEach(projects.indices, id: \.self) { k in
                            Text(projects[k].name).tag(k+1)
                        }
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // 建立 Transaction
                        let cat = categories[selectedCategoryIndex]
                        let sub = cat.subcategories[selectedSubcategoryIndex]
                        let proj = selectedProjectIndex > 0
                                 ? projects[selectedProjectIndex - 1] : nil

                        let tx = Transaction(
                            category:    cat,
                            subcategory: sub,
                            amount:      Int(amountText) ?? 0,
                            date:        date,
                            note:        note.isEmpty ? nil : note,
                            project:     proj
                        )

                        // 插入 ModelContext → 自動存檔
                        modelContext.insert(tx)
                        dismiss()
                    }
                    .disabled(amountText.isEmpty)
                }
            }
        }
    }
}


#Preview {
    AddTransactionView()
}
