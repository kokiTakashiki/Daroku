//
//  JSONExportService.swift
//  JSONHandler
//

import Foundation
import OSLog

/// JSONエクスポート用のカスタムフィールド構造体
public struct ExportableCustomField: Sendable, Codable {
    public let id: UUID
    public let name: String
    public let type: String
    public let value: String

    public init(from customField: CustomFieldExportable) {
        id = customField.exportID
        name = customField.exportName
        type = customField.exportType
        value = customField.exportValue
    }
}

/// JSONエクスポート用の記録構造体
public struct ExportableRecord: Sendable, Codable {
    public let id: UUID
    public let date: Date
    public let score: Double
    public let correctKeys: Int32
    public let mistypes: Int32
    public let avgKeysPerSec: Double
    public let note: String?
    public let customFields: [ExportableCustomField]

    public init(from record: RecordExportable) {
        id = record.exportID
        date = record.exportDate
        score = record.exportScore
        correctKeys = record.exportCorrectKeys
        mistypes = record.exportMistypes
        avgKeysPerSec = record.exportAvgKeysPerSec
        note = record.exportNote
        customFields = record.exportCustomFields
            .map { ExportableCustomField(from: $0) }
            .sorted { $0.name < $1.name }
    }
}

/// JSONエクスポート用のソフトウェア構造体
public struct ExportableTypingSoftware: Sendable, Codable {
    public let software: SoftwareInfo
    public let records: [ExportableRecord]

    public struct SoftwareInfo: Sendable, Codable {
        public let id: UUID
        public let name: String
        public let unit: String?
        public let url: String?
        public let createdAt: Date

        public init(id: UUID, name: String, unit: String?, url: String?, createdAt: Date) {
            self.id = id
            self.name = name
            self.unit = unit
            self.url = url
            self.createdAt = createdAt
        }
    }

    public init(from typingSoftware: TypingSoftwareExportable) {
        software = SoftwareInfo(
            id: typingSoftware.exportID,
            name: typingSoftware.exportName,
            unit: typingSoftware.exportUnit,
            url: typingSoftware.exportURL,
            createdAt: typingSoftware.exportCreatedAt
        )
        records = typingSoftware.exportRecords
            .map { ExportableRecord(from: $0) }
            .sorted { $0.date < $1.date }
    }
}

/// CustomFieldエクスポート用プロトコル
public protocol CustomFieldExportable {
    var exportID: UUID { get }
    var exportName: String { get }
    var exportType: String { get }
    var exportValue: String { get }
}

/// Recordエクスポート用プロトコル
public protocol RecordExportable {
    var exportID: UUID { get }
    var exportDate: Date { get }
    var exportScore: Double { get }
    var exportCorrectKeys: Int32 { get }
    var exportMistypes: Int32 { get }
    var exportAvgKeysPerSec: Double { get }
    var exportNote: String? { get }
    var exportCustomFields: [CustomFieldExportable] { get }
}

/// TypingSoftwareエクスポート用プロトコル
public protocol TypingSoftwareExportable {
    var exportID: UUID { get }
    var exportName: String { get }
    var exportUnit: String? { get }
    var exportURL: String? { get }
    var exportCreatedAt: Date { get }
    var exportRecords: [RecordExportable] { get }
}

/// CoreDataエンティティをJSON形式にエクスポートするサービス
@MainActor
public final class JSONExportService {
    private static let logger = Logger(subsystem: "com.daroku", category: "JSONExportService")

    /// TypingSoftwareとその関連RecordをJSONデータに変換する
    /// - Parameter software: エクスポート対象のTypingSoftware（TypingSoftwareExportableプロトコルに準拠）
    /// - Returns: JSON形式のデータ。エンコードに失敗した場合はnil
    public static func exportToJSON(software: TypingSoftwareExportable) -> Data? {
        let exportable = ExportableTypingSoftware(from: software)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let jsonData = try encoder.encode(exportable)
            Self.logger.info("Successfully exported \(exportable.records.count) records for software: \(software.exportName, privacy: .public)")
            return jsonData
        } catch {
            Self.logger.error("Failed to encode JSON: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}

