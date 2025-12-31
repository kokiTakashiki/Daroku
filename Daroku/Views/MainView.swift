//
//  MainView.swift
//  Daroku
//

import SwiftUI

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedSoftware: TypingSoftware?
    @State private var showingTable = true
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showingURLEditPopover = false
    @State private var editingURL = ""

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedSoftware: $selectedSoftware)
        } detail: {
            if let software = selectedSoftware {
                VStack(spacing: 0) {
                    // ヘッダー
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(software.name ?? "名称未設定")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("単位: \(software.unit ?? "点")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let url = software.url, !url.isEmpty {
                                HStack(spacing: 4) {
                                    if let urlValue = URL(string: url) {
                                        Link(url, destination: urlValue)
                                            .font(.caption2)
                                            .foregroundStyle(.blue)
                                    } else {
                                        Text(url)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Button {
                                        editingURL = url
                                        showingURLEditPopover = true
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                Button {
                                    editingURL = ""
                                    showingURLEditPopover = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("URLを追加")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Image(systemName: "pencil")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Spacer()

                        Picker("表示", selection: $showingTable) {
                            Label("表", systemImage: "tablecells")
                                .tag(true)
                            Label("グラフ", systemImage: "chart.line.uptrend.xyaxis")
                                .tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    .padding()
                    .background(.bar)

                    Divider()

                    // メインコンテンツ
                    if showingTable {
                        RecordTableView(software: software)
                    } else {
                        RecordChartView(software: software)
                    }
                }
            } else {
                ContentUnavailableView(
                    "タイピングソフトを選択",
                    systemImage: "keyboard",
                    description: Text("左のサイドバーからタイピングソフトを選択するか、新規作成してください")
                )
            }
        }
        .navigationTitle("⌨️打録")
        .frame(minWidth: 900, minHeight: 600)
        .popover(isPresented: $showingURLEditPopover, arrowEdge: .bottom) {
            if let software = selectedSoftware {
                urlEditPopover(software: software)
            }
        }
    }

    @ViewBuilder
    private func urlEditPopover(software: TypingSoftware) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("URLを編集")
                .font(.headline)

            TextField("URL", text: $editingURL)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("キャンセル") {
                    showingURLEditPopover = false
                }
                .keyboardShortcut(.cancelAction)

                Button("保存") {
                    saveURL(software: software)
                    showingURLEditPopover = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
    }

    private func saveURL(software: TypingSoftware) {
        withAnimation {
            software.url = editingURL.isEmpty ? nil : editingURL
            do {
                try viewContext.save()
            } catch {
                print("Failed to save URL: \(error)")
            }
        }
    }
}

#Preview {
    MainView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
