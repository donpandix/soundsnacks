//
//  SoundSnacksApp.swift
//  SoundSnacks
//
//  Created by Cesar Gonzalez Molina on 10-01-26.
//

import SwiftUI
import SwiftData

@main
struct SoundSnacksApp: App {
    var body: some Scene {
        WindowGroup {
            let fixedWidth: CGFloat = 1200
            let fixedHeight: CGFloat = 800
            ContentView()
                .frame(width: fixedWidth, height: fixedHeight)
        }
        .defaultSize(width: 1200, height: 800)
        .windowResizability(.contentSize)
        .modelContainer(for: [Sound.self, Category.self])
        .commands {
            CommandMenu("Categorías") {
                Button("Gestionar Categorías") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowCategoryManager"), object: nil)
                }
            }
        }
        
        Window("Gestor de Categorías", id: "categoryManager") {
            CategoryManagerView()
        }
        .modelContainer(for: [Sound.self, Category.self])
    }
}
