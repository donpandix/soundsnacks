import SwiftUI
import SwiftData
import AVFoundation

@Model
class Sound {
    @Attribute(.unique) var id: UUID
    var descripcion: String
    var fileName: String
    var filePath: String
    var duration: TimeInterval
    var order: Int
    @Relationship var category: Category?
    
    init(descripcion: String, fileName: String, filePath: String, duration: TimeInterval, order: Int, category: Category? = nil) {
        self.id = UUID()
        self.descripcion = descripcion
        self.fileName = fileName
        self.filePath = filePath
        self.duration = duration
        self.order = order
        self.category = category
    }
    
    func loadData() -> Data? {
        let url = URL(fileURLWithPath: filePath)
        return try? Data(contentsOf: url)
    }
}