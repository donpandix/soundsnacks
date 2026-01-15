import SwiftUI
import SwiftData
#if canImport(AppKit)
import AppKit
#endif

struct CategoryManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var showingAdd = false
    @State private var editingCategory: Category?
    #if canImport(AppKit)
    @State private var formWindows: [NSWindow] = []
    #endif
    @State private var categoryToDelete: Category?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
                ForEach(categories) { category in
                    HStack {
                        Circle()
                            .fill(category.color)
                            .frame(width: 20, height: 20)
                        Text(category.name)
                        Spacer()
                        Button("Editar") {
                            openCategoryFormWindow(category: category)
                        }
                        .buttonStyle(.bordered)
                        .disabled(category.name == "Sin categoría")
                        .opacity(category.name == "Sin categoría" ? 0.6 : 1)
                        if category.name == "Sin categoría" {
                            Text("Por defecto")
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .padding(.leading, 8)
                        } else {
                            Button("Eliminar") {
                                categoryToDelete = category
                                showDeleteConfirmation = true
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Categorías")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { openCategoryFormWindow(category: nil) }) {
                        Label("Agregar", systemImage: "plus")
                    }
                }
            }
        // On macOS we open the form in a new window to force a fixed size

        .alert("Borrar Categoría", isPresented: $showDeleteConfirmation, presenting: categoryToDelete) { category in
            Button("Cancelar", role: .cancel) { categoryToDelete = nil }
            Button("Borrar", role: .destructive) {
                if let cat = categoryToDelete {
                    modelContext.delete(cat)
                    try? modelContext.save()
                    categoryToDelete = nil
                }
            }
        } message: { category in
            Text("¿Estás seguro de que deseas borrar la categoría '\(category.name)'? Esta acción no se puede deshacer.")
        }

        .onAppear {
            if categories.isEmpty {
                addDefaultCategories()
            }
        }
    }
    
    private func addDefaultCategories() {
        // Always add a non-deletable default category first (handled by name)
        let defaultExists = categories.contains { $0.name == "Sin categoría" }
        if !defaultExists {
            let def = Category(name: "Sin categoría", colorHex: "#808080")
            modelContext.insert(def)
        }
        let defaults = [
            ("Gritos", "#FF0000"),
            ("Saludos", "#00FF00"),
            ("Golpes", "#EBB04B"),
            ("Disparos", "#4B5EAA"),
            ("Risas", "#FFFF00"),
            ("Burlas", "#800080"),
            ("Victorias", "#FFD700"),
            ("Derrotas", "#808080"),
            ("Animales", "#8B4513"),
            ("Memes", "#FF69B4"),
            ("Efectos Mágicos", "#FF00FF"),
            ("Sonidos Locos", "#FF4500")
        ]
        for (name, hex) in defaults {
            // Avoid inserting duplicates if already present
            if !categories.contains(where: { $0.name == name }) {
                let cat = Category(name: name, colorHex: hex)
                modelContext.insert(cat)
            }
        }
        try? modelContext.save()
    }

    private func openCategoryFormWindow(category: Category?) {
        #if canImport(AppKit)
        let content = CategoryFormView(category: category)
            .environment(\.modelContext, modelContext)
        let hosting = NSHostingController(rootView: content)
        let window = NSWindow(contentViewController: hosting)
        window.setContentSize(NSSize(width: 500, height: 400))
        window.styleMask = [.titled, .closable, .resizable]
        window.title = category == nil ? "Nueva Categoría" : "Editar Categoría"
        window.center()
        window.makeKeyAndOrderFront(nil)
        formWindows.append(window)
        #endif
    }
}

struct CategoryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var selectedColor: Color
    @Query private var categories: [Category]
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    let category: Category?
    
    init(category: Category?) {
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _selectedColor = State(initialValue: category?.color ?? .gray)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header and inputs
            VStack(alignment: .leading, spacing: 8) {
                Text(category == nil ? "Nueva Categoría" : "Editar Categoría")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)

                VStack(spacing: 8) {
                    TextField("Nombre", text: $name)
                        .textFieldStyle(.roundedBorder)
                    ColorPicker("Color", selection: $selectedColor)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            Spacer()

            // Action buttons fixed at bottom
            HStack {
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Guardar") {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        validationMessage = "El nombre no puede estar vacío"
                        showValidationAlert = true
                        return
                    }

                    let exists = categories.contains { cat in
                        cat.name.lowercased() == trimmed.lowercased() && cat.id != category?.id
                    }
                    if exists {
                        validationMessage = "Ya existe una categoría con ese nombre"
                        showValidationAlert = true
                        return
                    }

                    if let category = category {
                        if category.name == "Sin categoría" {
                            validationMessage = "No puedes modificar la categoría por defecto"
                            showValidationAlert = true
                            return
                        }
                        category.name = trimmed
                        category.color = selectedColor
                    } else {
                        let newCat = Category(name: trimmed, colorHex: selectedColor.toHex() ?? "#000000")
                        modelContext.insert(newCat)
                    }
                    try? modelContext.save()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(minHeight: 500)
        .frame(maxWidth: .infinity)
        .alert(validationMessage, isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}
#Preview {
    NavigationStack {
        CategoryManagerView()
    }
}

