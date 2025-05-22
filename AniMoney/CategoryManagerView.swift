import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Category & Project Management View
struct CategoryManagerView: View {
    @EnvironmentObject private var dc: DataController
    @State private var showAddCategory   = false
    @State private var showAddProject    = false

    var body: some View {
        NavigationStack {
            List {
                // — Categories
                Section(header:
                    HStack {
                        Text("Categories")
                        Spacer()
                        Button { showAddCategory = true }
                        label: { Image(systemName: "plus") }
                    }
                ) {
                    ForEach(dc.categories) { cat in
                        NavigationLink(value: cat) {
                            Text(cat.name)
                        }
                    }
                }

                // — Projects
                Section(header:
                    HStack {
                        Text("Projects")
                        Spacer()
                        Button { showAddProject = true }
                        label: { Image(systemName: "plus") }
                    }
                ) {
                    ForEach(dc.projects) { proj in
                        Text(proj.name)
                    }
                }
            }
            .navigationTitle("Classification Manager")
            .navigationDestination(for: Category.self) { cat in
                SubcategoryListView(category: cat)
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView()
                    .environmentObject(dc)
            }
            .sheet(isPresented: $showAddProject) {
                AddProjectView()
                    .environmentObject(dc)
            }
        }
    }
}


struct SubcategoryListView: View {
    @EnvironmentObject private var dc: DataController
    let category: Category
    @State private var showAddSub = false

    var subcategories: [Subcategory] {
        category.subcategories.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            Section(header:
                HStack {
                    Text(category.name)
                    Spacer()
                    Button { showAddSub = true }
                    label: { Image(systemName: "plus") }
                }
            ) {
                ForEach(subcategories) { sub in
                    Text(sub.name)
                }
            }
        }
        .navigationTitle("Subcategories")
        .sheet(isPresented: $showAddSub) {
            AddSubcategoryView(category: category)
                .environmentObject(dc)
        }
    }
}


// MARK: - Add Category View
struct AddCategoryView: View {
    @EnvironmentObject private var dc: DataController
    @Environment(\.dismiss)   private var dismiss
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            Form { TextField("Category Name", text: $name) }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dc.addCategory(name: name)
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
    @EnvironmentObject private var dc: DataController
    @Environment(\.dismiss)   private var dismiss
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            Form { TextField("Project Name", text: $name) }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dc.addProject(name: name)
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
    @EnvironmentObject private var dc: DataController
    @Environment(\.dismiss)   private var dismiss
    let category: Category
    @State private var name: String = ""

    var body: some View {
        NavigationView {
            Form { TextField("Subcategory Name", text: $name) }
            .navigationTitle("New Subcategory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dc.addSubcategory(to: category, name: name)
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
