//
//  DarokuApp.swift
//  Daroku
//

import SwiftUI

/// タイピング練習の記録を管理するmacOSアプリケーションのエントリーポイント
@main
struct DarokuApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1000, height: 700)
        .commands {
            SidebarCommands()
            ToolbarCommands()
            CommandGroup(replacing: .help) {
                Button("打録 ヘルプ") {
                    HelpView.openWindow()
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }
}
