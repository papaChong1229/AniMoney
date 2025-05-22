import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Category & Project Management View
struct CategoryManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.order, order: .forward) private var categories: [Category]
    @Query(sort: \Project.order, order: .forward) private var projects: [Project]

    @State private var showAddCategory = false
    @State private var showAddProject  = false

    var body: some View {
        NavigationStack {
            List {
                // Categories Section
                Section(header:
                    HStack {
                        Text("Categories")
                        Spacer()
                        Button(action: { showAddCategory = true }) {
                            Image(systemName: "plus")
                        }
                    }
                ) {
                    ForEach(categories) { category in
                        NavigationLink(value: category) {
                            Text(category.name)
                        }
                    }
                }
                
                // Projects Section
                Section(header:
                    HStack {
                        Text("Projects")
                        Spacer()
                        Button(action: { showAddProject = true }) {
                            Image(systemName: "plus")
                        }
                    }
                ) {
                    ForEach(projects) { project in
                        Text(project.name)
                    }
                }
            }
            .navigationTitle("Classification Manager")
            // Navigation to subcategories
            .navigationDestination(for: Category.self) { category in
                SubcategoryListView(category: category)
            }
            // Modals for adding
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView()
            }
            .sheet(isPresented: $showAddProject) {
                AddProjectView()
            }
        }
    }
}

// MARK: - Subcategory List & Add View
struct SubcategoryListView: View {
    @Environment(\.modelContext) private var modelContext
    let category: Category
    @State private var showAddSubcategory = false

    var subcategories: [Subcategory] {
        category.subcategories.sorted(by: { $0.order < $1.order })
    }

    var body: some View {
        List {
            Section(header:
                HStack {
                    Text(category.name)
                    Spacer()
                    Button(action: { showAddSubcategory = true }) {
                        Image(systemName: "plus")
                    }
                }
            ) {
                ForEach(subcategories) { sub in
                    Text(sub.name)
                }
            }
        }
        .navigationTitle("Subcategories")
        .sheet(isPresented: $showAddSubcategory) {
            AddSubcategoryView(category: category)
        }
    }
}

// MARK: - Add Category View
struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.order, order: .forward) private var categories: [Category]
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Category Name", text: $name)
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let nextOrder = (categories.map(\ .order).max() ?? -1) + 1
                        let cat = Category(name: name, order: nextOrder)
                        modelContext.insert(cat)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Project View
struct AddProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.order, order: .forward) private var projects: [Project]
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Project Name", text: $name)
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let nextOrder = (projects.map(\ .order).max() ?? -1) + 1
                        let proj = Project(name: name, order: nextOrder)
                        modelContext.insert(proj)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Add Subcategory View
struct AddSubcategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let category: Category
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Subcategory Name", text: $name)
            }
            .navigationTitle("New Subcategory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let existing = category.subcategories
                        let nextOrder = (existing.map(\ .order).max() ?? -1) + 1
                        let sub = Subcategory(name: name, order: nextOrder)
                        category.subcategories.append(sub)
                        modelContext.insert(sub)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CategoryManagerView()
        .modelContainer(for: [Category.self, Subcategory.self, Project.self, Transaction.self])
}
