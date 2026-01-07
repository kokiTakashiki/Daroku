//
//  JSONImportExtensions.swift
//  Daroku
//

import CoreData
import Foundation
import JSONHandler
import OSLog

/// ExportableTypingSoftwareからCore Dataエンティティを作成する機能
@MainActor
public final class JSONImportExtensions {
    private static let logger = Logger(subsystem: "com.daroku", category: "JSONImportExtensions")

    /// ExportableTypingSoftwareからCore Dataエンティティを作成し、コンテキストに追加する
    /// - Parameters:
    ///   - exportable: インポートするExportableTypingSoftware
    ///   - context: Core Dataのマネージドオブジェクトコンテキスト
    /// - Returns: 作成されたTypingSoftware。作成に失敗した場合はnil
    public static func importToCoreData(
        _ exportable: ExportableTypingSoftware,
        into context: NSManagedObjectContext
    ) -> TypingSoftware? {
        // TypingSoftwareを作成（常に新しいUUIDを使用）
        let software = TypingSoftware(context: context)
        let newSoftwareId = UUID()
        software.id = newSoftwareId
        software.name = exportable.software.name
        software.unit = exportable.software.unit
        software.url = exportable.software.url
        software.createdAt = exportable.software.createdAt

        // Recordを作成
        for exportableRecord in exportable.records {
            let record = Record(context: context)
            let newRecordId = UUID()
            record.id = newRecordId
            record.date = exportableRecord.date
            record.score = exportableRecord.score
            record.correctKeys = exportableRecord.correctKeys
            record.mistypes = exportableRecord.mistypes
            record.avgKeysPerSec = exportableRecord.avgKeysPerSec
            record.note = exportableRecord.note
            record.typingSoftware = software

            // CustomFieldを作成
            for exportableCustomField in exportableRecord.customFields {
                let customField = CustomField(context: context)
                let newCustomFieldId = UUID()
                customField.id = newCustomFieldId
                customField.name = exportableCustomField.name
                customField.type = exportableCustomField.type
                customField.value = exportableCustomField.value
                customField.record = record
            }
        }

        // コンテキストを保存
        do {
            try context.save()
            Self.logger.info("Successfully imported software: \(exportable.software.name, privacy: .public) with \(exportable.records.count) records")
            return software
        } catch {
            Self.logger.error("Failed to save imported data: \(error.localizedDescription, privacy: .public)")
            context.rollback()
            return nil
        }
    }
}
