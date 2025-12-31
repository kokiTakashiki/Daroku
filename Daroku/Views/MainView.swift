//
//  MainView.swift
//  Daroku
//

import StoreKit
import SwiftUI

// MARK: - AppLinks

enum AppLinks {
    static let followURL = "https://twitter.com/bluewhitered123"
    // static let appStoreID = ""
}

// MARK: - TipProducts

enum TipProducts {
    static let smallTip = "com.daroku.tip.small"
    static let mediumTip = "com.daroku.tip.medium"
    static let largeTip = "com.daroku.tip.large"

    static let all = [smallTip, mediumTip, largeTip]
}

struct MainView: View {
    @State private var selectedSoftware: TypingSoftware?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView(selectedSoftware: $selectedSoftware)
            } detail: {
                if let software = selectedSoftware {
                    SoftwareDetailView(software: software)
                } else {
                    ContentUnavailableView(
                        "タイピングソフトを選択",
                        systemImage: "keyboard",
                        description: Text("左のサイドバーからタイピングソフトを選択するか、新規作成してください")
                    )
                    .navigationTitle("⌨️打録")
                }
            }
            .frame(minWidth: 900, minHeight: 600)

            Divider()

            FooterView()
        }
    }
}

// MARK: - SoftwareDetailView

/// Core Dataオブジェクトを@ObservedObjectで監視し、変更を自動的に反映する詳細ビュー
private struct SoftwareDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var software: TypingSoftware

    @State private var showingTable = true
    @State private var showingURLEditPopover = false
    @State private var editingURL = ""

    var body: some View {
        let title = if let name = software.name {
            name
        } else {
            "名称未設定"
        }
        VStack(spacing: 0) {
            header()

            Divider()

            // メインコンテンツ
            if showingTable {
                RecordTableView(software: software)
            } else {
                RecordChartView(software: software)
            }
        }
        .navigationTitle(title)
    }

    private func header() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("単位: \(software.unit ?? "点")")
                    .font(.caption2)
                if let url = software.url, !url.isEmpty {
                    HStack(spacing: 4) {
                        Text("サイトURL: ")
                            .font(.caption2)
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
                        .popover(isPresented: $showingURLEditPopover, arrowEdge: .bottom) {
                            urlEditPopover
                        }
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
                    .popover(isPresented: $showingURLEditPopover, arrowEdge: .bottom) {
                        urlEditPopover
                    }
                }
            }

            Spacer()

            Picker("", selection: $showingTable) {
                Image(systemName: "list.bullet")
                    .tag(true)
                Image(systemName: "chart.xyaxis.line")
                    .tag(false)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(.bar)
    }

    @ViewBuilder
    private var urlEditPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("URLを編集")
                .font(.headline)

            TextField("URL", text: $editingURL)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("キャンセル") {
                    editingURL = software.url ?? ""
                    showingURLEditPopover = false
                }
                .keyboardShortcut(.cancelAction)

                Button("保存") {
                    saveURL()
                    showingURLEditPopover = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            editingURL = software.url ?? ""
        }
    }

    private func saveURL() {
        software.url = editingURL.isEmpty ? nil : editingURL

        do {
            try viewContext.save()
        } catch {
            print("Failed to save URL: \(error)")
        }
    }
}

// MARK: - FooterView

