import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var store = SoundStore()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sound.order) private var sounds: [Sound]
    @Query private var categories: [Category]

    @State private var showAddSoundSheet = false
    @State private var selectedSoundForEdit: Sound?
    @State private var soundToDelete: Sound?
    @State private var showDeleteAlert = false
    @State private var showCategoryManager = false

    // Reordering state
    @State private var isReordering = false
    @State private var draggedSoundID: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                Divider()
                gridArea
            }
            .navigationDestination(isPresented: $showCategoryManager) {
                CategoryManagerView()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !isReordering {
                        Button(action: { isReordering = true }) { Label("Reordenar", systemImage: "arrow.up.arrow.down") }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSoundSheet) { AddSoundView() }
        .sheet(item: $selectedSoundForEdit) { sound in EditSoundView(sound: sound) }
        .alert("Borrar Sonido", isPresented: $showDeleteAlert, presenting: soundToDelete) { sound in
            Button("Cancelar", role: .cancel) { }
            Button("Borrar", role: .destructive) { deleteSound(sound) }
        } message: { sound in
            Text("¿Estás seguro de que deseas borrar '\(sound.descripcion)'? Esta acción no se puede deshacer.")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowCategoryManager"))) { _ in
            showCategoryManager = true
        }
        .onAppear { store.load() }
    }

    // MARK: - Subviews
    private var header: some View {
        HStack {
            Text("SoundSnacks")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()

            if !isReordering {
                Button("Reordenar") { isReordering = true }
                    .buttonStyle(.bordered)
            }

            if isReordering {
                Button("Terminar ordenamiento") { isReordering = false }
                    .buttonStyle(.borderedProminent)
            }

            Button(action: { showAddSoundSheet = true }) {
                Label("Agregar", systemImage: "plus.circle.fill").font(.system(size: 16))
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.top, 22)
        .padding(.bottom, 12)
    }

    private var gridArea: some View {
        GeometryReader { geo in
            let columnsCount = 8
            let rowsCount = 4
            let spacing: CGFloat = 16
            let hPadding: CGFloat = 16
            let vPadding: CGFloat = 20

            let availableWidth = geo.size.width - (hPadding * 2) - (spacing * CGFloat(columnsCount - 1))
            let availableHeight = geo.size.height - (vPadding * 2) - (spacing * CGFloat(rowsCount - 1))
            let tileSize = min(max(1, availableWidth / CGFloat(columnsCount)), max(1, availableHeight / CGFloat(rowsCount)))

            let columns = Array(repeating: GridItem(.fixed(tileSize), spacing: spacing), count: columnsCount)

            if sounds.isEmpty {
                VStack {
                    Spacer()
                    Text("Agrega nuevos sonidos (mp3, wav o m4a) con el botón \"+\"")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(sounds) { sound in
                            soundButton(for: sound, size: tileSize)
                                .id(sound.id + sound.descripcion)
                                .onDrag {
                                    draggedSoundID = sound.id
                                    return NSItemProvider(object: NSString(string: sound.id))
                                }
                                .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
                                    guard let provider = providers.first else { return false }
                                    _ = provider.loadObject(ofClass: NSString.self) { ns, _ in
                                        DispatchQueue.main.async {
                                            guard let idStr = ns as? String else { return }
                                            reorderSound(draggedId: idStr, to: sound.id)
                                        }
                                    }
                                    return true
                                }
                        }
                    }
                    .padding(.horizontal, hPadding)
                    .padding(.vertical, vPadding)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    private func soundButton(for sound: Sound, size: CGFloat) -> some View {
        // Compute font sizes relative to tile size; category label is 50% of title
        let titleSize: CGFloat = max(12, min(20, size * 0.12))
        let categorySize: CGFloat = max(8, titleSize * 0.5)

        return Button(action: { if !isReordering { store.toggle(sound) } }) {
            ZStack {
                colorForCategory(name: sound.category)
                VStack(spacing: 6) {
                    VStack(spacing: 6) {
                        Text(sound.descripcion)
                            .multilineTextAlignment(.center)
                            .font(.system(size: titleSize, weight: .semibold))
                            .foregroundColor(contrastColor(forCategoryName: sound.category))
                            .padding(.horizontal, 8)
                            .padding(.top, 10) // added 10px extra distance from top border

                        if store.isPlaying(sound) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption2)
                                .foregroundColor(contrastColor(forCategoryName: sound.category))
                        } else if store.isPaused(sound) {
                            Text("Pausado").font(.caption2).foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Category label: centered and anchored near the bottom
                    Text(sound.category)
                        .multilineTextAlignment(.center)
                        .font(.system(size: categorySize))
                        .foregroundColor(contrastColor(forCategoryName: sound.category))
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: size, height: size)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 210/255, green: 216/255, blue: 219/255), lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: { if !isReordering { selectedSoundForEdit = sound } }) { Label("Editar", systemImage: "pencil") }
            Button(role: .destructive) {
                if !isReordering { soundToDelete = sound; showDeleteAlert = true }
            } label: { Label("Borrar", systemImage: "trash") }
            Divider()
            Button(action: { isReordering = true }) { Label("Reordenar", systemImage: "arrow.up.arrow.down") }
        }
    }

    // MARK: - Actions
    private func deleteSound(_ sound: Sound) {
        if let fileName = sound.fileName {
            let soundsFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Sounds")
            let soundPath = soundsFolderPath.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: soundPath)
        }
        modelContext.delete(sound)
        try? modelContext.save()
        store.sounds.removeAll { $0.id == sound.id }
    }

    // Reordering: insert dragged item at destination index and persist
    private func reorderSound(draggedId: String, to destId: String) {
        guard draggedId != destId else { return }
        var ordered = sounds
        guard let sourceIndex = ordered.firstIndex(where: { $0.id == draggedId }),
              let destIndex = ordered.firstIndex(where: { $0.id == destId }) else { return }

        let moving = ordered.remove(at: sourceIndex)
        ordered.insert(moving, at: destIndex)

        for (i, s) in ordered.enumerated() {
            s.order = i + 1
        }
        try? modelContext.save()
    }

    // MARK: - Helpers
    private func colorForCategory(name: String) -> Color {
        if let cat = categories.first(where: { $0.name == name }) { return cat.color }
        return Color(red: 235/255, green: 240/255, blue: 242/255)
    }

    private func contrastColor(forCategoryName name: String) -> Color {
        if let cat = categories.first(where: { $0.name == name }) {
            let hex = cat.colorHex.trimmingCharacters(in: .whitespacesAndNewlines)
            if let (r,g,b) = rgbFromHex(hex) {
                let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                return lum < 0.5 ? .white : .black
            }
            return .black
        }
        return .black
    }

    private func rgbFromHex(_ hex: String) -> (Double, Double, Double)? {
        var hexColor = hex
        if hexColor.hasPrefix("#") { hexColor.removeFirst() }
        guard hexColor.count == 6 else { return nil }
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0
        guard scanner.scanHexInt64(&hexNumber) else { return nil }
        let r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
        let b = Double(hexNumber & 0x0000FF) / 255.0
        return (r,g,b)
    }
}