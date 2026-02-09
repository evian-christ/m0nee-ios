import SwiftUI

struct ExpenseDetailView: View {
	@EnvironmentObject var settings: AppSettings

	private var currencyCode: String { settings.currencyCode }
	private var showRating: Bool { settings.showRating }
	private var decimalDisplayMode: DecimalDisplayMode { settings.decimalDisplayMode }

	@Environment(\.dismiss) private var dismiss
	let expenseID: UUID
	@ObservedObject var store: ExpenseStore
	@State private var isEditing = false

	private var expense: Expense? {
		store.expenses.first(where: { $0.id == expenseID })
	}

	private var categoryItem: CategoryItem? {
		guard let expense else { return nil }
		return store.categories.first(where: { $0.name == expense.category })
	}

	var body: some View {
		if let expense = expense {
			List {
				// MARK: - Hero Section
				Section {
					VStack(spacing: 12) {
						// Category icon
						ZStack {
							Circle()
								.fill(categoryItem?.color.color ?? .gray)
								.frame(width: 56, height: 56)
							Image(systemName: categoryItem?.symbol ?? "tag")
								.foregroundColor(.white)
								.font(.system(size: 24, weight: .medium))
						}

						// Name + badges
						HStack(spacing: 4) {
							Text(expense.name)
								.font(.system(size: 20, weight: .semibold))
							if expense.isRecurring {
								Image(systemName: "arrow.triangle.2.circlepath")
									.font(.system(size: 13))
									.foregroundColor(.blue)
							}
							if expense.excludeFromBudget {
								Image(systemName: "circle.slash")
									.font(.system(size: 13))
									.foregroundColor(.orange)
							}
						}

						// Amount
						Text(NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: expense.amount)) ?? "")
							.font(.system(size: 40, weight: .bold))
							.foregroundColor(.primary)
							.minimumScaleFactor(0.5)
							.lineLimit(1)
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 8)
				}
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)

				// MARK: - Info Section
				Section {
					HStack {
						Text("Date")
							.foregroundColor(.secondary)
						Spacer()
						Text(expense.date.formatted(date: .abbreviated, time: .shortened))
					}

					HStack {
						Text("Category")
							.foregroundColor(.secondary)
						Spacer()
						HStack(spacing: 6) {
							ZStack {
								Circle()
									.fill((categoryItem?.color.color ?? .gray).opacity(0.15))
									.frame(width: 24, height: 24)
								Image(systemName: categoryItem?.symbol ?? "tag")
									.font(.system(size: 12))
									.foregroundColor(categoryItem?.color.color ?? .gray)
							}
							Text(expense.category)
						}
					}

					if expense.isRecurring || expense.excludeFromBudget {
						HStack {
							Text("Status")
								.foregroundColor(.secondary)
							Spacer()
							HStack(spacing: 8) {
								if expense.isRecurring {
									Label("Recurring", systemImage: "arrow.triangle.2.circlepath")
										.font(.subheadline)
										.foregroundColor(.blue)
								}
								if expense.excludeFromBudget {
									Label("Excluded", systemImage: "circle.slash")
										.font(.subheadline)
										.foregroundColor(.orange)
								}
							}
						}
					}
				}

				// MARK: - Details Section
				if let details = expense.details, !details.isEmpty {
					Section("Details") {
						Text(details)
					}
				}

				// MARK: - Note Section
				if let memo = expense.memo, !memo.isEmpty {
					Section("Note") {
						Text(memo)
					}
				}

				// MARK: - Rating Section
				if showRating, let rating = expense.rating {
					Section("Rating") {
						HStack(spacing: 4) {
							ForEach(1...5, id: \.self) { index in
								Image(systemName: index <= rating ? "star.fill" : "star")
									.font(.system(size: 18))
									.foregroundColor(index <= rating ? .yellow : Color(.systemGray3))
							}
						}
					}
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					let isOrphan = expense.isRecurring && store.recurringExpenses.first { $0.id == expense.parentRecurringID } == nil
					if !expense.isRecurring || isOrphan {
						Button("Edit") {
							isEditing = true
						}
					}
				}
			}
			.sheet(isPresented: $isEditing) {
				NavigationStack {
					EditExpenseView(
						expenseID: expense.id,
						date: expense.date,
						name: expense.name,
						amount: "\(expense.amount)",
						category: expense.category,
						details: expense.details ?? "",
						rating: expense.rating ?? 3,
						memo: expense.memo ?? "",
						excludeFromBudget: expense.excludeFromBudget,
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
