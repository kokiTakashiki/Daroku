//
//  JSONHandlerTests.swift
//  JSONHandlerTests
//

@testable import JSONHandler
import Foundation
import Testing

struct JSONHandlerTests {
    @Test func testExportableCustomField() async throws {
        struct MockCustomField: CustomFieldExportable {
            var exportID: UUID = UUID()
            var exportName: String = "テストフィールド"
            var exportType: String = "string"
            var exportValue: String = "テスト値"
        }

        let mockField = MockCustomField()
        let exportable = ExportableCustomField(from: mockField)

        #expect(exportable.id == mockField.exportID)
        #expect(exportable.name == "テストフィールド")
        #expect(exportable.type == "string")
        #expect(exportable.value == "テスト値")
    }

    @Test func testExportableRecord() async throws {
        struct MockCustomField: CustomFieldExportable {
            var exportID: UUID = UUID()
            var exportName: String
            var exportType: String = "string"
            var exportValue: String = "テスト値"
        }

        struct MockRecord: RecordExportable {
            var exportID: UUID = UUID()
            var exportDate: Date = Date(timeIntervalSince1970: 1704067200)
            var exportScore: Double = 1000.0
            var exportCorrectKeys: Int32 = 100
            var exportMistypes: Int32 = 10
            var exportAvgKeysPerSec: Double = 5.5
            var exportNote: String? = "テストメモ"
            var exportCustomFields: [CustomFieldExportable] = []
        }

        var mockRecord = MockRecord()
        let customField = MockCustomField(exportName: "カスタムフィールド")
        mockRecord.exportCustomFields = [customField]

        let exportable = ExportableRecord(from: mockRecord)

        #expect(exportable.id == mockRecord.exportID)
        #expect(exportable.date == Date(timeIntervalSince1970: 1704067200))
        #expect(exportable.score == 1000.0)
        #expect(exportable.correctKeys == 100)
        #expect(exportable.mistypes == 10)
        #expect(exportable.avgKeysPerSec == 5.5)
        #expect(exportable.note == "テストメモ")
        #expect(exportable.customFields.count == 1)
        #expect(exportable.customFields[0].name == "カスタムフィールド")
    }

    @Test func testJSONEncoding() async throws {
        struct MockCustomField: CustomFieldExportable {
            var exportID: UUID = UUID()
            var exportName: String = "テストフィールド"
            var exportType: String = "string"
            var exportValue: String = "テスト値"
        }

        struct MockRecord: RecordExportable {
            var exportID: UUID = UUID()
            var exportDate: Date = Date(timeIntervalSince1970: 1704067200)
            var exportScore: Double = 1000.0
            var exportCorrectKeys: Int32 = 100
            var exportMistypes: Int32 = 10
            var exportAvgKeysPerSec: Double = 5.5
            var exportNote: String? = "テストメモ"
            var exportCustomFields: [CustomFieldExportable] = []
        }

        struct MockTypingSoftware: TypingSoftwareExportable {
            var exportID: UUID = UUID()
            var exportName: String = "テストソフト"
            var exportUnit: String? = "点"
            var exportURL: String? = "https://example.com"
            var exportCreatedAt: Date = Date()
            var exportRecords: [RecordExportable] = []
        }

        var mockSoftware = MockTypingSoftware()
        var mockRecord = MockRecord()
        let customField = MockCustomField()
        mockRecord.exportCustomFields = [customField]
        mockSoftware.exportRecords = [mockRecord]

        let exportable = ExportableTypingSoftware(from: mockSoftware)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(exportable)
        #expect(jsonData.count > 0)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(ExportableTypingSoftware.self, from: jsonData)

        #expect(decoded.software.name == "テストソフト")
        #expect(decoded.software.unit == "点")
        #expect(decoded.software.url == "https://example.com")
        #expect(decoded.records.count == 1)
        #expect(decoded.records[0].score == 1000.0)
        #expect(decoded.records[0].customFields.count == 1)

        let jsonString = String(data: jsonData, encoding: .utf8)!
        #expect(jsonString.contains("テストソフト"))
        #expect(jsonString.contains("2024-01-01"))
    }

    // MARK: - JSONImportService Tests

