//
//  JSONExportExtensions.swift
//  Daroku
//

import CoreData
import JSONHandler

extension CustomField: CustomFieldExportable {
    public var exportID: UUID {
        id ?? UUID()
    }

    public var exportName: String {
        name ?? ""
    }

    public var exportType: String {
        type ?? "string"
    }

    public var exportValue: String {
        value ?? ""
    }
}

extension Record: RecordExportable {
    public var exportID: UUID {
        id ?? UUID()
    }

    public var exportDate: Date {
        date ?? Date()
    }

    public var exportScore: Double {
        score
    }

    public var exportCorrectKeys: Int32 {
        correctKeys
    }

    public var exportMistypes: Int32 {
        mistypes
    }

    public var exportAvgKeysPerSec: Double {
        avgKeysPerSec
    }

    public var exportNote: String? {
        note
    }

    public var exportCustomFields: [CustomFieldExportable] {
        (customFields as? Set<CustomField> ?? []).map { $0 as CustomFieldExportable }
    }
}

extension TypingSoftware: TypingSoftwareExportable {
    public var exportID: UUID {
        id ?? UUID()
    }

    public var exportName: String {
        name ?? ""
    }

    public var exportUnit: String? {
        unit
    }

    public var exportURL: String? {
        url
    }

    public var exportCreatedAt: Date {
        createdAt ?? Date()
    }

    public var exportRecords: [RecordExportable] {
        (records as? Set<Record> ?? []).map { $0 as RecordExportable }
    }
}
