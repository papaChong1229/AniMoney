// CategoryManagementViews.swift

import SwiftUI
import SwiftData

// MARK: - Main Management View (Top Level Entry Point)
struct MainFinanceManagementView: View {
    @EnvironmentObject var dataController: DataController

    var body: some View {
        NavigationStack {
            CategoryManagerView()
        }
    }
}

// MARK: - Category Manager View
struct CategoryManagerView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddCategorySheet = false

    @State private var categoryToAction: Category?
    @State private var showingConfirmDirectDeleteCatDialog = false
    @State private var showingReassignCategorySheet = false
    @State private var targetCategoryIDForReassignment: PersistentIdentifier?

    @State private var showingAddProjectSheet = false

    var body: some View {
        List {
            // MARK: Categories Section
            Section(header: Text("Categories").font(.title3).padding(.bottom, 2)) {
                if dataController.categories.isEmpty {
                    Text("No categories yet. Tap '+' to add one.").foregroundColor(.secondary)
                }
                ForEach(dataController.categories.sorted(by: { $0.order < $1.order }), id: \.id) { category in
                    NavigationLink(destination: SubcategoryListView(category: category).environmentObject(dataController)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(category.name).font(.headline)
                                Spacer()
                                let hasAnyTransactions = dataController.hasTransactions(category: category) ||
                                                         category.subcategories.contains(where: { dataController.hasTransactions(subcategory: $0) })
                                Text(hasAnyTransactions ? "(Has Tx)" : "(No Tx)").font(.caption2).foregroundColor(.gray)
                            }
                            Text("\(category.subcategories.count) subcategories").font(.caption).foregroundColor(.secondary)
                        }.padding(.vertical, 4)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            self.categoryToAction = category
                            let hasTx = dataController.hasTransactions(category: category) || category.subcategories.contains { dataController.hasTransactions(subcategory: $0) }
                            if hasTx {
                                targetCategoryIDForReassignment = dataController.categories.first(where: { $0.id != category.id && !$0.subcategories.isEmpty })?.id
                                self.showingReassignCategorySheet = true
                            } else {
                                self.showingConfirmDirectDeleteCatDialog = true
                            }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }

            // MARK: Projects Section
            Section(header: Text("Projects").font(.title3).padding(.vertical, 2)) {
                if dataController.projects.isEmpty {
                    Text("No projects yet. Tap '+' to add one.").foregroundColor(.secondary)
                }
                ForEach(dataController.projects.sorted(by: { $0.order < $1.order }), id: \.id) { project in
                    NavigationLink(destination: ProjectDetailView(project: project).environmentObject(dataController)) {
                        HStack {
                            Text(project.name)
                            Spacer()
                            Text("(\(dataController.hasTransactions(project: project) ? "Has Tx" : "No Tx"))").font(.caption2).foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("Manage Finance Items")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showingAddCategorySheet = true } label: { Label("Add Category", systemImage: "folder.badge.plus") }
                    Button { showingAddProjectSheet = true } label: { Label("Add Project", systemImage: "doc.badge.plus") }
                } label: { Label("Add Item", systemImage: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showingAddCategorySheet) { AddCategoryView().environmentObject(dataController) }
        .sheet(isPresented: $showingAddProjectSheet) { AddProjectView().environmentObject(dataController) }
        .confirmationDialog(
            "Delete Category: \"\(categoryToAction?.name ?? "")\"?",
            isPresented: $showingConfirmDirectDeleteCatDialog,
            presenting: categoryToAction
        ) { catAction in
            Button("Delete Category and its Subcategories", role: .destructive) {
                dataController.deleteCategoryWithCascade(catAction)
                categoryToAction = nil
            }
            Button("Cancel", role: .cancel) { categoryToAction = nil }
        } message: { catAction in Text("Are you sure? This will also delete all subcategories of \"\(catAction.name)\". There are no transactions associated.") }
        .sheet(isPresented: $showingReassignCategorySheet) {
            if let catFrom = categoryToAction {
                ReassignCategoryTransactionsView(categoryToReassignFrom: catFrom, selectedTargetCategoryID: $targetCategoryIDForReassignment) { success in
                    showingReassignCategorySheet = false
                    if success { print("Category reassigned/deleted.") } else { print("Category reassignment cancelled/failed.") }
                    categoryToAction = nil
                }.environmentObject(dataController)
            }
        }
    }
}

// MARK: - AddCategoryView, ReassignCategoryTransactionsView (largely same as before)
struct AddCategoryView: View { /* ... (same as previous version) ... */
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var categoryName: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Category Name", text: $categoryName)
                Button("Add Category") {
                    if !categoryName.isEmpty {
                        dataController.addCategory(name: categoryName)
                        dismiss()
                    }
                }.disabled(categoryName.isEmpty)
            }
            .navigationTitle("New Category")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct ReassignCategoryTransactionsView: View { /* ... (same as previous version) ... */
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let categoryToReassignFrom: Category
    @Binding var selectedTargetCategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void
    var availableTargetCategories: [Category] { dataController.categories.filter { $0.id != categoryToReassignFrom.id && !$0.subcategories.isEmpty } }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign ALL transactions from \"\(categoryToReassignFrom.name)\" (and its subcategories) to a subcategory of:")) {
                    if availableTargetCategories.isEmpty { Text("No other categories with subcategories available.").foregroundColor(.orange) }
                    else {
                        Picker("Target Category", selection: $selectedTargetCategoryID) {
                            Text("Select a category...").tag(nil as PersistentIdentifier?)
                            ForEach(availableTargetCategories) { cat in Text("\(cat.name) (\(cat.subcategories.count) subs)").tag(cat.id as PersistentIdentifier?) }
                        }.labelsHidden()
                    }
                }
                Section { Button("Reassign and Delete Original Category") { handleReassignAndDeleteCategory() }.disabled(selectedTargetCategoryID == nil || availableTargetCategories.isEmpty) }
            }
            .navigationTitle("Select Target for Category Tx")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onCompletion(false); dismiss() } } }
            .onAppear { if selectedTargetCategoryID == nil, let first = availableTargetCategories.first { selectedTargetCategoryID = first.id } }
        }
    }
    private func handleReassignAndDeleteCategory() {
        guard let targetCatID = selectedTargetCategoryID, let targetCat = availableTargetCategories.first(where: { $0.id == targetCatID }) else { onCompletion(false); return }
        if dataController.reassignTransactions(from: categoryToReassignFrom, to: targetCat) {
            dataController.deleteCategory(categoryToReassignFrom); onCompletion(true); dismiss()
        } else { onCompletion(false) }
    }
}

