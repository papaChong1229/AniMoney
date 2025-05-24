// CategoryManagementViews.swift

import SwiftUI
import SwiftData

// MARK: - Main Management View (Top Level)
struct MainFinanceManagementView: View {
    @EnvironmentObject var dataController: DataController // Assuming DC is passed down

    var body: some View {
        NavigationStack { // Use NavigationStack for modern navigation
            CategoryManagerView() // Starting point
        }
    }
}


// MARK: - Category Manager View (Lists Categories and link to Projects)
struct CategoryManagerView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddCategorySheet = false

    // States for CATEGORY deletion flow
    @State private var categoryToDelete: Category?
    @State private var showingDeleteCategoryOptionsDialog = false
    @State private var showingReassignCategorySheet = false
    @State private var targetCategoryIDForReassignment: PersistentIdentifier?

    // State for adding a new project
    @State private var showingAddProjectSheet = false


    var body: some View {
        List {
            // Section for Categories
            Section(header: Text("Categories").font(.title3).padding(.bottom, 2)) {
                if dataController.categories.isEmpty {
                    Text("No categories yet. Tap '+' to add one.")
                        .foregroundColor(.secondary)
                }
                ForEach(dataController.categories.sorted(by: { $0.order < $1.order }), id: \.id) { category in
                    NavigationLink(destination: SubcategoryListView(category: category)
                                                .environmentObject(dataController)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(category.name)
                                    .font(.headline)
                                Spacer()
                                Text("(\(dataController.hasTransactions(category: category) ? "Has Tx" : "No Tx"))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Text("\(category.subcategories.count) subcategories")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            self.categoryToDelete = category
                            if dataController.hasTransactions(category: category) || category.subcategories.contains(where: { dataController.hasTransactions(subcategory: $0) }) {
                                self.showingDeleteCategoryOptionsDialog = true
                            } else {
                                // No transactions for category OR its subcategories
                                dataController.deleteCategoryWithCascade(category) // This handles subcategories too
                                self.categoryToDelete = nil
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        // TODO: Add Edit Category swipe action
                    }
                }
            }

            // Section for Projects
            Section(header: Text("Projects").font(.title3).padding(.vertical, 2)) {
                if dataController.projects.isEmpty {
                    Text("No projects yet. Tap '+' to add one.")
                        .foregroundColor(.secondary)
                }
                ForEach(dataController.projects.sorted(by: { $0.order < $1.order }), id: \.id) { project in
                    // NavigationLink to a ProjectDetailView or similar if needed
                    NavigationLink(destination: ProjectDetailView(project: project) // Placeholder
                                                .environmentObject(dataController) ) {
                        HStack {
                            Text(project.name)
                            Spacer()
                            Text("(\(dataController.hasTransactions(project: project) ? "Has Tx" : "No Tx"))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    // TODO: Add swipe actions for project deletion/reassignment
                }
            }
        }
        .navigationTitle("Manage Finance Items")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingAddCategorySheet = true } label: {
                        Label("Add Category", systemImage: "folder.badge.plus")
                    }
                    Button { showingAddProjectSheet = true } label: {
                        Label("Add Project", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Label("Add Item", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddCategorySheet) {
            AddCategoryView().environmentObject(dataController)
        }
        .sheet(isPresented: $showingAddProjectSheet) {
            AddProjectView().environmentObject(dataController) // Create this view
        }
        .confirmationDialog( // For CATEGORY deletion
            "Delete Category: \"\(categoryToDelete?.name ?? "")\"?",
            isPresented: $showingDeleteCategoryOptionsDialog,
            presenting: categoryToDelete
        ) { catForDialogActions in
            Button("Delete Category, its Subcategories, and ALL Related Transactions", role: .destructive) {
                dataController.deleteCategoryWithCascade(catForDialogActions)
                categoryToDelete = nil
            }
            Button("Reassign Transactions, then Delete Category & Subcategories") {
                targetCategoryIDForReassignment = dataController.categories.first(where: {
                    $0.id != catForDialogActions.id && !$0.subcategories.isEmpty // Target category must have subcategories
                })?.id
                showingReassignCategorySheet = true
            }
            Button("Cancel", role: .cancel) { categoryToDelete = nil }
        } message: { catForDialogMessage in
            Text("Category \"\(catForDialogMessage.name)\" or its subcategories have transactions. Deleting this category will also delete all its subcategories. How do you want to handle transactions?")
        }
        .sheet(isPresented: $showingReassignCategorySheet) { // For CATEGORY reassignment
            if let categoryToReassignFrom = categoryToDelete {
                ReassignCategoryTransactionsView( // Renamed for clarity
                    categoryToReassignFrom: categoryToReassignFrom,
                    selectedTargetCategoryID: $targetCategoryIDForReassignment,
                    onCompletion: { success in
                        showingReassignCategorySheet = false
                        if success { print("Category transactions reassigned and original deleted.") }
                        else { print("Category reassignment cancelled/failed.") }
                        categoryToDelete = nil
                    }
                ).environmentObject(dataController)
            }
        }
    }
}


// MARK: - Add Category View
struct AddCategoryView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var categoryName: String = ""

    var body: some View {
        NavigationView { // Use NavigationView inside sheet for its own toolbar
            Form {
                TextField("Category Name", text: $categoryName)
                Button("Add Category") {
                    if !categoryName.isEmpty {
                        dataController.addCategory(name: categoryName)
                        dismiss()
                    }
                }
                .disabled(categoryName.isEmpty)
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
            }
        }
    }
}

// MARK: - Reassign Category Transactions View (Sheet for Category reassignment)
struct ReassignCategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    
    let categoryToReassignFrom: Category
    @Binding var selectedTargetCategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void

    var availableTargetCategories: [Category] {
        dataController.categories.filter { cat in
            cat.id != categoryToReassignFrom.id && !cat.subcategories.isEmpty // Target must have subcategories
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign ALL transactions from \"\(categoryToReassignFrom.name)\" (including those in its subcategories) to a subcategory of:")) {
                    if availableTargetCategories.isEmpty {
                        Text("No other categories with subcategories are available.").foregroundColor(.orange)
                    } else {
                        Picker("Target Category", selection: $selectedTargetCategoryID) {
                            Text("Select a category...").tag(nil as PersistentIdentifier?)
                            ForEach(availableTargetCategories) { cat in
                                Text("\(cat.name) (Subcategories: \(cat.subcategories.map(\.name).joined(separator: ", ")))")
                                    .tag(cat.id as PersistentIdentifier?)
                            }
                        }.labelsHidden()
                    }
                }
                Section {
                    Button("Reassign and Delete Original Category") {
                        handleReassignAndDeleteCategory()
                    }.disabled(selectedTargetCategoryID == nil || availableTargetCategories.isEmpty)
                }
            }
            .navigationTitle("Select Target Category")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onCompletion(false); dismiss() } } }
            .onAppear {
                if selectedTargetCategoryID == nil, let firstAvailable = availableTargetCategories.first {
                    selectedTargetCategoryID = firstAvailable.id
                }
            }
        }
    }

    private func handleReassignAndDeleteCategory() {
        guard let targetCatID = selectedTargetCategoryID,
              let targetCategory = availableTargetCategories.first(where: { $0.id == targetCatID }) else {
            print("Error: No valid target category for reassignment.")
            onCompletion(false)
            return
        }
        // Reassign all transactions from oldCategory (and its subcategories) to the first subcategory of targetCategory
        if dataController.reassignTransactions(from: categoryToReassignFrom, to: targetCategory) {
            dataController.deleteCategory(categoryToReassignFrom) // Deletes original cat + its subcats by cascade
            onCompletion(true)
            dismiss()
        } else {
            print("Error: Category transaction reassignment failed.")
            onCompletion(false)
        }
    }
}


