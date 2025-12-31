//
//  RecordChartView.swift
//  Daroku
//

import Charts
import SwiftUI

enum ChartMetric: String, CaseIterable, Identifiable {
    case score = "スコア"
    case correctKeys = "正確キー数"
    case mistypes = "ミスタイプ"
    case avgKeysPerSec = "平均速度"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .score: .blue
        case .correctKeys: .green
        case .mistypes: .red
        case .avgKeysPerSec: .orange
        }
    }

    var unit: String {
        switch self {
        case .score: ""
        case .correctKeys: "回"
        case .mistypes: "回"
        case .avgKeysPerSec: "回/秒"
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let metric: String
}

struct RecordChartView: View {
    @ObservedObject var software: TypingSoftware
    @State private var selectedMetrics: Set<ChartMetric> = [.score]

    private var records: [Record] {
        let recordSet = software.records as? Set<Record> ?? []
        return recordSet.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    private func chartData(for metric: ChartMetric) -> [ChartDataPoint] {
        records.compactMap { record in
            guard let date = record.date else { return nil }
            let value = getValue(for: metric, from: record)
            return ChartDataPoint(date: date, value: value, metric: metric.rawValue)
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
                    metricSelector
                    chartSection
                    statisticsSummary
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var metricSelector: some View {
        HStack {
            Text("表示する指標:")
                .foregroundStyle(.secondary)

            ForEach(ChartMetric.allCases) { metric in
                Toggle(isOn: Binding(
                    get: { selectedMetrics.contains(metric) },
                    set: { isOn in
                        if isOn {
                            selectedMetrics.insert(metric)
                        } else if selectedMetrics.count > 1 {
                            selectedMetrics.remove(metric)
                        }
                    }
                )) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(metric.color)
                            .frame(width: 8, height: 8)
                        Text(metric.rawValue)
                    }
                }
                .toggleStyle(.button)
                .buttonStyle(.bordered)
                .tint(selectedMetrics.contains(metric) ? metric.color : .secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }

    @ViewBuilder
    private var chartSection: some View {
        let allData = selectedMetrics.flatMap { chartData(for: $0) }

        Chart(allData) { dataPoint in
            LineMark(
                x: .value("日時", dataPoint.date),
                y: .value("値", dataPoint.value)
            )
            .foregroundStyle(by: .value("指標", dataPoint.metric))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("日時", dataPoint.date),
                y: .value("値", dataPoint.value)
            )
            .foregroundStyle(by: .value("指標", dataPoint.metric))
        }
        .chartForegroundStyleScale([
            ChartMetric.score.rawValue: ChartMetric.score.color,
            ChartMetric.correctKeys.rawValue: ChartMetric.correctKeys.color,
            ChartMetric.mistypes.rawValue: ChartMetric.mistypes.color,
            ChartMetric.avgKeysPerSec.rawValue: ChartMetric.avgKeysPerSec.color,
        ])
        .chartLegend(position: .bottom)
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
        .frame(minHeight: 300)
    }

    private var statisticsSummary: some View {
        HStack(spacing: 24) {
            ForEach(Array(selectedMetrics).sorted(by: { $0.rawValue < $1.rawValue })) { metric in
                let values = records.map { getValue(for: metric, from: $0) }
                let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
                let maxVal = values.max() ?? 0
                let minVal = values.min() ?? 0

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(metric.color)
                            .frame(width: 8, height: 8)
                        Text(metric.rawValue)
                            .font(.headline)
                    }

                    HStack(spacing: 16) {
                        StatItem(label: "平均", value: formatValue(avg, metric: metric))
                        StatItem(label: "最高", value: formatValue(maxVal, metric: metric))
                        StatItem(label: "最低", value: formatValue(minVal, metric: metric))
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
            }

            Spacer()
        }
        .padding()
    }

    private func getValue(for metric: ChartMetric, from record: Record) -> Double {
        switch metric {
        case .score: record.score
        case .correctKeys: Double(record.correctKeys)
        case .mistypes: Double(record.mistypes)
        case .avgKeysPerSec: record.avgKeysPerSec
        }
    }

    private func formatValue(_ value: Double, metric: ChartMetric) -> String {
        let unit = metric == .score ? (software.unit ?? "点") : metric.unit
        if metric == .avgKeysPerSec {
            return String(format: "%.1f %@", value, unit)
        }
        return "\(Int(value)) \(unit)"
    }
}

struct StatItem: View {
    let label: String
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