// MARK: - SubcategoryListView, AddSubcategoryView, ReassignSubcategoryTransactionsView (largely same as before, with direct reassign flow)
struct SubcategoryListView: View { /* ... (adapt swipe action like CategoryManagerView) ... */
    @EnvironmentObject var dataController: DataController
    @Bindable var category: Category
    @State private var subcategoryToAction: Subcategory?
    @State private var showingSubConfirmDirectDeleteDialog = false
    @State private var showingSubReassignSheet = false
    @State private var targetSubcategoryIDForReassignment: PersistentIdentifier?
    @State private var showingAddSubcategorySheet = false

    var body: some View {
        List {
            Section(header: Text("Subcategories of \"\(category.name)\"")) {
                if category.subcategories.isEmpty { Text("No subcategories yet.").foregroundColor(.secondary) }
                ForEach(category.subcategories.sorted(by: { $0.order < $1.order }), id: \.id) { subcategory in
                    HStack { Text(subcategory.name); Spacer(); Text("(\(dataController.hasTransactions(subcategory: subcategory) ? "Has Tx" : "No Tx"))").font(.caption2).foregroundColor(.gray) }
                    .swipeActions {
                        Button(role: .destructive) {
                            self.subcategoryToAction = subcategory
                            if dataController.hasTransactions(subcategory: subcategory) {
                                targetSubcategoryIDForReassignment = category.subcategories.first(where: { $0.id != subcategory.id })?.id
                                self.showingSubReassignSheet = true
                            } else {
                                self.showingSubConfirmDirectDeleteDialog = true
                            }
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
        }
        .navigationTitle("Manage Subcategories")
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { showingAddSubcategorySheet = true } label: { Label("Add Subcategory", systemImage: "plus") } } }
        .sheet(isPresented: $showingAddSubcategorySheet) { AddSubcategoryView(category: category).environmentObject(dataController) }
        .confirmationDialog("Delete Subcategory: \"\(subcategoryToAction?.name ?? "")\"?", isPresented: $showingSubConfirmDirectDeleteDialog, presenting: subcategoryToAction) { subcatAction in
            Button("Delete Subcategory", role: .destructive) { dataController.deleteSubcategory(subcatAction, from: category); subcategoryToAction = nil }
            Button("Cancel", role: .cancel) { subcategoryToAction = nil }
        } message: { subcatAction in Text("Are you sure? \"\(subcatAction.name)\" has no transactions.") }
        .sheet(isPresented: $showingSubReassignSheet) {
            if let subFrom = subcategoryToAction {
                ReassignSubcategoryTransactionsView(parentCategory: category, subcategoryToReassignFrom: subFrom, selectedTargetSubcategoryID: $targetSubcategoryIDForReassignment) { success in
                    showingSubReassignSheet = false
                    if success { print("Subcategory reassigned/deleted.") } else { print("Subcategory reassignment failed.") }
                    subcategoryToAction = nil
                }.environmentObject(dataController)
            }
        }
    }
}

struct AddSubcategoryView: View { /* ... (same as previous version) ... */
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let category: Category
    @State private var subcategoryName: String = ""
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Adding to: \(category.name)")) { TextField("New Subcategory Name", text: $subcategoryName) }
                Button("Add Subcategory") { if !subcategoryName.isEmpty { dataController.addSubcategory(to: category, name: subcategoryName); dismiss() } }.disabled(subcategoryName.isEmpty)
            }
            .navigationTitle("New Subcategory").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct ReassignSubcategoryTransactionsView: View { /* ... (same as previous version) ... */
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    let parentCategory: Category
    let subcategoryToReassignFrom: Subcategory
    @Binding var selectedTargetSubcategoryID: PersistentIdentifier?
    var onCompletion: (Bool) -> Void
    var availableTargetSubcategories: [Subcategory] { parentCategory.subcategories.filter { $0.id != subcategoryToReassignFrom.id } }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign transactions from \"\(subcategoryToReassignFrom.name)\" to another subcategory in \"\(parentCategory.name)\":")) {
                    if availableTargetSubcategories.isEmpty { Text("No other subcategories available.").foregroundColor(.orange) }
                    else {
                        Picker("Target Subcategory", selection: $selectedTargetSubcategoryID) {
                            Text("Select...").tag(nil as PersistentIdentifier?); ForEach(availableTargetSubcategories) { subcat in Text(subcat.name).tag(subcat.id as PersistentIdentifier?) }
                        }.labelsHidden()
                    }
                }
                Section { Button("Reassign and Delete Original Subcategory") { handleReassignAndSubDelete() }.disabled(selectedTargetSubcategoryID == nil || availableTargetSubcategories.isEmpty) }
            }
            .navigationTitle("Select Target Subcategory").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onCompletion(false); dismiss() } } }
            .onAppear { if selectedTargetSubcategoryID == nil, let first = availableTargetSubcategories.first { selectedTargetSubcategoryID = first.id } }
        }
    }
    private func handleReassignAndSubDelete() {
        guard let targetID = selectedTargetSubcategoryID, let targetSub = availableTargetSubcategories.first(where: { $0.id == targetID }) else { onCompletion(false); return }
        if dataController.reassignTransactions(from: subcategoryToReassignFrom, to: targetSub) {
            dataController.deleteSubcategory(subcategoryToReassignFrom, from: parentCategory); onCompletion(true); dismiss()
        } else { onCompletion(false) }
    }
}

