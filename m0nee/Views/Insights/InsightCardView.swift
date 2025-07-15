import SwiftUI

enum InsightCardType: String, Identifiable, Codable {
	case totalSpending
	case spendingTrend
	case categoryRating
	case budgetProgress
	case categoryBudgetProgress
	case lowestRatedSpending
	
	static var allCases: [InsightCardType] {
		return [.totalSpending, .spendingTrend, .categoryRating, .budgetProgress, .categoryBudgetProgress, .lowestRatedSpending]
	}
	
	var id: String { self.rawValue }
	
	var title: String {
		switch self {
		case .totalSpending:
			let period = UserDefaults.standard.string(forKey: "budgetPeriod") ?? "Monthly"
			return period == "Weekly" ? "This Week's Total Spending" : "This Month's Total Spending"
		case .spendingTrend:
			return NSLocalizedString("Spending Trend", comment: "Title for the Spending Trend insight card")
		case .categoryRating:
			return NSLocalizedString("Category Satisfaction", comment: "Title for the Category Satisfaction insight card")
		case .budgetProgress:
			let period = UserDefaults.standard.string(forKey: "budgetPeriod") ?? "Monthly"
			return period == "Weekly" ? "Week's Progress" : "Month's Progress"
		case .categoryBudgetProgress:
			return NSLocalizedString("Category Budget Progress", comment: "Title for the Category Budget Progress insight card")
		case .lowestRatedSpending:
			return NSLocalizedString("Lowest Rated Spending", comment: "Title for the Lowest Rated Spending insight card")
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
		case .lowestRatedSpending:
			return "hand.thumbsdown.fill"
		}
	}
	
	var isProOnly: Bool {
			switch self {
			case .categoryBudgetProgress, .categoryRating, .budgetProgress, .lowestRatedSpending:
					return true
			default:
					return false
			}
	}
}

struct InsightCardView: View {
	var type: InsightCardType
	let expenses: [Expense]
	let startDate: Date
	let endDate: Date
	let categories: [CategoryItem]
	let isProUser: Bool
	@AppStorage("monthlyBudget", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var monthlyBudget: Double = 0
	@AppStorage("currencyCode", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
	@AppStorage("enableBudgetTracking", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var enableBudgetTracking: Bool = true
	@AppStorage("budgetByCategory", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var budgetByCategory: Bool = false
	@AppStorage("showRating", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var showRating: Bool = true
	

	private var currencySymbol: String {
		CurrencyManager.symbol(for: currencyCode)
	}
	
	private var shouldBlur: Bool {
			if type.isProOnly && !isProUser {
				return true
			}
			switch type {
			case .categoryRating, .lowestRatedSpending:
				return !showRating
			case .budgetProgress:
				return !enableBudgetTracking
			case .categoryBudgetProgress:
				return !budgetByCategory || !enableBudgetTracking
			default:
				return false
			}
	}
	
	private var blurMessage: String {
			if type.isProOnly && !isProUser {
				return "Upgrade to Monir Pro to unlock this feature."
			}
			switch type {
			case .categoryRating, .lowestRatedSpending:
				return "Enable 'Show Rating' in General Settings to view this insight."
			case .budgetProgress:
				return "Enable 'Budget Tracking' in Budget Settings to view this insight."
			case .categoryBudgetProgress:
				return "Enable 'Budget Tracking' and 'Budget by Category' in Budget Settings to view this insight."
			default:
				return ""
			}
	}
	
	var body: some View {
		ZStack(alignment: .top) {
			RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray5))
			
			VStack(alignment: .leading, spacing: 12) {
				if type != .budgetProgress && type != .categoryBudgetProgress && type != .totalSpending && type != .lowestRatedSpending {
					HStack {
						Label(type.title, systemImage: type.icon)
							.font(.headline)
						Spacer()
					}
				}
				
				VStack {
					switch type {
					case .totalSpending:
						TotalSpendingCardView(
							expenses: expenses,
							monthlyBudget: monthlyBudget,
							currencyCode: currencyCode,
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
							guard let data = UserDefaults(suiteName: "group.com.chankim.Monir")?.data(forKey: "categoryBudgets"),
										let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
								return [:]
							}
							return decoded.reduce(into: [String: Double]()) { dict, pair in
								if let value = Double(pair.value) {
									dict[pair.key] = value
								}
							}
						}()
						
						VStack(alignment: .leading, spacing: 12) {
							HStack {
								Label(type.title, systemImage: type.icon)
									.font(.headline)
								Spacer()
							}
							
							CategoryBudgetProgressCardView(
								expenses: expenses,
								startDate: startDate,
								endDate: endDate,
								categoryBudgets: categoryBudgetDict
							)
						}
					case .lowestRatedSpending:
						LowestRatedSpendingCardView(expenses: expenses)
					}
				}
			}
			.frame(maxWidth: .infinity, alignment: .topLeading)
			.frame(height: 225, alignment: .topLeading)
			.clipped()
			.padding()
			.blur(radius: shouldBlur ? 6 : 0)
			
			if shouldBlur {
				ZStack {
					RoundedRectangle(cornerRadius: 16)
						.fill(Color(.systemGray6).opacity(0.3))
					Text(blurMessage)
						.font(.headline)
						.multilineTextAlignment(.center)
						.padding()
				}
				.frame(maxHeight: .infinity, alignment: .center)
			}
		}
		.padding(.top, 5)
		.frame(maxWidth: .infinity)
		.frame(height: 270)
	}
}
