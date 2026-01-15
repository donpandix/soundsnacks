import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AddSoundView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Sound.order) private var sounds: [Sound]
    
    @State private var soundName = ""
    @State private var category = ""
    @State private var selectedFile: URL?
    @State private var showFilePicker = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var isFormValid: Bool {
        let hasName = !soundName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasCategory = !category.trimmingCharacters(in: .whitespaces).isEmpty
        let hasFile = selectedFile != nil
        return hasName && hasCategory && hasFile
    }
    
    var body: some View {
        NavigationStack {
            Form {
                infoSection
                audioSection
                errorSection
            }
            .navigationTitle("Agregar Sonido")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isLoading ? "Guardando..." : "Guardar") {
                        saveSound()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [
                    UTType(filenameExtension: "mp3") ?? .audio,
                    UTType(filenameExtension: "wav") ?? .audio,
                    UTType(filenameExtension: "m4a") ?? .audio
                ],
                onCompletion: { result in
                    if case .success(let url) = result {
                        selectedFile = url
                        errorMessage = ""
                    }
                }
            )
        }
    }
    
    private var infoSection: some View {
        Section("Información del sonido") {
            TextField("Nombre del sonido", text: $soundName)
                .onChange(of: soundName) { _ in errorMessage = "" }

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
                .onAppear {
                    if category.trimmingCharacters(in: .whitespaces).isEmpty {
                        category = categories.first?.name ?? ""
                    }
                }
            }
        }
    }
    
    private var audioSection: some View {
        Section("Archivo de audio") {
            if let file = selectedFile {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.lastPathComponent)
                            .font(.body)
                            .lineLimit(1)
                        Text(formatFileSize(file))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: { self.selectedFile = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            } else {
                Text("No hay archivo seleccionado")
                    .foregroundColor(.gray)
            }
            
            Button(action: { showFilePicker = true }) {
                Label("Seleccionar archivo", systemImage: "folder")
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
    
    private func saveSound() {
        // Validación
        let trimmedName = soundName.trimmingCharacters(in: .whitespaces)
        let trimmedCategory = category.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "El nombre del sonido no puede estar vacío"
            return
        }
        
        guard !trimmedCategory.isEmpty else {
            errorMessage = "La categoría no puede estar vacía"
            return
        }
        
        guard let fileURL = selectedFile else {
            errorMessage = "Debe seleccionar un archivo de audio"
            return
        }
        
        // Validar extensión
        let validExtensions = ["mp3", "wav", "m4a"]
        let fileExtension = fileURL.pathExtension.lowercased()
        
        guard validExtensions.contains(fileExtension) else {
            errorMessage = "Solo se aceptan archivos MP3, WAV o M4A"
            return
        }
        
        isLoading = true
        
        let soundId = UUID().uuidString
        let soundOrder = sounds.count + 1
        let soundsFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Sounds")
        
        try? FileManager.default.createDirectory(at: soundsFolderPath, withIntermediateDirectories: true)
        
        // Use a unique filename to avoid collisions
        let uniqueFileName = UUID().uuidString + "." + fileExtension
        let destinationURL = soundsFolderPath.appendingPathComponent(uniqueFileName)

        // Start accessing security-scoped resource
        let hasAccess = fileURL.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try FileManager.default.copyItem(at: fileURL, to: destinationURL)

            let newSound = Sound(
                id: soundId,
                descripcion: trimmedName,
                assetName: nil,
                fileName: uniqueFileName,
                fileExtension: fileExtension,
                category: trimmedCategory,
                order: soundOrder,
                isCustom: true
            )

            modelContext.insert(newSound)
            try modelContext.save()

            isLoading = false
            dismiss()
        } catch {
            errorMessage = "Error al guardar: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func formatFileSize(_ url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? NSNumber {
                let bytes = size.int64Value
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useKB, .useMB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: bytes)
            }
        } catch {
            return ""
        }
        return ""
    }
}