// MARK: - Project Views (Updated for direct reassign and "None" option)
struct ProjectDetailView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @Bindable var project: Project

    @State private var showingConfirmDirectDeleteProjectDialog = false
    @State private var showingReassignProjectSheet = false
    @State private var targetProjectIDForReassignment: PersistentIdentifier? // Can be nil for "No Project"

    var body: some View {
        List {
            Section("Project Details") {
                Text("Name: \(project.name)")
                Text("Has Transactions: \(dataController.hasTransactions(project: project) ? "Yes" : "No")")
            }
            Section("Actions") {
                Button("Delete Project", role: .destructive) {
                    if dataController.hasTransactions(project: project) {
                        targetProjectIDForReassignment = dataController.projects.first(where: { $0.id != project.id })?.id // Pre-select or default to nil in sheet
                        self.showingReassignProjectSheet = true
                    } else {
                        self.showingConfirmDirectDeleteProjectDialog = true
                    }
                }
            }
        }
        .navigationTitle(project.name)
        .confirmationDialog("Delete Project: \"\(project.name)\"?", isPresented: $showingConfirmDirectDeleteProjectDialog) {
            Button("Delete Project", role: .destructive) { dataController.deleteProject(project); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure? \"\(project.name)\" has no transactions.") }
        .sheet(isPresented: $showingReassignProjectSheet) {
            // Ensure 'project' is still valid (e.g., not deleted by another process if app is complex)
             if let currentProject = dataController.projects.first(where: {$0.id == project.id}) {
                 ReassignProjectTransactionsView(projectToReassignFrom: currentProject, selectedTargetProjectID: $targetProjectIDForReassignment) { success in
                    showingReassignProjectSheet = false
                    if success { print("Project operation completed."); dismiss() } else { print("Project operation failed/cancelled.") }
                 }.environmentObject(dataController)
             } else {
                 // Handle case where project might have been deleted in the meantime
                 Text("Project data is no longer available.")
                     .onAppear {
                         showingReassignProjectSheet = false // Dismiss sheet if project is gone
                         dismiss() // Dismiss detail view
                     }
             }
        }
    }
}

