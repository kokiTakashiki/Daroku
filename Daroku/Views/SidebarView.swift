//
//  SidebarView.swift
//  Daroku
//

import OSLog
import SwiftUI

/// サイドバービュー。タイピングソフトの一覧を表示する
struct SidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedSoftware: TypingSoftware?

    private static let logger = Logger(subsystem: "com.daroku", category: "SidebarView")

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TypingSoftware.createdAt, ascending: true)],
        animation: .default
    )
    private var softwareList: FetchedResults<TypingSoftware>

    @State private var showingAddSheet = false
    @State private var newSoftwareName = ""
    @State private var newSoftwareUnit = ""
    @State private var newSoftwareURLString = ""

    var body: some View {
        List(selection: $selectedSoftware) {
            Section("タイピングソフト") {
                ForEach(softwareList) { software in
                    NavigationLink(value: software) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(software.name ?? String(localized: "名称未設定"))
                            Text("単位: \(software.unit ?? String(localized: "点"))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteSoftware(software)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteSoftware)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        .toolbar {
            ToolbarItem {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            addSoftwareSheet
        }
    }

    private var addSoftwareSheet: some View {
        NavigationStack {
            Form {
                TextField("ソフト名", text: $newSoftwareName)
                TextField("単位（例：円、点、WPM）", text: $newSoftwareUnit)
                TextField("URL（任意）", text: $newSoftwareURLString)
            }
            .padding()
            .frame(width: 300, height: 200)
            .navigationTitle("新規タイピングソフト")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        resetForm()
                        showingAddSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addSoftware()
                        showingAddSheet = false
                    }
                    .disabled(newSoftwareName.isEmpty)
                }
            }
        }
    }

    /// 新しいタイピングソフトを追加する
    private func addSoftware() {
        withAnimation {
            let software = TypingSoftware(context: viewContext)
            software.id = UUID()
            software.name = newSoftwareName
            software.unit = newSoftwareUnit.isEmpty ? String(localized: "点") : newSoftwareUnit
            software.createdAt = Date()

            do {
                try viewContext.save()
                selectedSoftware = software
            } catch {
                Self.logger.error("Failed to save software: \(error.localizedDescription, privacy: .public)")
            }

            resetForm()
        }
    }

    /// フォームをリセットする
    private func resetForm() {
        newSoftwareName = ""
        newSoftwareUnit = ""
        newSoftwareURLString = ""
    }

    /// タイピングソフトを削除する
    /// - Parameter software: 削除するタイピングソフト
    private func deleteSoftware(_ software: TypingSoftware) {
        withAnimation {
            if selectedSoftware == software {
                selectedSoftware = nil
            }
            viewContext.delete(software)
            do {
                try viewContext.save()
            } catch {
                Self.logger.error("Failed to delete software: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// 指定されたインデックスのタイピングソフトを削除する
    /// - Parameter offsets: 削除するタイピングソフトのインデックスのセット
    private func deleteSoftware(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let software = softwareList[index]
                if selectedSoftware == software {
                    selectedSoftware = nil
                }
                viewContext.delete(software)
            }
            do {
                try viewContext.save()
            } catch {
                Self.logger.error("Failed to delete software: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

#Preview {
    SidebarView(selectedSoftware: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
