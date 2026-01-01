//
//  ImageOCRView.swift
//  Daroku
//

import SwiftUI
import UniformTypeIdentifiers

/// 画像からテキストを読み取るビュー（埋め込み用）
struct ImageOCRView: View {
    @State private var droppedImage: NSImage?
    @State private var recognizedTexts: [String] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var copiedIndex: Int?
    @State private var isTargeted = false

    private let ocrService = ImageOCRService()

    var body: some View {
        VStack(spacing: 12) {
            // ヘッダー
            HStack {
                Label("画像から読み取り", systemImage: "doc.text.viewfinder")
                    .font(.headline)
                Spacer()
            }

            // 画像ドロップエリア
            imageDropZone

            Divider()

            // 認識結果エリア
            recognitionResultsArea
        }
        .padding()
    }

    // MARK: - 画像ドロップエリア

    private var imageDropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .foregroundStyle(isTargeted ? .blue : .secondary)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isTargeted ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
                )

            if let image = droppedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else if isProcessing {
                ProgressView("認識中...")
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("ここに画像をドロップ")
                        .font(.subheadline)
                    Button("ファイルを選択") {
                        selectImageFile()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .frame(height: 140)
        .onDrop(of: [.image, .fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    // MARK: - 認識結果エリア

    private var recognitionResultsArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("認識結果")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("クリックでコピー")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !recognizedTexts.isEmpty {
                    Button {
                        copyAllTexts()
                    } label: {
                        Label("すべてコピー", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }

            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if recognizedTexts.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("画像をドロップすると\n認識結果が表示されます")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(recognizedTexts.enumerated()), id: \.offset) { index, text in
                            recognizedTextRow(text: text, index: index)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func recognizedTextRow(text: String, index: Int) -> some View {
        Button {
            copyText(text, at: index)
        } label: {
            HStack {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if copiedIndex == index {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - アクション

    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }

        if provider.canLoadObject(ofClass: NSImage.self) {
            _ = provider.loadObject(ofClass: NSImage.self) { image, _ in
                if let nsImage = image as? NSImage {
                    Task { @MainActor in
                        await processImage(nsImage)
                    }
                }
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                if let data = data as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil),
                   let image = NSImage(contentsOf: url)
                {
                    Task { @MainActor in
                        await processImage(image)
                    }
                }
            }
        }
    }

    private func selectImageFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .png, .jpeg, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                Task {
                    await processImage(image)
                }
            }
        }
    }

    private func processImage(_ image: NSImage) async {
        droppedImage = image
        isProcessing = true
        errorMessage = nil
        recognizedTexts = []

        do {
            recognizedTexts = try await ocrService.recognizeText(from: image)
            if recognizedTexts.isEmpty {
                errorMessage = String(localized: "テキストが見つかりませんでした")
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    private func copyText(_ text: String, at index: Int) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedIndex = index
        }

        // 1秒後にチェックマークを消す
        Task {
            try? await Task.sleep(for: .seconds(1))
            withAnimation {
                if copiedIndex == index {
                    copiedIndex = nil
                }
            }
        }
    }

    private func copyAllTexts() {
        let allText = recognizedTexts.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(allText, forType: .string)
    }
}

#Preview {
    ImageOCRView()
        .frame(width: 300, height: 500)
}
