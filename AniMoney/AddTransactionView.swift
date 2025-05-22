import SwiftUI
import PhotosUI

struct AddTransactionView: View {
    @EnvironmentObject private var dataController: DataController
    @Environment(\.dismiss)     private var dismiss

    // MARK: - Form State
    @State private var selectedCategoryIndex   = 0
    @State private var selectedSubcategoryIndex = 0
    @State private var selectedProjectIndex     = 0  // 0 = None

    @State private var amountText: String = ""
    @State private var date = Date()
    @State private var note = ""

    @State private var photos: [PhotosPickerItem] = []
    @State private var uiImages: [UIImage]       = []

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
                Section("Category") {
                    Picker("Category", selection: $selectedCategoryIndex) {
                        ForEach(dataController.categories.indices, id: \.self) { i in
                            Text(dataController.categories[i].name).tag(i)
                        }
                    }
                    Picker("Subcategory", selection: $selectedSubcategoryIndex) {
                        ForEach(subcategories.indices, id: \.self) { j in
                            Text(subcategories[j].name).tag(j)
                        }
                    }
                }

                // 2. Amount
                Section("Amount") {
                    TextField("0", text: $amountText)
                        .keyboardType(.numberPad)
                }

                // 3. Date
                Section("Date") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                // 4. Note
                Section("Note") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }

                // 5. Photos (示範 UI，實際儲存需自行處理)
                Section("Photos") {
                    PhotosPicker(
                        selection: $photos,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Text("Select Photos")
                    }
                    .onChange(of: photos) { _, newItems in
                        uiImages.removeAll()
                        for item in newItems {
                            Task {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let img  = UIImage(data: data) {
                                    uiImages.append(img)
                                }
                            }
                        }
                    }

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

                // 6. Project
                Section("Project") {
                    Picker("Project", selection: $selectedProjectIndex) {
                        Text("None").tag(0)
                        ForEach(dataController.projects.indices, id: \.self) { k in
                            Text(dataController.projects[k].name).tag(k + 1)
                        }
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cat   = dataController.categories[selectedCategoryIndex]
                        let sub   = subcategories[selectedSubcategoryIndex]
                        let proj: Project? = selectedProjectIndex > 0
                            ? dataController.projects[selectedProjectIndex - 1]
                            : nil

                        // 呼叫 DataController 的新增方法
                        dataController.addTransaction(
                            category:    cat,
                            subcategory: sub,
                            amount:      Int(amountText) ?? 0,
                            date:        date,
                            note:        note.isEmpty ? nil : note,
                            project:     proj
                        )
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
        .environmentObject(try! DataController())
}