    @Test func testImportFromValidJSON() async throws {
        struct MockCustomField: CustomFieldExportable {
            var exportID: UUID = UUID()
            var exportName: String = "テストフィールド"
            var exportType: String = "string"
            var exportValue: String = "テスト値"
        }

        struct MockRecord: RecordExportable {
            var exportID: UUID = UUID()
            var exportDate: Date = Date(timeIntervalSince1970: 1704067200)
            var exportScore: Double = 1000.0
            var exportCorrectKeys: Int32 = 100
            var exportMistypes: Int32 = 10
            var exportAvgKeysPerSec: Double = 5.5
            var exportNote: String? = "テストメモ"
            var exportCustomFields: [CustomFieldExportable] = []
        }

        struct MockTypingSoftware: TypingSoftwareExportable {
            var exportID: UUID = UUID()
            var exportName: String = "テストソフト"
            var exportUnit: String? = "点"
            var exportURL: String? = "https://example.com"
            var exportCreatedAt: Date = Date(timeIntervalSince1970: 1704067200)
            var exportRecords: [RecordExportable] = []
        }

        var mockSoftware = MockTypingSoftware()
        let mockRecord = MockRecord()
        mockSoftware.exportRecords = [mockRecord]

        guard let jsonData = await JSONExportService.exportToJSON(software: mockSoftware) else {
            Issue.record("Failed to export JSON")
            return
        }

        let imported = await JSONImportService.importFromJSON(data: jsonData)

        #expect(imported != nil)
        #expect(imported?.software.name == "テストソフト")
        #expect(imported?.software.unit == "点")
        #expect(imported?.software.url == "https://example.com")
        #expect(imported?.records.count == 1)
        #expect(imported?.records[0].score == 1000.0)
        #expect(imported?.records[0].correctKeys == 100)
        #expect(imported?.records[0].mistypes == 10)
        #expect(imported?.records[0].avgKeysPerSec == 5.5)
        #expect(imported?.records[0].note == "テストメモ")
    }

    @Test func testImportFromJSONWithMultipleRecords() async throws {
        struct MockRecord: RecordExportable {
            var exportID: UUID
            var exportDate: Date
            var exportScore: Double
            var exportCorrectKeys: Int32 = 100
            var exportMistypes: Int32 = 10
            var exportAvgKeysPerSec: Double = 5.5
            var exportNote: String? = nil
            var exportCustomFields: [CustomFieldExportable] = []
        }

        struct MockTypingSoftware: TypingSoftwareExportable {
            var exportID: UUID = UUID()
            var exportName: String = "テストソフト"
            var exportUnit: String? = nil
            var exportURL: String? = nil
            var exportCreatedAt: Date = Date(timeIntervalSince1970: 1704067200)
            var exportRecords: [RecordExportable] = []
        }

        var mockSoftware = MockTypingSoftware()
        let record1 = MockRecord(
            exportID: UUID(),
            exportDate: Date(timeIntervalSince1970: 1704067200),
            exportScore: 1000.0
        )
        let record2 = MockRecord(
            exportID: UUID(),
            exportDate: Date(timeIntervalSince1970: 1704153600),
            exportScore: 1200.0
        )
        let record3 = MockRecord(
            exportID: UUID(),
            exportDate: Date(timeIntervalSince1970: 1704240000),
            exportScore: 1500.0
        )
        mockSoftware.exportRecords = [record1, record2, record3]

        guard let jsonData = await JSONExportService.exportToJSON(software: mockSoftware) else {
            Issue.record("Failed to export JSON")
            return
        }

        let imported = await JSONImportService.importFromJSON(data: jsonData)

        #expect(imported != nil)
        #expect(imported?.records.count == 3)
        #expect(imported?.records[0].score == 1000.0)
        #expect(imported?.records[1].score == 1200.0)
        #expect(imported?.records[2].score == 1500.0)
    }

