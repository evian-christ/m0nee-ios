import SwiftUI

struct LowestRatedSpendingCardView: View {
		let expenses: [Expense]
		@EnvironmentObject var settings: AppSettings

		private var currencySymbol: String { CurrencyManager.symbol(for: settings.currencyCode) }

		private var lowestRatedExpenses: [Expense] {
				expenses
						.filter { ($0.rating ?? 0) > 0 && ($0.rating ?? 0) <= 3 }
						.sorted {
								if ($0.rating ?? 0) != ($1.rating ?? 0) {
										return ($0.rating ?? 0) < ($1.rating ?? 0)
								} else {
										return $0.amount > $1.amount
								}
						}
						.prefix(3)
						.map { $0 }
		}

		var body: some View {
				VStack(alignment: .leading, spacing: 16) {
						HStack {
								Label("Lowest Rated Spending", systemImage: "hand.thumbsdown.fill")
										.font(.headline)
								Spacer()
						}

						if lowestRatedExpenses.isEmpty {
								Spacer()
								Text("No expenses with 3 stars or lower found.")
										.font(.subheadline)
										.foregroundColor(.secondary)
										.frame(maxWidth: .infinity, alignment: .center)
								Spacer()
						} else {
								VStack(spacing: 0) {
										ForEach(Array(lowestRatedExpenses.enumerated()), id: \.element.id) { index, expense in
												VStack(spacing: 0) {
														HStack(spacing: 8) {
																Text("\(index + 1)")
																		.font(.footnote)
																		.frame(width: 20, height: 20)
																		.background(Circle().fill(Color.gray.opacity(0.2)))
																		.foregroundColor(.primary)

																VStack(alignment: .leading, spacing: 2) {
																		Text(expense.name)
																				.font(.subheadline)
																				.fontWeight(.medium)
																				.lineLimit(1)

																		Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
																				.font(.caption2)
																				.foregroundColor(.secondary)
																}

																Spacer()

																HStack(spacing: 1) {
																		ForEach(1...5, id: \.self) { star in
																				Image(systemName: star <= (expense.rating ?? 0) ? "star.fill" : "star")
																						.font(.caption2)
																						.foregroundColor(Color("StarYellow"))
																		}
																}
														}
														.padding(.vertical, 12)
														.padding(.horizontal, 8)

														if index < lowestRatedExpenses.count - 1 {
																Divider()
														}
												}
										}
								}
								.padding(.horizontal, 8)
								.padding(.top, 8)
						}
				}
		}
}

struct LowestRatedSpendingCardView_Previews: PreviewProvider {
		static var previews: some View {
				let sampleBudget = UUID()
				return LowestRatedSpendingCardView(expenses: [
						Expense(id: UUID(), date: Date(), name: "Bad Food", amount: 15.0, category: "Food", details: nil, rating: 1, memo: nil, budgetID: sampleBudget),
						Expense(id: UUID(), date: Date(), name: "Bad Service", amount: 25.0, category: "Service", details: nil, rating: 2, memo: nil, budgetID: sampleBudget),
						Expense(id: UUID(), date: Date(), name: "Okay Purchase", amount: 50.0, category: "Shopping", details: nil, rating: 3, memo: nil, budgetID: sampleBudget),
						Expense(id: UUID(), date: Date(), name: "Good Experience", amount: 10.0, category: "Entertainment", details: nil, rating: 4, memo: nil, budgetID: sampleBudget),
						Expense(id: UUID(), date: Date(), name: "Great Buy", amount: 5.0, category: "Shopping", details: nil, rating: 5, memo: nil, budgetID: sampleBudget)
				])
				.previewLayout(.sizeThatFits)
				.padding()
		}
	}


private struct RankedExpenseView: View {
		let expense: Expense
		let rank: Int
		let fontSize: Font
		var isHighlighted: Bool = false

		@EnvironmentObject var settings: AppSettings

		private var currencySymbol: String {
				CurrencyManager.symbol(for: settings.currencyCode)
		}

		var body: some View {
			VStack(spacing: isHighlighted ? 12 : 8) {
					Text("#\(rank)")
							.font(.caption)
							.foregroundColor(.gray)

					HStack(spacing: 8) {
							VStack(spacing: 4) {
									Text(expense.name)
											.font(isHighlighted ? .headline : .subheadline)
											.fontWeight(.medium)
											.lineLimit(1)
											.multilineTextAlignment(.center)

									Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
											.font(fontSize)
											.fontWeight(.semibold)
							}
					}

					HStack(spacing: 2) {
							ForEach(1...5, id: \.self) { star in
									Image(systemName: star <= (expense.rating ?? 0) ? "star.fill" : "star")
											.font(.caption2)
											.foregroundColor(Color("StarYellow"))
							}
					}
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical, isHighlighted ? 14 : 10)
			.padding(.horizontal, 8)
			.background(Color(.systemBackground))
			.cornerRadius(16)
			.shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
	}
}
