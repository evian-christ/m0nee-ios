import SwiftUI

enum InsightCardType: String, Identifiable, Codable {
	case totalSpending
	case spendingTrend
	case categoryRating
	case budgetProgress
	case categoryBudgetProgress
	
	static var allCases: [InsightCardType] {
		return [.totalSpending, .spendingTrend, .categoryRating, .budgetProgress, .categoryBudgetProgress]
	}
	
	var id: String { self.rawValue }
	
	var title: String {
		switch self {
		case .totalSpending:
			let period = UserDefaults.standard.string(forKey: "budgetPeriod") ?? "Monthly"
			return period == "Weekly" ? "This Week's Total Spending" : "This Month's Total Spending"
		case .spendingTrend:
			return "Spending Trend"
		case .categoryRating:
			return "Category Satisfaction"
		case .budgetProgress:
			let period = UserDefaults.standard.string(forKey: "budgetPeriod") ?? "Monthly"
			return period == "Weekly" ? "Week's Progress" : "Month's Progress"
		case .categoryBudgetProgress:
			return "Category Budget Progress"
		}
	}
	
	var icon: String {
		switch self {
		case .totalSpending:
			return "creditcard"
		case .spendingTrend:
			return "chart.line.uptrend.xyaxis"
		case .categoryRating:
			return "star.lefthalf.fill"
		case .budgetProgress:
			return "gauge.with.needle"
		case .categoryBudgetProgress:
			return "chart.pie"
		}
	}
}

struct InsightCardView: View {
	var type: InsightCardType
	let expenses: [Expense]
	let startDate: Date
	let endDate: Date
	@AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
	@AppStorage("currencyCode") private var currencyCode: String = "GBP"
	@AppStorage("enableBudgetTracking") private var enableBudgetTracking: Bool = true

	private var currencySymbol: String {
		CurrencyManager.symbol(for: currencyCode)
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			if type != .budgetProgress {
				HStack {
					Label(type.title, systemImage: type.icon)
						.font(.headline)
					Spacer()
				}
			}
			
			switch type {
			case .totalSpending:
				TotalSpendingCardView(
					expenses: expenses,
					monthlyBudget: monthlyBudget,
					currencySymbol: currencySymbol,
					budgetTrackingEnabled: enableBudgetTracking
				)
			case .spendingTrend:
				SpendingTrendCardView(
					expenses: expenses,
					startDate: startDate,
					endDate: endDate,
					monthlyBudget: monthlyBudget
				)
			case .categoryRating:
				CategoryRatingCardView(expenses: expenses)
			case .budgetProgress:
				BudgetProgressCardView(
					expenses: expenses,
					startDate: startDate,
					endDate: endDate,
					monthlyBudget: monthlyBudget
				)
			case .categoryBudgetProgress:
				let categoryBudgetDict: [String: Double] = {
					guard let data = UserDefaults.standard.data(forKey: "categoryBudgets"),
							let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
						return [:]
					}
					return decoded.reduce(into: [String: Double]()) { dict, pair in
						if let value = Double(pair.value) {
							dict[pair.key] = value
						}
					}
				}()

				CategoryBudgetProgressCardView(
					expenses: expenses,
					startDate: startDate,
					endDate: endDate,
					categoryBudgets: categoryBudgetDict
				)
			}
		}
		.padding()
		.frame(maxWidth: .infinity)
		.frame(height: 240)
		.background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
		.padding(.vertical, 0)
	}
}