    @Test func testImportFromJSONWithCustomFields() async throws {
        struct MockCustomField: CustomFieldExportable {
            var exportID: UUID
            var exportName: String
            var exportType: String = "string"
            var exportValue: String
        }

        struct MockRecord: RecordExportable {
            var exportID: UUID = UUID()
            var exportDate: Date = Date(timeIntervalSince1970: 1704067200)
            var exportScore: Double = 1000.0
            var exportCorrectKeys: Int32 = 100
            var exportMistypes: Int32 = 10
            var exportAvgKeysPerSec: Double = 5.5
            var exportNote: String? = nil
            var exportCustomFields: [CustomFieldExportable] = []
        }

        struct MockTypingSoftware: TypingSoftwareExportable {
            var exportID: UUID = UUID()
            var exportName: String = "テストソフト"
            var exportUnit: String? = nil
            var exportURL: String? = nil
            var exportCreatedAt: Date = Date(timeIntervalSince1970: 1704067200)
            var exportRecords: [RecordExportable] = []
        }

        var mockSoftware = MockTypingSoftware()
        var mockRecord = MockRecord()
        let customField1 = MockCustomField(
            exportID: UUID(),
            exportName: "カスタムフィールド1",
            exportValue: "値1"
        )
        let customField2 = MockCustomField(
            exportID: UUID(),
            exportName: "カスタムフィールド2",
            exportValue: "値2"
        )
        mockRecord.exportCustomFields = [customField1, customField2]
        mockSoftware.exportRecords = [mockRecord]

        guard let jsonData = await JSONExportService.exportToJSON(software: mockSoftware) else {
            Issue.record("Failed to export JSON")
            return
        }

        let imported = await JSONImportService.importFromJSON(data: jsonData)

        #expect(imported != nil)
        guard let imported = imported else { return }
        
        #expect(imported.records.count == 1)
        #expect(imported.records[0].customFields.count == 2)
        #expect(imported.records[0].customFields.contains { $0.name == "カスタムフィールド1" })
        #expect(imported.records[0].customFields.contains { $0.name == "カスタムフィールド2" })
        #expect(imported.records[0].customFields.contains { $0.value == "値1" })
        #expect(imported.records[0].customFields.contains { $0.value == "値2" })
    }

    @Test func testImportFromJSONWithOptionalFields() async throws {
        struct MockRecord: RecordExportable {
            var exportID: UUID = UUID()
            var exportDate: Date = Date(timeIntervalSince1970: 1704067200)
            var exportScore: Double = 1000.0
            var exportCorrectKeys: Int32 = 100
            var exportMistypes: Int32 = 10
            var exportAvgKeysPerSec: Double = 5.5
            var exportNote: String? = "オプショナルメモ"
            var exportCustomFields: [CustomFieldExportable] = []
        }

        struct MockTypingSoftware: TypingSoftwareExportable {
            var exportID: UUID = UUID()
            var exportName: String = "テストソフト"
            var exportUnit: String? = "オプショナル単位"
            var exportURL: String? = "https://optional.example.com"
            var exportCreatedAt: Date = Date(timeIntervalSince1970: 1704067200)
            var exportRecords: [RecordExportable] = []
        }

        var mockSoftware = MockTypingSoftware()
        let mockRecord = MockRecord()
        mockSoftware.exportRecords = [mockRecord]

        guard let jsonData = await JSONExportService.exportToJSON(software: mockSoftware) else {
            Issue.record("Failed to export JSON")
            return
        }

        let imported = await JSONImportService.importFromJSON(data: jsonData)

        #expect(imported != nil)
        #expect(imported?.software.unit == "オプショナル単位")
        #expect(imported?.software.url == "https://optional.example.com")
        #expect(imported?.records[0].note == "オプショナルメモ")
    }

    @Test func testImportFromInvalidJSON() async throws {
        let invalidJSON = "{ invalid json }"
        let invalidData = invalidJSON.data(using: .utf8)!

        let imported = await JSONImportService.importFromJSON(data: invalidData)

        #expect(imported == nil)
    }

    @Test func testImportFromEmptyData() async throws {
        let emptyData = Data()

        let imported = await JSONImportService.importFromJSON(data: emptyData)

        #expect(imported == nil)
    }

    @Test func testImportFromJSONWithMissingRequiredFields() async throws {
        // 必須フィールド（software.name）が欠けているJSON
        let invalidJSON = """
        {
            "software": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "createdAt": "2024-01-01T00:00:00Z"
            },
            "records": []
        }
        """
        let invalidData = invalidJSON.data(using: .utf8)!

        let imported = await JSONImportService.importFromJSON(data: invalidData)

        #expect(imported == nil)
    }

    @Test func testImportFromJSONWithInvalidDateFormat() async throws {
        // 不正な日付フォーマットのJSON
        let invalidJSON = """
        {
            "software": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "name": "テストソフト",
                "createdAt": "2024/01/01"
            },
            "records": []
        }
        """
        let invalidData = invalidJSON.data(using: .utf8)!

        let imported = await JSONImportService.importFromJSON(data: invalidData)

        #expect(imported == nil)
    }
}

