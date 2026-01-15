import SwiftUI
import SwiftData

struct EditSoundView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @Bindable var sound: Sound
    
    @State private var soundName: String
    @State private var category: String
    @State private var order: String
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    init(sound: Sound) {
        self.sound = sound
        _soundName = State(initialValue: sound.descripcion)
        _category = State(initialValue: sound.category)
        _order = State(initialValue: String(sound.order))
    }
    
    var isFormValid: Bool {
        let hasName = !soundName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasCategory = !category.trimmingCharacters(in: .whitespaces).isEmpty
        let hasOrder = Int(order.trimmingCharacters(in: .whitespaces)) != nil
        return hasName && hasCategory && hasOrder
    }
    
    var body: some View {
        NavigationStack {
            Form {
                infoSection
                errorSection
            }
            .navigationTitle("Editar Sonido")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isLoading ? "Guardando..." : "Guardar") {
                        saveChanges()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    private var infoSection: some View {
        Section("Información del sonido") {
            TextField("Nombre del sonido", text: $soundName)
                .onChange(of: soundName) { _ in
                    errorMessage = ""
                }
            
            if categories.isEmpty {
                TextField("Categoría", text: $category)
                    .onChange(of: category) { _ in errorMessage = "" }
            } else {
                Picker(selection: $category) {
                    ForEach(categories, id: \.id) { cat in
                        Text(cat.name).tag(cat.name)
                    }
                } label: {
                    Text("Categoría")
                }
            }
            
            TextField("Orden", text: $order)
                .onChange(of: order) { _ in
                    errorMessage = ""
                }
        }
    }
    
    private var errorSection: some View {
        Group {
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
    
    private func saveChanges() {
        let trimmedName = soundName.trimmingCharacters(in: .whitespaces)
        let trimmedCategory = category.trimmingCharacters(in: .whitespaces)
        let trimmedOrder = order.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "El nombre del sonido no puede estar vacío"
            return
        }
        
        guard !trimmedCategory.isEmpty else {
            errorMessage = "La categoría no puede estar vacía"
            return
        }
        
        guard let orderInt = Int(trimmedOrder), orderInt > 0 else {
            errorMessage = "El orden debe ser un número positivo"
            return
        }
        
        isLoading = true
        
        sound.descripcion = trimmedName
        sound.category = trimmedCategory
        sound.order = orderInt
        
        try? modelContext.save()
        
        isLoading = false
        dismiss()
    }
}
