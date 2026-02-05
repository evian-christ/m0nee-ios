import SwiftUI

struct AddExpenseView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject var settings: AppSettings
	@EnvironmentObject var store: ExpenseStore

	@State private var currentPage = 0
	@State private var expenseID: UUID?
	@State private var amount: String = ""
	@State private var name: String = ""
	@State private var date: Date = Date()
	@State private var category: String = ""
	@State private var rating: Int = 5
	@State private var details: String = ""
	@State private var memo: String = ""
	@State private var excludeFromBudget: Bool = false

	var onSave: (Expense) -> Void

	init(
		expenseID: UUID? = nil,
		date: Date = Date(),
		name: String = "",
		amount: String = "",
		category: String = "",
		details: String = "",
		rating: Int = 5,
		memo: String = "",
		excludeFromBudget: Bool = false,
		onSave: @escaping (Expense) -> Void
	) {
		_expenseID = State(initialValue: expenseID)
		_date = State(initialValue: date)
		_name = State(initialValue: name)
		_amount = State(initialValue: amount)
		_category = State(initialValue: category)
		_details = State(initialValue: details)
		_rating = State(initialValue: rating)
		_memo = State(initialValue: memo)
		_excludeFromBudget = State(initialValue: excludeFromBudget)
		self.onSave = onSave
	}

	private var currencySymbol: String {
		CurrencyManager.symbol(for: settings.currencyCode)
	}

	private var canProceed: Bool {
		switch currentPage {
		case 0: return !amount.isEmpty && (Double(amount) ?? 0) > 0
		case 1: return !name.trimmingCharacters(in: .whitespaces).isEmpty
		case 2: return true
		case 3: return !category.isEmpty
		case 4: return true
		case 5: return true
		default: return false
		}
	}

	var body: some View {
		VStack(spacing: 0) {
			// Progress indicator
			HStack(spacing: 8) {
				ForEach(0..<6) { index in
					Circle()
						.fill(index <= currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
						.frame(width: 8, height: 8)
				}
			}
			.padding()
			.background(Color(.systemGroupedBackground))

			// Page content
			TabView(selection: $currentPage) {
				amountPage.tag(0)
				namePage.tag(1)
				datePage.tag(2)
				categoryPage.tag(3)
				ratingPage.tag(4)
				notesPage.tag(5)
			}
			.tabViewStyle(.page(indexDisplayMode: .never))
			.animation(.easeInOut, value: currentPage)
		}
		.background(Color(.systemGroupedBackground))
		.navigationTitle("Add Expense")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Cancel") {
					dismiss()
				}
			}
		}
		.onAppear {
			if category.isEmpty, let firstCategory = store.categories.first?.name {
				category = firstCategory
			}
		}
	}

	// MARK: - Page 1: Amount

	private var amountPage: some View {
		VStack(spacing: 32) {
			Spacer()

			VStack(spacing: 16) {
				Text("How much?")
					.font(.system(size: 28, weight: .bold))

				HStack(spacing: 8) {
					Text(currencySymbol)
						.font(.system(size: 48, weight: .semibold))
						.foregroundColor(.secondary)

					TextField("0", text: $amount)
						.keyboardType(.decimalPad)
						.font(.system(size: 48, weight: .semibold))
						.multilineTextAlignment(.leading)
						.frame(maxWidth: 200)
				}
			}

			Spacer()

			Button {
				if canProceed {
					withAnimation {
						currentPage = 1
					}
				}
			} label: {
				Text("Next")
					.font(.headline)
					.foregroundColor(.white)
					.frame(maxWidth: .infinity)
					.frame(height: 50)
					.background(canProceed ? Color.accentColor : Color.secondary)
					.cornerRadius(12)
			}
			.disabled(!canProceed)
			.padding(.horizontal, 24)
			.padding(.bottom, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(.systemGroupedBackground))
	}

	// MARK: - Page 2: Name

	private var namePage: some View {
		VStack(spacing: 32) {
			Spacer()

			VStack(spacing: 16) {
				Text("What did you buy?")
					.font(.system(size: 28, weight: .bold))

				TextField("Expense name", text: $name)
					.font(.system(size: 24))
					.multilineTextAlignment(.center)
					.padding()
					.background(Color(.secondarySystemBackground))
					.cornerRadius(12)
					.padding(.horizontal, 32)
					.onChange(of: name) { newValue in
						if newValue.count > 30 {
							name = String(newValue.prefix(30))
						}
					}
			}

			Spacer()

			HStack(spacing: 16) {
				Button {
					withAnimation {
						currentPage = 0
					}
				} label: {
					Text("Back")
						.font(.headline)
						.foregroundColor(.accentColor)
						.frame(maxWidth: .infinity)
						.frame(height: 50)
						.background(Color(.systemBackground))
						.cornerRadius(12)
				}

				Button {
					if canProceed {
						withAnimation {
							currentPage = 2
						}
					}
				} label: {
					Text("Next")
						.font(.headline)
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.frame(height: 50)
						.background(canProceed ? Color.accentColor : Color.secondary)
						.cornerRadius(12)
				}
				.disabled(!canProceed)
			}
			.padding(.horizontal, 24)
			.padding(.bottom, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(.systemGroupedBackground))
	}

	// MARK: - Page 3: Date

	private var datePage: some View {
		VStack(spacing: 32) {
			Spacer()

			VStack(spacing: 16) {
				Text("When?")
					.font(.system(size: 28, weight: .bold))

				DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
					.datePickerStyle(.graphical)
					.labelsHidden()
					.padding()
			}

			Spacer()

			HStack(spacing: 16) {
				Button {
					withAnimation {
						currentPage = 1
					}
				} label: {
					Text("Back")
						.font(.headline)
						.foregroundColor(.accentColor)
						.frame(maxWidth: .infinity)
						.frame(height: 50)
						.background(Color(.systemBackground))
						.cornerRadius(12)
				}

				Button {
					withAnimation {
						currentPage = 3
					}
				} label: {
					Text("Next")
						.font(.headline)
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.frame(height: 50)
						.background(Color.accentColor)
						.cornerRadius(12)
				}
			}
			.padding(.horizontal, 24)
			.padding(.bottom, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(.systemGroupedBackground))
	}

	// MARK: - Page 4: Category

	private var categoryPage: some View {
		VStack(spacing: 32) {
			Text("Category")
				.font(.system(size: 28, weight: .bold))
				.padding(.top, 32)

			ScrollView {
				LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
					ForEach(store.categories) { item in
						Button {
							category = item.name
						} label: {
							VStack(spacing: 8) {
								ZStack {
									Circle()
										.fill(item.color.color.opacity(category == item.name ? 1 : 0.3))
										.frame(width: 60, height: 60)
									Image(systemName: item.symbol)
										.font(.system(size: 24))
										.foregroundColor(.white)
								}
								Text(item.name)
									.font(.caption)
									.foregroundColor(category == item.name ? .primary : .secondary)
							}
						}
					}
				}
				.padding(.horizontal, 24)
			}

			HStack(spacing: 16) {
				Button {
					withAnimation {
						currentPage = 2
					}
				} label: {
					Text("Back")
						.font(.headline)
						.foregroundColor(.accentColor)
						.frame(maxWidth: .infinity)
						.frame(height: 50)
						.background(Color(.systemBackground))
						.cornerRadius(12)
				}

				Button {
					if canProceed {
						withAnimation {
							currentPage = 4
						}
					}
				} label: {
					Text("Next")
						.font(.headline)
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.frame(height: 50)
						.background(canProceed ? Color.accentColor : Color.secondary)
						.cornerRadius(12)
				}
				.disabled(!canProceed)
			}
			.padding(.horizontal, 24)
			.padding(.bottom, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(.systemGroupedBackground))
	}

	// MARK: - Page 5: Rating

	private var ratingPage: some View {
		VStack(spacing: 32) {
			Spacer()

			VStack(spacing: 16) {
				Text("Rate this purchase")
					.font(.system(size: 28, weight: .bold))

				HStack(spacing: 12) {
					ForEach(1...5, id: \.self) { index in
						Button {
							rating = index
						} label: {
							Image(systemName: index <= rating ? "star.fill" : "star")
								.resizable()
								.frame(width: 40, height: 40)
								.foregroundColor(.yellow)
						}
					}
				}
			}

			Spacer()

			HStack(spacing: 16) {
				Button {
					withAnimation {
						currentPage = 3
					}
				} label: {
					Text("Back")
						.font(.headline)
						.foregroundColor(.accentColor)
						.frame(maxWidth: .infinity)
						.frame(height: 50)
						.background(Color(.systemBackground))
						.cornerRadius(12)
				}

				Button {
					withAnimation {
						currentPage = 5
					}
				} label: {
					Text("Next")
						.font(.headline)
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.frame(height: 50)
						.background(Color.accentColor)
						.cornerRadius(12)
				}
			}
			.padding(.horizontal, 24)
			.padding(.bottom, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(.systemGroupedBackground))
	}

	// MARK: - Page 6: Notes & Add

	private var notesPage: some View {
		VStack(spacing: 32) {
			Spacer()

			VStack(spacing: 16) {
				Text("Add a note")
					.font(.system(size: 28, weight: .bold))

				Text("(optional)")
					.font(.subheadline)
					.foregroundColor(.secondary)

				TextField("Notes...", text: $details, axis: .vertical)
					.lineLimit(3...6)
					.font(.system(size: 16))
					.padding()
					.background(Color(.secondarySystemBackground))
					.cornerRadius(12)
					.padding(.horizontal, 32)
					.onChange(of: details) { newValue in
						if newValue.count > 200 {
							details = String(newValue.prefix(200))
						}
					}
			}

			Spacer()

			HStack(spacing: 16) {
				Button {
					withAnimation {
						currentPage = 4
					}
				} label: {
					Text("Back")
						.font(.headline)
						.foregroundColor(.accentColor)
						.frame(maxWidth: .infinity)
						.frame(height: 50)
						.background(Color(.systemBackground))
						.cornerRadius(12)
				}

				Button {
					saveExpense()
				} label: {
					Text("Add Expense")
						.font(.headline)
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.frame(height: 50)
						.background(Color.accentColor)
						.cornerRadius(12)
				}
			}
			.padding(.horizontal, 24)
			.padding(.bottom, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(.systemGroupedBackground))
	}

	// MARK: - Save Logic

	private func saveExpense() {
		let parsedAmount = (Double(amount) ?? 0)

		let newExpense = Expense(
			id: expenseID ?? UUID(),
			date: date,
			name: name,
			amount: parsedAmount,
			category: category,
			details: details.isEmpty ? nil : details,
			rating: settings.showRating ? rating : 5,
			memo: memo.isEmpty ? nil : memo,
			isRecurring: false,
			parentRecurringID: nil,
			excludeFromBudget: excludeFromBudget
		)

		onSave(newExpense)
		dismiss()
	}
}
