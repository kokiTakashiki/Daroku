//
//  DarokuTests.swift
//  DarokuTests
//
//  Created by takedatakashiki on 2025/12/30.
//

@testable import Daroku
import Foundation
import JSONHandler
import Testing

struct DarokuTests {
    @Test func jSONExport() async throws {
        // メモリ内ストアでPersistenceControllerを作成
        let controller = try await PersistenceController(inMemory: true)
        let context = await controller.viewContext

        // テストデータを作成
        let software = TypingSoftware(context: context)
        software.id = UUID()
        software.name = "テストソフト"
        software.unit = "点"
        software.url = "https://example.com"
        software.createdAt = Date()

        let record1 = Record(context: context)
        record1.id = UUID()
        record1.date = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01 00:00:00 UTC
        record1.score = 1000.0
        record1.correctKeys = 100
        record1.mistypes = 10
        record1.avgKeysPerSec = 5.5
        record1.note = "テストメモ"
        record1.typingSoftware = software

        let record2 = Record(context: context)
        record2.id = UUID()
        record2.date = Date(timeIntervalSince1970: 1_704_153_600) // 2024-01-02 00:00:00 UTC
        record2.score = 2000.0
        record2.correctKeys = 200
        record2.mistypes = 20
        record2.avgKeysPerSec = 6.0
        record2.note = nil
        record2.typingSoftware = software

        let customField = CustomField(context: context)
        customField.id = UUID()
        customField.name = "カスタムフィールド"
        customField.type = "string"
        customField.value = "カスタム値"
        customField.record = record1

        try context.save()

        // JSONエクスポートを実行
        let jsonData = await MainActor.run {
            JSONExportService.exportToJSON(software: software)
        }

        // JSONデータが存在することを確認
        #expect(jsonData != nil, "JSONデータがnilです")

        guard let jsonData else {
            return
        }

        // JSONがパース可能であることを確認
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(ExportableTypingSoftware.self, from: jsonData)

        // ソフトウェア情報が正しいことを確認
        #expect(decoded.software.name == "テストソフト")
        #expect(decoded.software.unit == "点")
        #expect(decoded.software.url == "https://example.com")
        #expect(decoded.software.id == software.id)

        // 記録データが正しく含まれていることを確認
        #expect(decoded.records.count == 2, "記録の数が正しくありません")

        // 日付順にソートされていることを確認
        let sortedRecords = decoded.records.sorted { $0.date < $1.date }
        #expect(sortedRecords[0].date == record1.date)
        #expect(sortedRecords[1].date == record2.date)

        // 最初の記録のデータを確認
        let firstRecord = decoded.records.first { $0.id == record1.id }!
        #expect(firstRecord.score == 1000.0)
        #expect(firstRecord.correctKeys == 100)
        #expect(firstRecord.mistypes == 10)
        #expect(firstRecord.avgKeysPerSec == 5.5)
        #expect(firstRecord.note == "テストメモ")

        // カスタムフィールドが正しく含まれていることを確認
        #expect(firstRecord.customFields.count == 1)
        #expect(firstRecord.customFields[0].name == "カスタムフィールド")
        #expect(firstRecord.customFields[0].type == "string")
        #expect(firstRecord.customFields[0].value == "カスタム値")

        // 2番目の記録のデータを確認（カスタムフィールドなし、noteがnil）
        let secondRecord = decoded.records.first { $0.id == record2.id }!
        #expect(secondRecord.score == 2000.0)
        #expect(secondRecord.correctKeys == 200)
        #expect(secondRecord.mistypes == 20)
        #expect(secondRecord.avgKeysPerSec == 6.0)
        #expect(secondRecord.note == nil)
        #expect(secondRecord.customFields.isEmpty)

        // JSON文字列がISO8601形式の日付を含むことを確認（日付部分のみ）
        let jsonString = String(data: jsonData, encoding: .utf8)!
        #expect(jsonString.contains("2024-01-01"))
    }
}
