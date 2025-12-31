//
//  SidebarView.swift
//  Daroku
//

import SwiftUI

struct SidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedSoftware: TypingSoftware?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TypingSoftware.createdAt, ascending: true)],
        animation: .default
    )
    private var softwares: FetchedResults<TypingSoftware>

    @State private var showingAddSheet = false
    @State private var newSoftwareName = ""
    @State private var newSoftwareUnit = "点"
    @State private var newSoftwareURL = ""

    var body: some View {
        List(selection: $selectedSoftware) {
            Section("タイピングソフト") {
                ForEach(softwares) { software in
                    NavigationLink(value: software) {
                        HStack {
                            Image(systemName: "keyboard")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(software.name ?? "名称未設定")
                                Text("単位: \(software.unit ?? "点")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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
                .onDelete(perform: deleteSoftwares)
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
                TextField("URL（任意）", text: $newSoftwareURL)
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

    private func addSoftware() {
        withAnimation {
            let software = TypingSoftware(context: viewContext)
            software.id = UUID()
            software.name = newSoftwareName
            software.unit = newSoftwareUnit.isEmpty ? "点" : newSoftwareUnit
            software.createdAt = Date()

            do {
                try viewContext.save()
                selectedSoftware = software
            } catch {
                print("Failed to save software: \(error)")
            }

            resetForm()
        }
    }

    private func resetForm() {
        newSoftwareName = ""
        newSoftwareUnit = "点"
        newSoftwareURL = ""
    }

    private func deleteSoftware(_ software: TypingSoftware) {
        withAnimation {
            if selectedSoftware == software {
                selectedSoftware = nil
            }
            viewContext.delete(software)
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete software: \(error)")
            }
        }
    }

    private func deleteSoftwares(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let software = softwares[index]
                if selectedSoftware == software {
                    selectedSoftware = nil
                }
                viewContext.delete(software)
            }
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete softwares: \(error)")
            }
        }
    }
}

#Preview {
    SidebarView(selectedSoftware: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