struct AddProjectView: View { /* ... (same as previous version) ... */
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var projectName: String = ""
    var body: some View {
        NavigationView {
            Form { TextField("Project Name", text: $projectName)
                Button("Add Project") { if !projectName.isEmpty { dataController.addProject(name: projectName); dismiss() } }.disabled(projectName.isEmpty)
            }
            .navigationTitle("New Project").toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

struct ReassignProjectTransactionsView: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss

    let projectToReassignFrom: Project
    @Binding var selectedTargetProjectID: PersistentIdentifier? // This is an Optional<PersistentIdentifier>
    var onCompletion: (Bool) -> Void

    private let noProjectTag: PersistentIdentifier? = nil // Explicit nil for "No Project" option

    var availableTargetProjects: [Project] {
        dataController.projects.filter { $0.id != projectToReassignFrom.id }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign transactions from \"\(projectToReassignFrom.name)\" to:")) {
                    Picker("Target Project", selection: $selectedTargetProjectID) {
                        Text("No Project (Clear Project Field)").tag(noProjectTag) // "None" option
                        ForEach(availableTargetProjects) { proj in
                            Text(proj.name).tag(proj.id as PersistentIdentifier?) // Tag with optional ID
                        }
                    }
                }
                Section {
                    Button("Apply Change and Delete Original Project") {
                        handleReassignAndDeleteProject()
                    }
                    // Button is always enabled because "No Project" is a valid selection
                }
            }
            .navigationTitle("Select Target for Project Tx")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onCompletion(false); dismiss() } } }
            .onAppear {
                // If no pre-selection, default to "No Project" or first available
                if selectedTargetProjectID == nil { // Only if not already set by caller
                    selectedTargetProjectID = availableTargetProjects.first?.id ?? noProjectTag
                }
            }
        }
    }

    private func handleReassignAndDeleteProject() {
        var operationSuccess = false
        if let targetID = selectedTargetProjectID { // A specific project is chosen
            if let targetProj = availableTargetProjects.first(where: { $0.id == targetID }) {
                operationSuccess = dataController.reassignTransactions(from: projectToReassignFrom, to: targetProj)
            } else {
                print("Error: Selected target project for reassignment not found.")
                onCompletion(false); return
            }
        } else { // "No Project" (nil) was chosen
            operationSuccess = dataController.clearProjectFromTransactions(of: projectToReassignFrom)
        }

        if operationSuccess {
            dataController.deleteProject(projectToReassignFrom) // Now delete the original project
            onCompletion(true); dismiss()
        } else {
            print("Error: Project transaction operation (reassign to other or nil) failed.")
            onCompletion(false)
        }
    }
}