struct FooterView: View {
    var body: some View {
        HStack(spacing: 12) {
            // Helpボタン（丸ボタン）
            Button {
                HelpView.openWindow()
            } label: {
                Image(systemName: "questionmark")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .background(
                Circle()
                    .fill(.quaternary)
            )

            Button {
                openTipWindow()
            } label: {
                Text("🍵 Tip me")
            }
            .buttonStyle(.plain)

            ShareLink(
                item: URL(string: "https://example.com/daroku")!,
                subject: Text("打録"),
                message: Text("打録 - タイピング練習の記録を管理するmacOSアプリ")
            ) {
                Text("Share")
            }
            .buttonStyle(.plain)

            Button {
                openURL(AppLinks.followURL)
            } label: {
                Text("Follow")
            }
            .buttonStyle(.plain)

            Button {
                openAppStoreReview()
            } label: {
                Text("Review")
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func openTipWindow() {
        let tipWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        tipWindow.title = "開発者を支援"
        tipWindow.center()
        tipWindow.contentView = NSHostingView(rootView: TipView())
        tipWindow.makeKeyAndOrderFront(nil)
        tipWindow.isReleasedWhenClosed = false
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    private func openAppStoreReview() {
        // let urlString = "https://apps.apple.com/app/id\(AppLinks.appStoreID)?action=write-review"
        // openURL(urlString)
    }
}

// MARK: - HelpView

struct HelpView: View {
    /// ヘルプウィンドウを開く（既に開いている場合は前面に表示）
    @MainActor
    static func openWindow() {
        // 既存のヘルプウィンドウがあれば前面に表示
        for window in NSApplication.shared.windows where window.title == "ヘルプ" {
            window.makeKeyAndOrderFront(nil)
            return
        }

        // 新しいヘルプウィンドウを作成
        let helpWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        helpWindow.title = "ヘルプ"
        helpWindow.center()
        helpWindow.contentView = NSHostingView(rootView: HelpView())
        helpWindow.makeKeyAndOrderFront(nil)
        helpWindow.isReleasedWhenClosed = false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("打録（ダロク）ヘルプ")
                    .font(.title)
                    .fontWeight(.bold)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("概要")
                        .font(.headline)
                    Text("打録は、タイピング練習の記録を管理するためのアプリケーションです。スコア、ミスタイプ数、平均速度などを記録し、グラフで進捗を確認できます。")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("使い方")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("1.")
                                .fontWeight(.medium)
                            Text("左のサイドバーの「+」ボタンから、新しいタイピングソフトを追加します。")
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Text("2.")
                                .fontWeight(.medium)
                            Text("タイピングソフトを選択し、「記録を追加」ボタンから練習結果を記録します。")
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Text("3.")
                                .fontWeight(.medium)
                            Text("「表」と「グラフ」を切り替えて、記録を確認できます。")
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Text("4.")
                                .fontWeight(.medium)
                            Text("画像OCR機能を使えば、スクリーンショットから自動的にスコアを読み取ることができます。")
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("機能")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "keyboard")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("複数のタイピングソフトに対応")
                                    .fontWeight(.medium)
                                Text("寿司打、e-typing など、お好きなタイピングソフトの記録を管理できます。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("グラフで進捗を確認")
                                    .fontWeight(.medium)
                                Text("スコアの推移を折れ線グラフで視覚的に確認できます。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "text.viewfinder")
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("画像OCR機能")
                                    .fontWeight(.medium)
                                Text("スクリーンショットから自動的にスコアを読み取ります。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

// MARK: - TipStore

@MainActor
class TipStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseState: PurchaseState = .ready

    enum PurchaseState: Equatable {
        case ready
        case purchasing
        case purchased
        case failed(String)
    }

    init() {
        Task {
            await loadProducts()
        }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: TipProducts.all)
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case let .success(verification):
                switch verification {
                case let .verified(transaction):
                    await transaction.finish()
                    purchaseState = .purchased
                case .unverified:
                    purchaseState = .failed("購入の検証に失敗しました")
                }
            case .userCancelled:
                purchaseState = .ready
            case .pending:
                purchaseState = .ready
            @unknown default:
                purchaseState = .ready
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func resetState() {
        purchaseState = .ready
    }
}

// MARK: - TipView

struct TipView: View {
    @StateObject private var store = TipStore()

    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            VStack(spacing: 8) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)

                Text("開発者を支援する")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("打録を気に入っていただけましたら、\n開発を支援していただけると嬉しいです！")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            Divider()
                .padding(.horizontal)

            // チップオプション
            if store.products.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("商品を読み込み中...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 150)
            } else {
                VStack(spacing: 12) {
                    ForEach(store.products, id: \.id) { product in
                        TipButton(product: product, store: store)
                    }
                }
                .padding(.horizontal)
            }

            // ステータス表示
            switch store.purchaseState {
            case .ready:
                EmptyView()
            case .purchasing:
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("購入処理中...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .purchased:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("ありがとうございます！")
                        .font(.callout)
                        .foregroundStyle(.green)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        store.resetState()
                    }
                }
            case let .failed(message):
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        store.resetState()
                    }
                }
            }

            Spacer()

            // フッター
            Text("チップは消耗型のアプリ内課金です。\n追加機能のアンロックはありません。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
        }
        .frame(width: 400, height: 450)
    }
}

// MARK: - TipButton

struct TipButton: View {
    let product: Product
    @ObservedObject var store: TipStore

    private var tipEmoji: String {
        switch product.id {
        case TipProducts.smallTip: "🍵"
        case TipProducts.mediumTip: "☕️"
        case TipProducts.largeTip: "🍰"
        default: "💰"
        }
    }

    private var tipLabel: String {
        switch product.id {
        case TipProducts.smallTip: "小さなチップ"
        case TipProducts.mediumTip: "ちょうどいいチップ"
        case TipProducts.largeTip: "大きなチップ"
        default: product.displayName
        }
    }

    var body: some View {
        Button {
            Task {
                await store.purchase(product)
            }
        } label: {
            HStack {
                Text(tipEmoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tipLabel)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary)
            )
        }
        .buttonStyle(.plain)
        .disabled(store.purchaseState == .purchasing)
    }
}

#Preview {
    MainView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
