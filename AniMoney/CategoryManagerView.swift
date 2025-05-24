import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddCategorySheet = false

    @State private var categoryToDelete: Category?
    @State private var showingDeleteOptionsDialog = false
    @State private var showingReassignSheet = false
    @State private var targetCategoryIDForReassignment: PersistentIdentifier?

    var body: some View {
        NavigationStack {
            List {
                ForEach(dataController.categories, id: \.id) { category in
                    // DisclosureGroup for subcategories could be nice here
                    VStack(alignment: .leading) {
                        HStack {
                            Text(category.name)
                                .font(.headline)
                            Spacer()
                            Text("(\(dataController.hasTransactions(category: category) ? "Has Tx" : "No Tx"))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        if !category.subcategories.isEmpty {
                            Text("Subcategories: \(category.subcategories.map(\.name).joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No subcategories")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button(role: .destructive) {
                            self.categoryToDelete = category
                            if dataController.hasTransactions(category: category) {
                                self.showingDeleteOptionsDialog = true
                            } else {
                                // No transactions related directly to Category (check subcategories if logic requires)
                                // The .cascade on Category.subcategories handles subcategory deletion.
                                dataController.deleteCategoryWithCascade(category) // This will delete category, its subcategories, and any direct category transactions
                                self.categoryToDelete = nil
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        // TODO: Add Edit Category swipe action
                        // TODO: Add Manage Subcategories swipe action (navigate to a subcategory list for this category)
                    }
                }
            }
            .navigationTitle("Manage Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategorySheet = true
                    } label: {
                        Label("Add Category", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategorySheet) {
                AddCategoryView().environmentObject(dataController)
            }
            .confirmationDialog(
                "Delete \"\(categoryToDelete?.name ?? "Category")\"?",
                isPresented: $showingDeleteOptionsDialog,
                presenting: categoryToDelete
            ) { categoryForDialogActions in
                Button("Delete Category, its Subcategories, and All Related Transactions", role: .destructive) {
                    // This function in DataController should handle deleting transactions linked to the category
                    // AND transactions linked to its subcategories if that's the desired behavior.
                    // Currently, deleteCategoryWithCascade deletes tx for category, and subcategories by .cascade.
                    // If subcategory transactions also need explicit deletion, DataController needs adjustment.
                    // For now, assuming deleteCategoryWithCascade is sufficient.
                    dataController.deleteCategoryWithCascade(categoryForDialogActions)
                    categoryToDelete = nil
                }
                Button("Reassign Transactions, then Delete Category & Subcategories") {
                    // Ensure categoryForDialogActions.subcategories is populated for the next view.
                    // The target category for reassignment must have at least one subcategory.
                    targetCategoryIDForReassignment = dataController.categories.first(where: {
                        $0.id != categoryForDialogActions.id && !$0.subcategories.isEmpty
                    })?.id
                    showingReassignSheet = true
                }
                Button("Cancel", role: .cancel) {
                    categoryToDelete = nil
                }
            } message: { categoryForDialogMessage in // categoryToDelete must be non-nil
                 Text("Category \"\(categoryForDialogMessage.name)\" has transactions. Its subcategories will also be deleted. How do you want to handle transactions?")
            }
            .sheet(isPresented: $showingReassignSheet) {
                if let categoryToReassignFrom = categoryToDelete {
                    ReassignmentTargetCategorySelectionView(
                        categoryToReassignFrom: categoryToReassignFrom,
                        selectedTargetCategoryID: $targetCategoryIDForReassignment,
                        onCompletion: { reassignSuccess in
                            showingReassignSheet = false
                            if reassignSuccess {
                                print("Reassignment and deletion process initiated successfully.")
                            } else {
                                print("Reassignment process was cancelled or failed.")
                            }
                            categoryToDelete = nil
                        }
                    )
                    .environmentObject(dataController)
                }
            }
        }
    }
}

// AddCategoryView remains largely the same as before
struct AddCategoryView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var categoryName: String = ""
    // You might want to allow adding initial subcategories here too
    // @State private var initialSubcategoryName: String = ""


    var body: some View {
        NavigationView {
            Form {
                TextField("Category Name", text: $categoryName)
                // Example for adding one initial subcategory (optional)
                // TextField("Initial Subcategory (Optional)", text: $initialSubcategoryName)
                Button("Add Category") {
                    if !categoryName.isEmpty {
                        dataController.addCategory(name: categoryName)
                        // If you added logic for initial subcategory:
                        // if let newCat = dataController.categories.last(where: {$0.name == categoryName }), !initialSubcategoryName.isEmpty {
                        //    dataController.addSubcategory(to: newCat, name: initialSubcategoryName)
                        // }
                        dismiss()
                    }
                }
                .disabled(categoryName.isEmpty)
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}


// ReassignmentTargetCategorySelectionView remains largely the same,
// but the logic for `availableTargetCategories` is crucial.
struct ReassignmentTargetCategorySelectionView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    let categoryToReassignFrom: Category
    @Binding var selectedTargetCategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void

    var availableTargetCategories: [Category] {
        dataController.categories.filter { cat in
            // Cannot reassign to itself AND target category must have at least one subcategory
            cat.id != categoryToReassignFrom.id && !cat.subcategories.isEmpty
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign transactions from \"\(categoryToReassignFrom.name)\" to:")) {
                    if availableTargetCategories.isEmpty {
                        Text("No other categories with subcategories are available. Please ensure other categories have at least one subcategory, or choose to delete all transactions instead of reassigning.")
                            .foregroundColor(.orange)
                            .padding(.vertical)
                    } else {
                        Picker("Target Category", selection: $selectedTargetCategoryID) {
                            Text("Select a category...").tag(nil as PersistentIdentifier?)
                            ForEach(availableTargetCategories) { cat in
                                Text("\(cat.name) (Subcategories: \(cat.subcategories.map(\.name).joined(separator: ", ")))")
                                    .tag(cat.id as PersistentIdentifier?)
                            }
                        }
                        .labelsHidden()
                    }
                }

                Section {
                    Button("Reassign and Delete Original Category") {
                        handleReassignAndDelete()
                    }
                    .disabled(selectedTargetCategoryID == nil || availableTargetCategories.isEmpty)
                }
            }
            .navigationTitle("Select Target")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCompletion(false)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if selectedTargetCategoryID == nil, let firstAvailable = availableTargetCategories.first {
                    selectedTargetCategoryID = firstAvailable.id
                }
            }
        }
    }

    private func handleReassignAndDelete() {
        guard let targetID = selectedTargetCategoryID,
              let targetCategory = availableTargetCategories.first(where: { $0.id == targetID }) else {
            print("Error: No valid target category selected for reassignment.")
            onCompletion(false)
            return
        }

        // Perform reassignment
        if dataController.reassignTransactions(from: categoryToReassignFrom, to: targetCategory) {
            // If reassignment is successful, delete the original category.
            // `deleteCategory` will handle cascade deletion of its subcategories.
            dataController.deleteCategory(categoryToReassignFrom)
            onCompletion(true)
            dismiss()
        } else {
            print("Error: Transaction reassignment failed.")
            onCompletion(false)
        }
    }
}
