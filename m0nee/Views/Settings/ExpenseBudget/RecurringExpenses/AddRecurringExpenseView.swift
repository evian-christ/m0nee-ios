import SwiftUI

struct AddRecurringExpenseView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject var store: ExpenseStore
	@EnvironmentObject var settings: AppSettings

	@State private var name: String = ""
	@State private var rawAmount: String = ""
	@State private var category: String = ""
	@State private var memo: String = ""
	@State private var details: String = ""
	@State private var startDate: Date = Date()
	@State private var recurrenceDraft = RecurrenceDraft()

	@State private var showingCategorySelection = false
	@State private var showingRepeatSelection = false
	@State private var showFieldValidation = false

	private let decimalDisplayMode: DecimalDisplayMode
	private let currencyCode: String

	init(decimalDisplayMode: DecimalDisplayMode, currencyCode: String) {
		self.decimalDisplayMode = decimalDisplayMode
		self.currencyCode = currencyCode
	}

	private var currencySymbol: String {
		CurrencyManager.symbol(for: currencyCode)
	}

	private var repeatDescription: LocalizedStringKey {
		let rule = recurrenceDraft
		switch rule.selectedPeriod {
		case .never:
			return "Never"
		case .daily:
			switch rule.frequencyType {
			case .weeklySelectedDays:
				let sortedWeekdays = rule.selectedWeekdays.sorted()
				let symbols = Calendar.current.shortWeekdaySymbols
				var grouped: [[Int]] = []
				var currentGroup: [Int] = []
				for day in sortedWeekdays {
					if currentGroup.isEmpty || day == currentGroup.last! + 1 {
						currentGroup.append(day)
					} else {
						grouped.append(currentGroup)
						currentGroup = [day]
					}
				}
				if !currentGroup.isEmpty {
					grouped.append(currentGroup)
				}
				let weekdayRanges = grouped.map { group in
					let first = symbols[group.first! - 1]
					let last = symbols[group.last! - 1]
					return group.count == 1 ? first : "\(first) - \(last)"
				}
				return LocalizedStringKey(weekdayRanges.joined(separator: ", "))
			case .monthlySelectedDays:
				let sortedDays = rule.selectedMonthDays.sorted()
				return LocalizedStringKey("days \(sortedDays.map(String.init).joined(separator: ", "))")
			case .everyN:
				return LocalizedStringKey("Every \(rule.dayInterval) days")
			}
		case .weekly:
			return LocalizedStringKey("Every \(rule.dayInterval) weeks")
		case .monthly:
			return LocalizedStringKey("Every \(rule.dayInterval) months")
		}
	}

	var body: some View {
		NavigationView {
			Form {
				Section(header: Text("Amount").font(.caption)) {
					HStack {
						Text(currencySymbol)
							.font(.system(size: 20, weight: .bold))
						TextField("0.00", text: $rawAmount)
							.keyboardType(.decimalPad)
							.font(.system(size: 20, weight: .bold))
					}
				}

				Section(header: Text("Required").font(.caption)) {
					ZStack(alignment: .trailing) {
						TextField("Name", text: $name)
							.padding(.trailing, 28)
							.onChange(of: name) { newValue in
								if newValue.count > 30 {
									name = String(newValue.prefix(30))
								}
							}
						if showFieldValidation && name.trimmingCharacters(in: .whitespaces).isEmpty {
							Image(systemName: "exclamationmark.circle.fill")
								.foregroundColor(.red)
								.padding(.trailing, 4)
								.transition(.opacity)
								.animation(.easeInOut(duration: 0.25), value: showFieldValidation)
						}
					}

					DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])

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
					.navigationTitle("Select Category"), isActive: $showingCategorySelection) {
						HStack {
							Text("Category")
							Spacer()
							ZStack(alignment: .trailing) {
								Text(category)
									.foregroundColor(.secondary)
									.lineLimit(1)
									.truncationMode(.tail)
									.layoutPriority(1)
									.frame(maxWidth: .infinity, alignment: .trailing)

								if showFieldValidation && category.isEmpty {
									Image(systemName: "exclamationmark.circle.fill")
										.foregroundColor(.red)
										.padding(.trailing, 4)
										.transition(.opacity)
										.animation(.easeInOut(duration: 0.25), value: showFieldValidation)
								}
							}
						}
					}
				}

				Section(header: Text("Optional").font(.caption)) {
					TextField("Details", text: $details)
						.onChange(of: details) { newValue in
							if newValue.count > 500 {
								details = String(newValue.prefix(500))
							}
						}
					TextField("Note", text: $memo)
						.onChange(of: memo) { newValue in
							if newValue.count > 500 {
								memo = String(newValue.prefix(500))
							}
						}
				}

				Section {
					NavigationLink(destination: RepeatExpenseView(draft: $recurrenceDraft), isActive: $showingRepeatSelection) {
						HStack {
							Text("Repeat")
							Spacer()
							Text(repeatDescription)
								.foregroundColor(.secondary)
						}
					}
				}
			}
			.navigationTitle("Add Recurring Expense")
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
							  !rawAmount.trimmingCharacters(in: .whitespaces).isEmpty,
							  !category.isEmpty,
							  recurrenceDraft.selectedPeriod != .never else {
							return
						}

						let parsedAmount = (Double(rawAmount) ?? 0)
						let frequencyType = recurrenceDraft.frequencyType

						let rule = RecurrenceRule(
							period: RecurrenceRule.Period(rawValue: recurrenceDraft.selectedPeriod.rawValue.lowercased()) ?? .daily,
							frequencyType: frequencyType,
							interval: recurrenceDraft.dayInterval,
							selectedWeekdays: recurrenceDraft.selectedWeekdays.isEmpty ? nil : recurrenceDraft.selectedWeekdays,
							selectedMonthDays: recurrenceDraft.selectedMonthDays.isEmpty ? nil : recurrenceDraft.selectedMonthDays,
							startDate: startDate,
							endDate: nil
						)

						let newRecurring = RecurringExpense(
							id: UUID(),
							name: name,
							amount: parsedAmount,
							category: category,
							details: details.isEmpty ? nil : details,
							rating: nil,
							memo: memo.isEmpty ? nil : memo,
							startDate: startDate,
							recurrenceRule: rule,
							lastGeneratedDate: nil
						)

						store.addRecurringExpense(newRecurring)
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
	}
}
