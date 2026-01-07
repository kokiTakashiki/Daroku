//
//  JSONImportService.swift
//  JSONHandler
//

import Foundation
import OSLog

/// CoreDataエンティティをJSON形式からインポートするサービス
@MainActor
public final class JSONImportService {
    private static let logger = Logger(subsystem: "com.daroku", category: "JSONImportService")

    /// JSONデータを`ExportableTypingSoftware`にデコードする
    /// - Parameter data: デコードするJSONデータ
    /// - Returns: デコードされた`ExportableTypingSoftware`。デコードに失敗した場合はnil
    public static func importFromJSON(data: Data) -> ExportableTypingSoftware? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let exportable = try decoder.decode(ExportableTypingSoftware.self, from: data)
            Self.logger.info("Successfully decoded JSON with \(exportable.records.count) records for software: \(exportable.software.name, privacy: .public)")
            return exportable
        } catch {
            Self.logger.error("Failed to decode JSON: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

