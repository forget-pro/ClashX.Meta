//
//  TrafficGraphView.swift
//  ClashX Dashboard
//
//

import SwiftUI
import AppKit
import DGCharts

fileprivate let labelsCount = 4

struct TrafficGraphView: View {
	@Binding var values: [CGFloat]
	let graphColor: NSColor
	
    var body: some View {
		let scale = chartScale(for: values)

		TrafficLineChartRepresentable(
			values: values,
			graphColor: graphColor,
			scale: scale
		)
    }

	private func chartScale(for values: [CGFloat]) -> TrafficScale {
		let peakValue = values.max() ?? CGFloat(labelsCount) * 1000
		let unit = chartUnit(for: Double(peakValue))
		let maxValueInUnit = Double(peakValue) / unit.divisor
		let minimumScaleValue = unit == .kilobytesPerSecond ? Double(labelsCount) : 0
		let baselineMaxValue = Swift.max(maxValueInUnit, minimumScaleValue)
		let step = niceStep(for: baselineMaxValue / Double(labelsCount))
		let upperValue = step * Double(labelsCount)

		return TrafficScale(
			upperBound: CGFloat(upperValue * unit.divisor),
			unit: unit
		)
	}

	private func chartUnit(for value: Double) -> TrafficUnit {
		switch value {
		case ..<1_000_000:
			return .kilobytesPerSecond
		case ..<1_000_000_000:
			return .megabytesPerSecond
		default:
			return .gigabytesPerSecond
		}
	}

	private func niceStep(for rawStep: Double) -> Double {
		guard rawStep > 0 else { return 1 }

		let exponent = floor(log10(rawStep))
		let base = pow(10, exponent)
		let fraction = rawStep / base

		let niceFraction: Double
		switch fraction {
		case ...1:
			niceFraction = 1
		case ...2:
			niceFraction = 2
		case ...5:
			niceFraction = 5
		default:
			niceFraction = 10
		}

		return niceFraction * base
	}

}

private struct TrafficScale {
	let upperBound: CGFloat
	let unit: TrafficUnit
}

private enum TrafficUnit: String {
	case kilobytesPerSecond = "KB/s"
	case megabytesPerSecond = "MB/s"
	case gigabytesPerSecond = "GB/s"

	var divisor: Double {
		switch self {
		case .kilobytesPerSecond:
			return 1_000
		case .megabytesPerSecond:
			return 1_000_000
		case .gigabytesPerSecond:
			return 1_000_000_000
		}
	}
}

private struct TrafficLineChartRepresentable: NSViewRepresentable {
	var values: [CGFloat]
	var graphColor: NSColor
	var scale: TrafficScale

	func makeNSView(context: Context) -> TrafficLineChartView {
		let chartView = TrafficLineChartView()
		configure(chartView)
		return chartView
	}

	func updateNSView(_ chartView: TrafficLineChartView, context: Context) {
		update(chartView)
	}

	private func configure(_ chartView: TrafficLineChartView) {
		chartView.chartDescription.enabled = false
		chartView.legend.enabled = false
		chartView.dragEnabled = false
		chartView.setScaleEnabled(false)
		chartView.noDataText = ""
		chartView.minOffset = 8
		chartView.wantsLayer = true
		chartView.layer?.backgroundColor = NSColor.clear.cgColor

		chartView.xAxis.enabled = false
		chartView.leftAxis.enabled = true
		chartView.leftAxis.drawLabelsEnabled = true
		chartView.leftAxis.drawAxisLineEnabled = false
		chartView.leftAxis.drawGridLinesEnabled = true
		chartView.leftAxis.gridColor = NSColor.systemGray.withAlphaComponent(0.3)
		chartView.leftAxis.gridLineWidth = 0.5
		chartView.leftAxis.setLabelCount(labelsCount + 1, force: true)
		chartView.leftAxis.gridLineDashLengths = [2, 2]
		chartView.leftAxis.gridLineDashPhase = 0
		chartView.leftAxis.labelFont = .monospacedDigitSystemFont(ofSize: 11, weight: .light)
		chartView.leftAxis.labelTextColor = .secondaryLabelColor
		chartView.leftAxis.xOffset = 4
		chartView.rightAxis.enabled = false
	}

	private func update(_ chartView: TrafficLineChartView) {
		let chartEntries = values.enumerated().map {
			ChartDataEntry(x: Double($0.offset), y: Double($0.element))
		}

		let dataSet = LineChartDataSet(entries: chartEntries, label: "")
		dataSet.colors = [graphColor]
		dataSet.lineWidth = 1.5
		dataSet.mode = .horizontalBezier
		dataSet.drawValuesEnabled = false
		dataSet.drawCirclesEnabled = false
		dataSet.highlightEnabled = false

		let data = LineChartData(dataSet: dataSet)
		data.setDrawValues(false)
		chartView.data = data

		let axisUpperBound = Double(max(scale.upperBound, 1))
		chartView.leftAxis.axisMaximum = axisUpperBound
		chartView.leftAxis.axisMinimum = 0
		chartView.leftAxis.valueFormatter = TrafficAxisValueFormatter(unit: scale.unit)
		chartView.leftAxis.granularityEnabled = true
		chartView.leftAxis.granularity = axisUpperBound / Double(labelsCount)

		chartView.xAxis.axisMinimum = 0
		chartView.xAxis.axisMaximum = Double(max(values.count - 1, 1))
		chartView.notifyDataSetChanged()
	}
}

private final class TrafficAxisValueFormatter: AxisValueFormatter {
	private let unit: TrafficUnit
	private let formatter: NumberFormatter

	init(unit: TrafficUnit) {
		self.unit = unit
		self.formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.minimumFractionDigits = 0
		formatter.maximumFractionDigits = 1
		formatter.usesGroupingSeparator = false
	}

	func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		guard value > 0 else { return "" }

		let scaledValue = value / unit.divisor
		let maximumFractionDigits = scaledValue < 1 ? 2 : 1
		formatter.maximumFractionDigits = maximumFractionDigits
		let text = formatter.string(from: NSNumber(value: scaledValue)) ?? String(format: "%.1f", scaledValue)
		return text + unit.rawValue
	}
}

private final class TrafficLineChartView: LineChartView {
	override var intrinsicContentSize: NSSize {
		NSSize(width: NSView.noIntrinsicMetric, height: 120)
	}
}

struct TrafficGraphView_Previews: PreviewProvider {
	static var previews: some View {
		VStack(spacing: 16) {
			TrafficGraphView(
				values: .constant([12_000, 28_000, 35_000, 22_000, 48_000, 64_000, 40_000, 72_000]),
				graphColor: .systemBlue
			)

			TrafficGraphView(
				values: .constant([2_000, 4_500, 3_500, 8_000, 6_500, 12_000, 9_000, 15_000]),
				graphColor: .systemGreen
			)
		}
		.padding()
		.frame(width: 360)
	}
}
