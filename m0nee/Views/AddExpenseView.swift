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
	
	@AppStorage("categories") private var categoriesString: String = "Food,Transport,Other"
	
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
		ScrollView {
			VStack(spacing: 24) {
				VStack(spacing: 8) {
					Text(formattedAmount)
						.font(.system(size: 48, weight: .bold))
						.foregroundColor(.primary)
						.padding(.top, 16)
						.onTapGesture { isAmountFocused = true }

					TextField("", text: $rawAmount)
						.keyboardType(.numberPad)
						.focused($isAmountFocused)
						.opacity(0.01)
						.frame(height: 1)
				}

				VStack(spacing: 8) {
					GeometryReader { geometry in
						HStack(spacing: 8) {
							Spacer()
							ForEach(1...5, id: \.self) { index in
								Image(systemName: index <= rating ? "star.fill" : "star")
									.resizable()
									.frame(width: 32, height: 32)
									.foregroundColor(.yellow)
							}
							Spacer()
						}
						.contentShape(Rectangle())
						.gesture(
							DragGesture(minimumDistance: 0)
								.onChanged { value in
									let spacing: CGFloat = 8
									let starWidth: CGFloat = 32
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
					.frame(height: 40)

					Text("How much did you enjoy this spending?")
						.font(.caption)
						.foregroundColor(.secondary)
				}

				VStack(alignment: .leading, spacing: 16) {
					Text("Required")
						.font(.caption)
						.foregroundColor(.secondary)

					TextField("Name", text: $name)
						.padding(10)
						.background(Color(.secondarySystemBackground))
						.cornerRadius(8)
						.overlay(
							RoundedRectangle(cornerRadius: 8)
								.stroke(showFieldValidation && name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.red : Color.clear, lineWidth: 1)
						)

					DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
						.padding(.leading, 10)

					HStack {
						Text("Category")
							.font(.body)
							.foregroundColor(.primary)

						Spacer()

						Picker("", selection: $category) {
							ForEach(categoryList, id: \.self) { Text($0) }
						}
						.pickerStyle(.menu)
					}
					.padding(.leading, 10)
					.padding(.trailing, -4)
				}

				VStack(alignment: .leading, spacing: 16) {
					Text("Optional")
						.font(.caption)
						.foregroundColor(.secondary)

					TextField("Details", text: $details)
						.padding(10)
						.background(Color(.secondarySystemBackground))
						.cornerRadius(8)

					TextField("Note", text: $memo)
						.padding(10)
						.background(Color(.secondarySystemBackground))
						.cornerRadius(8)

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
							.padding(.top, 8)
						}
					}
				}

				if let id = expenseID {
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
							.foregroundColor(.red)
							.frame(maxWidth: .infinity)
					}
					.padding(.top, 16)
				}

				Spacer(minLength: 24)
			}
			.padding()
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
						rating: rating,
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