// MARK: - Subcategory List View
struct SubcategoryListView: View {
    @EnvironmentObject var dataController: DataController
    @Bindable var category: Category // Use @Bindable if you need to modify category directly from here

    @State private var subcategoryToDelete: Subcategory?
    @State private var showingSubDeleteOptionsDialog = false
    @State private var showingSubReassignSheet = false
    @State private var targetSubcategoryIDForReassignment: PersistentIdentifier?
    @State private var showingAddSubcategorySheet = false

    var body: some View {
        List {
            Section(header: Text("Subcategories of \"\(category.name)\"")) {
                if category.subcategories.isEmpty {
                    Text("No subcategories yet.").foregroundColor(.secondary)
                }
                ForEach(category.subcategories.sorted(by: { $0.order < $1.order }), id: \.id) { subcategory in
                    HStack {
                        Text(subcategory.name)
                        Spacer()
                        Text("(\(dataController.hasTransactions(subcategory: subcategory) ? "Has Tx" : "No Tx"))")
                            .font(.caption2).foregroundColor(.gray)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            self.subcategoryToDelete = subcategory
                            if dataController.hasTransactions(subcategory: subcategory) {
                                self.showingSubDeleteOptionsDialog = true
                            } else {
                                dataController.deleteSubcategory(subcategory, from: category)
                                self.subcategoryToDelete = nil
                            }
                        } label: { Label("Delete", systemImage: "trash") }
                        // TODO: Add Edit Subcategory swipe action
                    }
                }
            }
        }
        .navigationTitle("Subcategories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddSubcategorySheet = true } label: { Label("Add Subcategory", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showingAddSubcategorySheet) {
            AddSubcategoryView(category: category).environmentObject(dataController)
        }
        .confirmationDialog( // For SUBCATEGORY deletion
            "Delete Subcategory: \"\(subcategoryToDelete?.name ?? "")\"?",
            isPresented: $showingSubDeleteOptionsDialog,
            presenting: subcategoryToDelete
        ) { subcatForDialogActions in
            Button("Delete Subcategory and Its Transactions", role: .destructive) {
                dataController.deleteSubcategoryAndRelatedTransactions(from: category, subcategoryToDelete: subcatForDialogActions)
                subcategoryToDelete = nil
            }
            Button("Reassign Transactions, then Delete Subcategory") {
                targetSubcategoryIDForReassignment = category.subcategories.first(where: {
                    $0.id != subcatForDialogActions.id // Target must be a *different* subcategory in the *same* parent
                })?.id
                showingSubReassignSheet = true
            }
            Button("Cancel", role: .cancel) { subcategoryToDelete = nil }
        } message: { subcatForDialogMessage in
            Text("Subcategory \"\(subcatForDialogMessage.name)\" has transactions. How do you want to proceed?")
        }
        .sheet(isPresented: $showingSubReassignSheet) { // For SUBCATEGORY reassignment
            if let subToReassignFrom = subcategoryToDelete {
                ReassignSubcategoryTransactionsView(
                    parentCategory: category,
                    subcategoryToReassignFrom: subToReassignFrom,
                    selectedTargetSubcategoryID: $targetSubcategoryIDForReassignment,
                    onCompletion: { success in
                        showingSubReassignSheet = false
                        if success { print("Subcategory transactions reassigned and original deleted.") }
                        else { print("Subcategory reassignment cancelled/failed.") }
                        subcategoryToDelete = nil
                    }
                ).environmentObject(dataController)
            }
        }
    }
}

