//
//  DarokuApp.swift
//  Daroku
//

import SwiftUI

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
        }
    }
}
