//
//  RecordChartView.swift
//  Daroku
//

import Charts
import SwiftUI

/// グラフで表示する指標の列挙型
enum ChartMetric: String, CaseIterable, Identifiable {
    /// スコア
    case score
    /// 正確キー数
    case correctKeys
    /// ミスタイプ数
    case mistypes
    /// 平均キータイプ数（回/秒）
    case avgKeysPerSec

    /// 一意の識別子。rawValueと同じ値
    var id: String { rawValue }

    /// ローカライズされた指標名
    var localizedName: String {
        switch self {
        case .score: String(localized: "スコア")
        case .correctKeys: String(localized: "正確キー数")
        case .mistypes: String(localized: "ミスタイプ")
        case .avgKeysPerSec: String(localized: "平均速度")
        }
    }

    /// グラフで使用する指標の色
    var color: Color {
        switch self {
        case .score: .blue
        case .correctKeys: .green
        case .mistypes: .red
        case .avgKeysPerSec: .orange
        }
    }

    /// 指標の単位（例：「回」「回/秒」）
    var unit: String {
        switch self {
        case .score: ""
        case .correctKeys: String(localized: "回")
        case .mistypes: String(localized: "回")
        case .avgKeysPerSec: String(localized: "回/秒")
        }
    }
}

/// グラフのデータポイント
struct ChartDataPoint: Identifiable {
    /// 一意の識別子
    let id = UUID()
    /// データポイントの日時
    let date: Date
    /// データポイントの値
    let value: Double
    /// 指標名
    let metric: String
}

/// 記録をグラフで表示するビュー
struct RecordChartView: View {
    @ObservedObject var software: TypingSoftware

    /// 日付順にソートされた記録の配列
    /// - Complexity: O(n log n), where n is the number of records.
    private var records: [Record] {
        let recordSet = software.records as? Set<Record> ?? []
        return recordSet.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    /// 指定された指標のチャートデータを生成する
    /// - Parameter metric: チャートに表示する指標
    /// - Returns: 日付と値のペアを含むチャートデータポイントの配列
    private func chartData(for metric: ChartMetric) -> [ChartDataPoint] {
        records.compactMap { record in
            guard let date = record.date else { return nil }
            let value = value(for: metric, from: record)
            return ChartDataPoint(date: date, value: value, metric: metric.localizedName)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if records.isEmpty {
                ContentUnavailableView(
                    "記録がありません",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("記録を追加するとグラフが表示されます")
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    chartSection
                    statisticsSummary
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    @ViewBuilder
    private var chartSection: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(ChartMetric.allCases) { metric in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(metric.color)
                                .frame(width: 8, height: 8)
                            Text(metric.localizedName)
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)

                        Chart(chartData(for: metric)) { dataPoint in
                            LineMark(
                                x: .value("日時", dataPoint.date),
                                y: .value("値", dataPoint.value)
                            )
                            .foregroundStyle(metric.color)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("日時", dataPoint.date),
                                y: .value("値", dataPoint.value)
                            )
                            .foregroundStyle(metric.color)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .padding()
                        .frame(height: 280)
                    }
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }

    /// 統計情報のサマリービュー。各指標の平均、最高、最低値を表示する
    private var statisticsSummary: some View {
        HStack(spacing: 24) {
            ForEach(ChartMetric.allCases) { metric in
                let values = records.map { value(for: metric, from: $0) }
                let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
                let maxVal = values.max() ?? 0
                let minVal = values.min() ?? 0

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(metric.color)
                            .frame(width: 8, height: 8)
                        Text(metric.localizedName)
                            .font(.headline)
                    }

                    HStack(spacing: 16) {
                        StatItem(label: String(localized: "平均"), value: formatValue(avg, for: metric))
                        StatItem(label: String(localized: "最高"), value: formatValue(maxVal, for: metric))
                        StatItem(label: String(localized: "最低"), value: formatValue(minVal, for: metric))
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
            }

            Spacer()
        }
        .padding()
    }

    /// 記録から指定された指標の値を取得する
    /// - Parameters:
    ///   - metric: 取得する指標
    ///   - record: 値を取得する記録
    /// - Returns: 指標に対応する値
    private func value(for metric: ChartMetric, from record: Record) -> Double {
        switch metric {
        case .score: record.score
        case .correctKeys: Double(record.correctKeys)
        case .mistypes: Double(record.mistypes)
        case .avgKeysPerSec: record.avgKeysPerSec
        }
    }

    /// 値をフォーマットして文字列に変換する
    /// - Parameters:
    ///   - value: フォーマットする値
    ///   - metric: 値の指標
    /// - Returns: フォーマットされた文字列
    private func formatValue(_ value: Double, for metric: ChartMetric) -> String {
        let unit = metric == .score ? (software.unit ?? String(localized: "点")) : metric.unit
        if metric == .avgKeysPerSec {
            return "\(value.formatted(.number.precision(.fractionLength(1)))) \(unit)"
        }
        return "\(Int(value)) \(unit)"
    }
}

/// 統計情報の表示コンポーネント
struct StatItem: View {
    /// ラベルテキスト
    let label: String
    /// 値のテキスト
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .monospacedDigit()
        }
    }
}

#Preview {
    let controller = PersistenceController.preview
    let request = TypingSoftware.fetchRequest()
    let software = try! controller.viewContext.fetch(request).first!

    return RecordChartView(software: software)
        .environment(\.managedObjectContext, controller.viewContext)
        .frame(width: 800, height: 500)
}
