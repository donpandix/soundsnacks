import SwiftUI
import SwiftData

@Model
class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    
    init(name: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
    }
    
    var color: Color {
        get { Color(hex: colorHex) ?? .gray }
        set { colorHex = newValue.toHex() ?? "#000000" }
    }
}

extension Color {
    init?(hex: String) {
        let r, g, b, a: Double
        
        let start = hex.hasPrefix("#") ? hex.index(hex.startIndex, offsetBy: 1) : hex.startIndex
        let hexColor = String(hex[start...])
        
        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = Double((hexNumber & 0xff0000) >> 16) / 255
                g = Double((hexNumber & 0x00ff00) >> 8) / 255
                b = Double(hexNumber & 0x0000ff) / 255
                a = 1.0
                
                self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
                return
            }
        }
        
        return nil
    }
    
    func toHex() -> String? {
        guard let components = cgColor?.components, components.count >= 3 else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}