// MARK: - Add Subcategory View
struct AddSubcategoryView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let category: Category // Parent category

    @State private var subcategoryName: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Adding to Category: \(category.name)")) {
                    TextField("New Subcategory Name", text: $subcategoryName)
                }
                Button("Add Subcategory") {
                    if !subcategoryName.isEmpty {
                        dataController.addSubcategory(to: category, name: subcategoryName)
                        dismiss()
                    }
                }.disabled(subcategoryName.isEmpty)
            }
            .navigationTitle("New Subcategory")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

// MARK: - Reassign Subcategory Transactions View (Sheet for Subcategory reassignment)
struct ReassignSubcategoryTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss

    let parentCategory: Category
    let subcategoryToReassignFrom: Subcategory
    @Binding var selectedTargetSubcategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void

    var availableTargetSubcategories: [Subcategory] {
        parentCategory.subcategories.filter { $0.id != subcategoryToReassignFrom.id }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign transactions from \"\(subcategoryToReassignFrom.name)\" to another subcategory in \"\(parentCategory.name)\":")) {
                    if availableTargetSubcategories.isEmpty {
                        Text("No other subcategories available in \"\(parentCategory.name)\".").foregroundColor(.orange)
                    } else {
                        Picker("Target Subcategory", selection: $selectedTargetSubcategoryID) {
                            Text("Select a subcategory...").tag(nil as PersistentIdentifier?)
                            ForEach(availableTargetSubcategories) { subcat in
                                Text(subcat.name).tag(subcat.id as PersistentIdentifier?)
                            }
                        }.labelsHidden()
                    }
                }
                Section {
                    Button("Reassign and Delete Original Subcategory") {
                        handleReassignAndSubDelete()
                    }.disabled(selectedTargetSubcategoryID == nil || availableTargetSubcategories.isEmpty)
                }
            }
            .navigationTitle("Select Target Subcategory")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onCompletion(false); dismiss() } } }
            .onAppear {
                if selectedTargetSubcategoryID == nil, let firstAvailable = availableTargetSubcategories.first {
                    selectedTargetSubcategoryID = firstAvailable.id
                }
            }
        }
    }

    private func handleReassignAndSubDelete() {
        guard let targetID = selectedTargetSubcategoryID,
              let targetSub = availableTargetSubcategories.first(where: { $0.id == targetID }) else {
            print("Error: No valid target subcategory for reassignment.")
            onCompletion(false); return
        }
        if dataController.reassignTransactions(from: subcategoryToReassignFrom, to: targetSub) {
            dataController.deleteSubcategory(subcategoryToReassignFrom, from: parentCategory)
            onCompletion(true); dismiss()
        } else {
            print("Error: Subcategory transaction reassignment failed."); onCompletion(false)
        }
    }
}


