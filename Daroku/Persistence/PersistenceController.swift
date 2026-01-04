//
//  PersistenceController.swift
//  Daroku
//

import CoreData
import OSLog

/// Core Dataの永続化ストア読み込み時に発生するエラー
enum PersistenceError: LocalizedError {
    /// 永続化ストアの読み込みに失敗した場合
    case failedToLoadStore(Error)

    var errorDescription: String? {
        switch self {
        case let .failedToLoadStore(error):
            "Failed to load Core Data stack: \(error.localizedDescription)"
        }
    }
}

/// Core Dataの管理クラス。永続化ストアとマネージドオブジェクトコンテキストを管理する
@MainActor
final class PersistenceController: Sendable {
    static let shared: PersistenceController = {
        do {
            return try PersistenceController()
        } catch {
            logger.error("Failed to initialize PersistenceController: \(error.localizedDescription, privacy: .public)")
            // エラーが発生した場合でも、メモリ内ストアでフォールバック
            return makeInMemoryController(context: "shared")
        }
    }()

    let container: NSPersistentContainer

    private static let logger = Logger(subsystem: "com.daroku", category: "PersistenceController")

    /// メインスレッドで使用するマネージドオブジェクトコンテキスト
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// 永続化コントローラーを初期化する
    /// - Parameter inMemory: `true`の場合、メモリ内ストアを使用する（プレビュー用）
    /// - Throws: `PersistenceError` 永続化ストアの読み込みに失敗した場合
    init(inMemory: Bool = false) throws {
        container = NSPersistentContainer(name: "Daroku")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        var loadError: Error?
        let group = DispatchGroup()
        group.enter()

        container.loadPersistentStores { _, error in
            loadError = error
            group.leave()
        }

        group.wait()

        if let error = loadError {
            throw PersistenceError.failedToLoadStore(error)
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    /// マネージドオブジェクトコンテキストに保留中の変更がある場合、保存する
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                Self.logger.error("Failed to save context: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// メモリ内ストアで永続化コントローラーを作成する。失敗した場合は再試行する
    /// - Parameter context: エラーメッセージに使用するコンテキスト文字列
    /// - Returns: 初期化された永続化コントローラー
    private static func makeInMemoryController(context: String) -> PersistenceController {
        do {
            return try PersistenceController(inMemory: true)
        } catch {
            logger.error("Failed to create PersistenceController (\(context)): \(error.localizedDescription, privacy: .public)")
            // 再試行
            do {
                return try PersistenceController(inMemory: true)
            } catch {
                logger.error("Failed to create PersistenceController (\(context)) on retry: \(error.localizedDescription, privacy: .public)")
                fatalError("Failed to create PersistenceController (\(context)) after retry: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Preview Helper

    /// A preview instance of `PersistenceController` with sample data for SwiftUI previews.
    static var preview: PersistenceController = {
        let controller = makeInMemoryController(context: "preview")
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
            logger.error("Preview save error: \(error.localizedDescription, privacy: .public)")
        }

        return controller
    }()
}
