//
//  PersistenceController.swift
//  Daroku
//

import CoreData

@MainActor
final class PersistenceController: Sendable {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Daroku")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }

    // MARK: - Preview Helper

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // サンプルデータを作成
        let sampleSoftware = TypingSoftware(context: context)
        sampleSoftware.id = UUID()
        sampleSoftware.name = "寿司打"
        sampleSoftware.unit = "円"
        sampleSoftware.createdAt = Date()

        let sampleRecord = Record(context: context)
        sampleRecord.id = UUID()
        sampleRecord.date = Date()
        sampleRecord.score = 4620
        sampleRecord.correctKeys = 443
        sampleRecord.mistypes = 63
        sampleRecord.avgKeysPerSec = 3.5
        sampleRecord.typingSoftware = sampleSoftware

        do {
            try context.save()
        } catch {
            print("Preview save error: \(error)")
        }

        return controller
    }()
}
