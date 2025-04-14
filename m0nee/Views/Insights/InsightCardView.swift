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
	@AppStorage("categoryBudgets") private var categoryBudgets: String = ""
	@AppStorage("currencyCode") private var currencyCode: String = "GBP"

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
				Group {
					let amountSpent = expenses.reduce(0) { $0 + $1.amount }
					
					VStack(alignment: .leading) {
						Text(String(format: "\(currencySymbol)%.2f / \(currencySymbol)%.2f", amountSpent, monthlyBudget))
							.font(.title2)
							.bold()
						ProgressView(value: amountSpent, total: monthlyBudget)
							.accentColor(amountSpent > monthlyBudget ? .red : .blue)
					}
				}
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
				let budgetPairs = categoryBudgets
					.split(separator: ",")
					.compactMap { pair -> (String, Double)? in
						let parts = pair.split(separator: ":")
						guard parts.count == 2, let value = Double(parts[1]) else { return nil }
						return (String(parts[0]), value)
					}
				let categoriesString = UserDefaults.standard.string(forKey: "categories") ?? ""
				let categoryList = categoriesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
				let categoryBudgetDict = Dictionary(uniqueKeysWithValues:
																							categoryList.map { category in
					let budget = budgetPairs.first(where: { $0.0 == category })?.1 ?? 0
					return (category, budget)
				}
				)
				
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
