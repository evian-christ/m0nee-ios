import SwiftUI

struct AddExpenseView: View {
	@Environment(\.dismiss) private var dismiss
	
	@State private var expenseID: UUID?
	@State private var date: Date
	@State private var name: String
	@State private var amount: String
	@State private var category: String
	@State private var details: String
	@State private var rating: Int
	@State private var memo: String
	@State private var showFieldValidation = false
	@State private var isRecurring: Bool = false
	@AppStorage("currencyCode") private var currencyCode: String = "GBP"
	@FocusState private var isAmountFocused: Bool
	@State private var rawAmount: String = ""
	@State private var showingCategorySelection = false
	@EnvironmentObject var store: ExpenseStore
	
	@AppStorage("categories") private var categoriesString: String = "Food,Transport,Other"
	@AppStorage("showRating") private var showRating: Bool = true
	
	var categoryList: [String] {
		categoriesString.split(separator: ",").map { String($0) }
	}
	
	var onSave: (Expense) -> Void
	
	init(
		expenseID: UUID? = nil,
		date: Date = Date(),
		name: String = "",
		amount: String = "",
		category: String = "Food",
		details: String = "",
		rating: Int = 3,
		memo: String = "",
		isRecurring: Bool = false,
		onSave: @escaping (Expense) -> Void
	) {
		_expenseID = State(initialValue: expenseID)
		_date = State(initialValue: date)
		_name = State(initialValue: name)
		_amount = State(initialValue: amount)
		let amountDouble = Double(amount) ?? 0
		let integerValue = Int(amountDouble * 100)
		_rawAmount = State(initialValue: "\(integerValue)")
		_category = State(initialValue: category)
		_details = State(initialValue: details)
		_rating = State(initialValue: rating)
		_memo = State(initialValue: memo)
		_isRecurring = State(initialValue: isRecurring)
		self.onSave = onSave
	}
	
	private var currencySymbol: String {
		CurrencyManager.symbol(for: currencyCode)
	}
	
	private var formattedAmount: String {
		let digits = rawAmount.filter { $0.isWholeNumber }
		let doubleValue = (Double(digits) ?? 0) / 100
		return String(format: "\(currencySymbol)%.2f", doubleValue)
	}
	
	var body: some View {
		Form {
			Section {
				VStack(spacing: 8) {
					Text(formattedAmount)
						.font(.system(size: 48, weight: .bold))
						.foregroundColor(.primary)
						.frame(maxWidth: .infinity, alignment: .center)
						.padding(.top, 8)
						.onTapGesture { isAmountFocused = true }

					TextField("", text: $rawAmount)
						.keyboardType(.numberPad)
						.focused($isAmountFocused)
						.opacity(0.01)
						.frame(height: 1)
				}
				.listRowSeparator(.hidden)

				if showRating {
					VStack(spacing: 4) {
						GeometryReader { geometry in
							HStack(spacing: 8) {
								Spacer()
								ForEach(1...5, id: \.self) { index in
									Image(systemName: index <= rating ? "star.fill" : "star")
										.resizable()
										.frame(width: 28, height: 28)
										.foregroundColor(.yellow)
								}
								Spacer()
							}
							.contentShape(Rectangle())
							.gesture(
								DragGesture(minimumDistance: 0)
									.onChanged { value in
										let spacing: CGFloat = 8
										let starWidth: CGFloat = 28
										let totalWidth = (starWidth * 5) + (spacing * 4)
										let startX = (geometry.size.width - totalWidth) / 2
										let relativeX = value.location.x - startX
										let fullStarWidth = starWidth + spacing
										let newRating = min(5, max(1, Int(relativeX / fullStarWidth) + 1))
										if newRating != rating {
											rating = newRating
										}
									}
							)
						}
						.frame(height: 36)

						Text("How much did you enjoy this spending?")
							.font(.caption)
							.foregroundColor(.secondary)
							.frame(maxWidth: .infinity, alignment: .center)
					}
					.padding(.top, -4)
				}
			}

			Section("Required") {
				TextField("Name", text: $name)

				DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

				NavigationLink(destination: List {
					ForEach(store.categories) { item in
						Button {
							category = item.name
							showingCategorySelection = false
						} label: {
							HStack(spacing: 12) {
								ZStack {
									Circle()
										.fill(Color(item.color.color))
										.frame(width: 28, height: 28)
									Image(systemName: item.symbol)
										.foregroundColor(.white)
										.font(.system(size: 14, weight: .semibold))
								}
								Text(item.name)
									.foregroundColor(.primary)
								if item.name == category {
									Spacer()
									Image(systemName: "checkmark")
								}
							}
						}
					}
				}
				.navigationTitle("Select Category")
				, isActive: $showingCategorySelection) {
					HStack {
						Text("Category")
						Spacer()
						Text(category)
							.foregroundColor(.secondary)
					}
				}
			}

			Section("Optional") {
				TextField("Details", text: $details)
				TextField("Note", text: $memo)

				if expenseID == nil {
					Toggle("Recurring Expense", isOn: $isRecurring)

					if isRecurring {
						VStack(alignment: .leading, spacing: 8) {
							Text("Repeat every...")
								.font(.subheadline)
								.foregroundColor(.secondary)
							Picker("Frequency", selection: .constant("Monthly")) {
								Text("Daily").tag("Daily")
								Text("Weekly").tag("Weekly")
								Text("Monthly").tag("Monthly")
								Text("Yearly").tag("Yearly")
							}
							.pickerStyle(.segmented)
						}
					}
				}
			}

			if let id = expenseID {
				Section {
					Button(role: .destructive) {
						onSave(Expense(
							id: id,
							date: date,
							name: name,
							amount: -1,
							category: category,
							details: details,
							rating: rating,
							memo: memo,
							isRecurring: isRecurring
						))
						dismiss()
					} label: {
						Text("Delete Expense")
							.frame(maxWidth: .infinity, alignment: .center)
					}
				}
			}
		}
		.navigationTitle(name.isEmpty ? "Add Expense" : "Edit \(name)")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Cancel") {
					dismiss()
				}
			}
			ToolbarItem(placement: .navigationBarTrailing) {
				Button("Save") {
					showFieldValidation = true
					guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
							!rawAmount.trimmingCharacters(in: .whitespaces).isEmpty else {
						return
					}
					let parsedAmount = (Double(rawAmount.filter { $0.isWholeNumber }) ?? 0) / 100
					let newExpense = Expense(
						id: expenseID ?? UUID(),
						date: date,
						name: name,
						amount: parsedAmount,
						category: category,
						details: details.isEmpty ? nil : details,
						rating: showRating ? rating : (expenseID != nil ? self.rating : 5),
						memo: memo.isEmpty ? nil : memo,
						isRecurring: isRecurring
					)
					onSave(newExpense)
					dismiss()
				}
			}
		}
	}
}
