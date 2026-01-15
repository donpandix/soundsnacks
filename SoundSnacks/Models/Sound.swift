import Foundation
import SwiftData

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Model
final class Sound {
    @Attribute(.unique) var id: String
    var descripcion: String
    var assetName: String?
    var fileName: String?
    var fileExtension: String?
    var category: String
    var order: Int
    var isCustom: Bool

    init(id: String, descripcion: String, assetName: String? = nil, fileName: String? = nil, fileExtension: String? = nil, category: String, order: Int, isCustom: Bool) {
        self.id = id
        self.descripcion = descripcion
        self.assetName = assetName
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.category = category
        self.order = order
        self.isCustom = isCustom
    }

    func loadData() -> Data? {
        if let name = assetName {
            #if canImport(UIKit) || canImport(AppKit)
            if let dataAsset = NSDataAsset(name: name) {
                return dataAsset.data
            } else {
                print("NSDataAsset no encontrado: \(name)")
            }
            #endif
        }
        if let fileName = fileName, let ext = fileExtension {
            let soundsFolderPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Sounds")
            let fileURL = soundsFolderPath.appendingPathComponent(fileName)
            if let data = try? Data(contentsOf: fileURL) {
                return data
            }
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext),
               let data = try? Data(contentsOf: url) {
                return data
            }
        }
        if let fileName = fileName, let ext = fileExtension {
            print("Archivo no encontrado: \(fileName).\(ext)")
        }
        return nil
    }
}
