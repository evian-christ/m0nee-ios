import Foundation

enum StatsCardType: String, CaseIterable, Identifiable, Codable {
	case monthlyTotal = "monthlyTotal"
	case dailyTrend = "dailyTrend"
	case budgetProgress = "budgetProgress"

	var id: String { rawValue }

	var isPro: Bool {
		self == .budgetProgress
	}

	var displayName: String {
		switch self {
		case .monthlyTotal:
			return NSLocalizedString("Total Spending", comment: "Stats card type")
		case .dailyTrend:
			return NSLocalizedString("Spending Trend", comment: "Stats card type")
		case .budgetProgress:
			return NSLocalizedString("Budget", comment: "Stats card type")
		}
	}

	var sfSymbol: String {
		switch self {
		case .monthlyTotal:
			return "sum"
		case .dailyTrend:
			return "chart.line.uptrend.xyaxis"
		case .budgetProgress:
			return "target"
		}
	}

	static let defaultCards: [StatsCardType] = [.monthlyTotal, .budgetProgress, .dailyTrend]
}
