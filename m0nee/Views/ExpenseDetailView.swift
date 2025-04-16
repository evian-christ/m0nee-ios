import SwiftUI

struct ExpenseDetailView: View {
	@AppStorage("currencyCode") private var currencyCode: String = "GBP"
	@AppStorage("showRating") private var showRating: Bool = true

	private var currencySymbol: String {
			CurrencyManager.symbol(for: currencyCode)
	}
	
	@Environment(\.dismiss) private var dismiss
	let expenseID: UUID
	@ObservedObject var store: ExpenseStore
	@State private var isEditing = false
	
	private var expense: Expense? {
		store.expenses.first(where: { $0.id == expenseID })
	}
	
	var body: some View {
		if let expense = expense {
			ScrollView {
				Text(expense.date.formatted(date: .abbreviated, time: .shortened))
					.font(.footnote)
					.foregroundColor(.secondary)
					.padding(.bottom, -12)

				VStack(spacing: 20) {

					// Expense Summary

						HStack(alignment: .center, spacing: 12) {
							if let categoryItem = store.categories.first(where: { $0.name == expense.category }) {
								ZStack {
									Circle()
										.fill(categoryItem.color.color)
										.frame(width: 44, height: 44)
									Image(systemName: categoryItem.symbol)
										.foregroundColor(.white)
										.font(.system(size: 18, weight: .medium))
								}
							} else {
								ZStack {
									Circle()
										.fill(Color.gray)
										.frame(width: 44, height: 44)
									Image(systemName: "tag")
										.foregroundColor(.white)
										.font(.system(size: 18, weight: .medium))
								}
							}

							HStack(spacing: 4) {
								Text(expense.name)
								if expense.isRecurring {
									Image(systemName: "arrow.triangle.2.circlepath")
										.font(.subheadline)
										.foregroundColor(.blue)
								}
							}
							.font(.title2.bold())

							Spacer()

							Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
								.font(.title3.bold())
						}


					.padding()
					.background(Color(.systemGray6))
					.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
					.padding(.horizontal)

					// Details Section
					if let details = expense.details, !details.isEmpty {
						VStack(alignment: .leading, spacing: 8) {
							Text("Details")
								.font(.headline)
							Text(details)
								.font(.body)
								.foregroundColor(.primary)
						}
						.padding()
						.frame(maxWidth: .infinity, alignment: .leading)
						.background(
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.fill(Color(.systemBackground))
								.overlay(
									RoundedRectangle(cornerRadius: 12, style: .continuous)
										.stroke(Color.secondary.opacity(0.2), lineWidth: 1)
								)
						)
						.padding(.horizontal)
					}

					// Note Section
					if let memo = expense.memo, !memo.isEmpty {
						VStack(alignment: .leading, spacing: 8) {
							Text("Note")
								.font(.headline)
							Text(memo)
								.font(.body)
								.foregroundColor(.primary)
						}
						.padding()
						.frame(maxWidth: .infinity, alignment: .leading)
						.background(
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.fill(Color(.systemBackground))
								.overlay(
									RoundedRectangle(cornerRadius: 12, style: .continuous)
										.stroke(Color.secondary.opacity(0.2), lineWidth: 1)
								)
						)
						.padding(.horizontal)
					}

					// Rating
					if showRating, let rating = expense.rating {
						VStack(alignment: .leading, spacing: 8) {
							Text("Rating")
								.font(.headline)
							HStack(spacing: 4) {
								ForEach(1...5, id: \.self) { index in
									Image(systemName: index <= rating ? "star.fill" : "star")
										.foregroundColor(.yellow)
								}
							}
						}
						.padding()
						.frame(maxWidth: .infinity, alignment: .leading)
						.background(
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.fill(Color(.systemBackground))
								.overlay(
									RoundedRectangle(cornerRadius: 12, style: .continuous)
										.stroke(Color.secondary.opacity(0.2), lineWidth: 1)
								)
						)
						.padding(.horizontal)
					}
				}
				.padding(.top)
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Edit") {
						isEditing = true
					}
				}
			}
			.sheet(isPresented: $isEditing) {
				NavigationStack {
					AddExpenseView(
						expenseID: expense.id,
						date: expense.date,
						name: expense.name,
						amount: "\(expense.amount)",
						category: expense.category,
						details: expense.details ?? "",
						rating: expense.rating ?? 3,
						memo: expense.memo ?? "",
						onSave: { updated in
							if updated.amount == -1 {
								store.delete(updated)
								isEditing = false
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
									dismiss()
								}
							} else {
								store.update(updated)
								isEditing = false
							}
						}
					)
				}
			}
		} else {
			Text("Expense not found")
				.foregroundColor(.secondary)
		}
	}
}
