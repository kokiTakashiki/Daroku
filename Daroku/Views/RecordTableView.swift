//
//  RecordTableView.swift
//  Daroku
//

import SwiftUI

struct RecordTableView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var software: TypingSoftware

    @State private var selection = Set<Record.ID>()
    @State private var showingAddSheet = false
    @State private var sortByDate = true
    @State private var sortAscending = false

    private var records: [Record] {
        let recordSet = software.records as? Set<Record> ?? []
        return recordSet.sorted { r1, r2 in
            let date1 = r1.date ?? .distantPast
            let date2 = r2.date ?? .distantPast
            return sortAscending ? date1 < date2 : date1 > date2
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Table(records, selection: $selection) {
                TableColumn("日付") { record in
                    Text(record.date?.formatted(date: .abbreviated, time: .shortened) ?? "-")
                }
                .width(min: 120, ideal: 150)

                TableColumn("スコア") { record in
                    Text("\(Int(record.score)) \(software.unit ?? String(localized: "点"))")
                        .monospacedDigit()
                }
                .width(min: 80, ideal: 100)

                TableColumn("正確キー数") { record in
                    Text("\(record.correctKeys) 回")
                        .monospacedDigit()
                }
                .width(min: 80, ideal: 100)

                TableColumn("ミスタイプ") { record in
                    Text("\(record.mistypes) 回")
                        .monospacedDigit()
                        .foregroundStyle(record.mistypes > 0 ? .red : .primary)
                }
                .width(min: 80, ideal: 100)

                TableColumn("平均速度") { record in
                    Text(String(format: "%.1f 回/秒", record.avgKeysPerSec))
                        .monospacedDigit()
                }
                .width(min: 80, ideal: 100)

                TableColumn("メモ") { record in
                    Text(record.note ?? "")
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }
            .contextMenu(forSelectionType: Record.ID.self) { items in
                if !items.isEmpty {
                    Button(role: .destructive) {
                        deleteRecords(ids: items)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            } primaryAction: { _ in
                // ダブルクリック時のアクション（将来的に編集機能など）
            }

            Divider()

            // フッター
            HStack {
                Text("\(records.count) 件の記録")
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    deleteSelectedRecords()
                } label: {
                    Label("削除", systemImage: "trash")
                }
                .disabled(selection.isEmpty)

                Button {
                    showingAddSheet = true
                } label: {
                    Label("記録を追加", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.bar)
        }
        .sheet(isPresented: $showingAddSheet) {
            RecordFormView(software: software)
        }
    }

    private func deleteSelectedRecords() {
        deleteRecords(ids: selection)
        selection.removeAll()
    }

    private func deleteRecords(ids: Set<Record.ID>) {
        withAnimation {
            for record in records where ids.contains(record.id) {
                viewContext.delete(record)
            }
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete records: \(error)")
            }
        }
    }
}

#Preview {
    let controller = PersistenceController.preview
    let software = try! controller.viewContext.fetch(TypingSoftware.fetchRequest()).first!

    return RecordTableView(software: software)
        .environment(\.managedObjectContext, controller.viewContext)
        .frame(width: 700, height: 400)
}
