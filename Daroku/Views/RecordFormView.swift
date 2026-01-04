//
//  RecordFormView.swift
//  Daroku
//

import OSLog
import SwiftUI

/// 記録を追加・編集するフォームビュー
struct RecordFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var software: TypingSoftware

    private static let logger = Logger(subsystem: "com.daroku", category: "RecordFormView")

    @State private var date = Date()
    @State private var score: Double = 0
    @State private var correctKeys: Int32 = 0
    @State private var mistypes: Int32 = 0
    @State private var avgKeysPerSec: Double = 0.0
    @State private var note = ""

    // カスタムフィールド
    @State private var customFields: [(name: String, value: String)] = []
    @State private var newFieldName = ""
    @State private var newFieldValue = ""

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // 左側: 入力フォーム
                formContent
                    .frame(width: 400)

                Divider()

                // 右側: OCR読み取り
                ImageOCRView()
                    .frame(width: 320)
            }
            .frame(height: 550)
            .navigationTitle("記録を追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveRecord()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - フォームコンテンツ

    private var formContent: some View {
        Form {
            Section("基本情報") {
                DatePicker("日時", selection: $date)

                HStack {
                    Text("スコア")
                    Spacer()
                    TextField("0", value: $score, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                    Text(software.unit ?? String(localized: "点"))
                        .foregroundStyle(.secondary)
                }
            }

            Section("タイピング統計") {
                HStack {
                    Text("正しく打ったキー数")
                    Spacer()
                    TextField("0", value: $correctKeys, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                    Text("回")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("ミスタイプ数")
                    Spacer()
                    TextField("0", value: $mistypes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                    Text("回")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("平均キータイプ数")
                    Spacer()
                    TextField("0.0", value: $avgKeysPerSec, format: .number.precision(.fractionLength(1)))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                    Text("回/秒")
                        .foregroundStyle(.secondary)
                }
            }

            Section("カスタムフィールド") {
                ForEach(customFields.indices, id: \.self) { index in
                    HStack {
                        Text(customFields[index].name)
                        Spacer()
                        TextField("値", text: $customFields[index].value)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                            .multilineTextAlignment(.trailing)
                        Button {
                            customFields.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    TextField("フィールド名", text: $newFieldName)
                        .textFieldStyle(.roundedBorder)
                    TextField("値", text: $newFieldValue)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Button {
                        addCustomField()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    .disabled(newFieldName.isEmpty)
                }
            }

            Section("メモ") {
                TextEditor(text: $note)
                    .frame(minHeight: 60)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    /// カスタムフィールドを追加する
    private func addCustomField() {
        guard !newFieldName.isEmpty else { return }
        customFields.append((name: newFieldName, value: newFieldValue))
        newFieldName = ""
        newFieldValue = ""
    }

    /// 記録を保存する
    private func saveRecord() {
        let record = Record(context: viewContext)
        record.id = UUID()
        record.date = date
        record.score = score
        record.correctKeys = correctKeys
        record.mistypes = mistypes
        record.avgKeysPerSec = avgKeysPerSec
        record.note = note.isEmpty ? nil : note
        record.typingSoftware = software

        // カスタムフィールドを保存
        for field in customFields {
            let customField = CustomField(context: viewContext)
            customField.id = UUID()
            customField.name = field.name
            customField.value = field.value
            customField.type = "string"
            customField.record = record
        }

        do {
            try viewContext.save()
        } catch {
            Self.logger.error("Failed to save record: \(error.localizedDescription, privacy: .public)")
        }
    }
}

#Preview {
    let controller = PersistenceController.preview
    let software = try! controller.viewContext.fetch(TypingSoftware.fetchRequest()).first!

    return RecordFormView(software: software)
        .environment(\.managedObjectContext, controller.viewContext)
}