// MARK: - Project Views (Placeholders and Basic Structure)

// Placeholder for a view showing project details or allowing edits
struct ProjectDetailView: View {
    @EnvironmentObject var dataController: DataController
    @Bindable var project: Project // Or just `let project: Project` if not editing directly

    // TODO: Implement project deletion and transaction reassignment logic similar to categories
    @State private var showingDeleteProjectOptionsDialog = false
    @State private var showingReassignProjectSheet = false
    @State private var targetProjectIDForReassignment: PersistentIdentifier?


    var body: some View {
        List {
            Section("Project Details") {
                Text("Name: \(project.name)")
                Text("Order: \(project.order)")
                Text("Has Transactions: \(dataController.hasTransactions(project: project) ? "Yes" : "No")")
            }

            Section("Actions") {
                Button("Delete Project", role: .destructive) {
                    if dataController.hasTransactions(project: project) {
                        showingDeleteProjectOptionsDialog = true
                    } else {
                        dataController.deleteProject(project) // Or deleteProjectWithCascade if needed
                        // Optionally dismiss this view if it's in a navigation stack
                    }
                }
            }
            // TODO: List transactions for this project?
        }
        .navigationTitle(project.name)
        .confirmationDialog( // For PROJECT deletion
            "Delete Project: \"\(project.name)\"?",
            isPresented: $showingDeleteProjectOptionsDialog
        ) {
            Button("Delete Project and All Its Transactions", role: .destructive) {
                dataController.deleteProjectWithCascade(project)
                // TODO: Handle navigation back
            }
            Button("Set Project to Nil for Transactions, then Delete Project", role: .destructive) {
                dataController.deleteProjectAndNilOutTransactions(project)
                 // TODO: Handle navigation back
            }
            Button("Reassign Transactions, then Delete Project") {
                targetProjectIDForReassignment = dataController.projects.first(where: { $0.id != project.id })?.id
                showingReassignProjectSheet = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Project \"\(project.name)\" has transactions. How do you want to proceed?")
        }
        .sheet(isPresented: $showingReassignProjectSheet) {
            // Create ReassignProjectTransactionsView similar to others
            if let currentProject = dataController.projects.first(where: {$0.id == project.id}) { // ensure it's a managed instance
                 ReassignProjectTransactionsView(
                    projectToReassignFrom: currentProject,
                    selectedTargetProjectID: $targetProjectIDForReassignment,
                    onCompletion: { success in
                        showingReassignProjectSheet = false
                        if success { print("Project transactions reassigned and original deleted.")}
                        // TODO: Handle navigation back if successful
                    }
                ).environmentObject(dataController)
            }
        }
    }
}

// Add Project View
struct AddProjectView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var projectName: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Project Name", text: $projectName)
                Button("Add Project") {
                    if !projectName.isEmpty {
                        dataController.addProject(name: projectName)
                        dismiss()
                    }
                }.disabled(projectName.isEmpty)
            }
            .navigationTitle("New Project")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

// Reassign Project Transactions View
struct ReassignProjectTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss

    let projectToReassignFrom: Project
    @Binding var selectedTargetProjectID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void

    var availableTargetProjects: [Project] {
        dataController.projects.filter { $0.id != projectToReassignFrom.id }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign transactions from \"\(projectToReassignFrom.name)\" to:")) {
                    if availableTargetProjects.isEmpty {
                        Text("No other projects available.").foregroundColor(.orange)
                    } else {
                        Picker("Target Project", selection: $selectedTargetProjectID) {
                            Text("Select a project...").tag(nil as PersistentIdentifier?)
                            ForEach(availableTargetProjects) { proj in
                                Text(proj.name).tag(proj.id as PersistentIdentifier?)
                            }
                        }.labelsHidden()
                    }
                }
                Section {
                    Button("Reassign and Delete Original Project") {
                        handleReassignAndDeleteProject()
                    }.disabled(selectedTargetProjectID == nil || availableTargetProjects.isEmpty)
                }
            }
            .navigationTitle("Select Target Project")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onCompletion(false); dismiss() } } }
            .onAppear {
                if selectedTargetProjectID == nil, let firstAvailable = availableTargetProjects.first {
                    selectedTargetProjectID = firstAvailable.id
                }
            }
        }
    }
    private func handleReassignAndDeleteProject() {
        guard let targetID = selectedTargetProjectID,
              let targetProj = availableTargetProjects.first(where: { $0.id == targetID }) else {
            onCompletion(false); return
        }
        if dataController.reassignTransactions(from: projectToReassignFrom, to: targetProj) {
            dataController.deleteProject(projectToReassignFrom)
            onCompletion(true); dismiss()
        } else {
            onCompletion(false)
        }
    }
}
