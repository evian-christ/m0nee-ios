import Charts
import SwiftUI

struct CategoryRatingCardView: View {
	var expenses: [Expense]
	
	var body: some View {
		let grouped = Dictionary(grouping: expenses) { $0.category }
		let averageRatings = grouped.compactMapValues { items -> Double? in
			let ratings = items.compactMap { $0.rating }
			return ratings.isEmpty ? nil : Double(ratings.reduce(0, +)) / Double(ratings.count)
		}
		
		let sorted = averageRatings.sorted(by: { $0.value > $1.value })
		
		return Chart {
			ForEach(sorted, id: \.key) { category, avg in
				BarMark(
					x: .value("Category", category),
					y: .value("Rating", avg)
				)
				.foregroundStyle(getColor(for: avg))
			}
		}
		.chartYScale(domain: [0, 5])
		.chartYAxis {
			AxisMarks(values: Array(0...5)) { value in
				AxisGridLine()
				AxisTick()
				AxisValueLabel()
			}
		}
		.chartLegend(.hidden)
		.frame(height: 180)
	}
	
	func getColor(for rating: Double) -> Color {
		switch Int(rating.rounded()) {
		case 5: return Color.green
		case 4: return Color.mint
		case 3: return Color.yellow
		case 2: return Color.orange
		case 1: return Color.red
		default: return Color.gray.opacity(0.4)
		}
	}
}
