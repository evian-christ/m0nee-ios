import SwiftUI

struct EditExpenseView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject var settings: AppSettings
	@EnvironmentObject var store: ExpenseStore
	@State private var recurrenceDraft = RecurrenceDraft()

	enum Field {
		case amount, name, details, memo
	}
	@FocusState private var focusedField: Field?

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
	@State private var repeatSummary: String = "Never"
	@State private var rawAmount: String = ""
	@State private var showingCategorySelection = false
	@State private var showingRepeatSelection = false
	@State private var showingProUpgrade = false
	@State private var excludeFromBudget: Bool = false

	@State private var showingDeleteAlert = false
	@State private var showingDuplicateAlert = false
	@State private var showAmountTooLargeAlert = false

	private var currencyCode: String { settings.currencyCode }
	private var decimalDisplayMode: DecimalDisplayMode { settings.decimalDisplayMode }
	private var showRating: Bool { settings.showRating }

	private var currencySymbol: String {
		CurrencyManager.symbol(for: currencyCode)
	}

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
		isRecurring: Bool = false,
		excludeFromBudget: Bool = false,
		onSave: @escaping (Expense) -> Void
	) {
		_expenseID = State(initialValue: expenseID)
		_date = State(initialValue: date)
		_name = State(initialValue: name)
		_amount = State(initialValue: amount)
		_rawAmount = State(initialValue: amount)
		let defaultCategory = category.isEmpty ? "" : category
		_category = State(initialValue: defaultCategory)
		_details = State(initialValue: details)
		_rating = State(initialValue: rating)
		_memo = State(initialValue: memo)
		_isRecurring = State(initialValue: isRecurring)
		_excludeFromBudget = State(initialValue: excludeFromBudget)
		self.onSave = onSave
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

	// MARK: - Body

	var body: some View {
		Form {
			// MARK: - Hero Amount Section
			Section {
				HStack(spacing: 4) {
					Text(currencySymbol)
						.font(.system(size: 48, weight: .bold))
					TextField("0", text: $rawAmount)
						.keyboardType(.decimalPad)
						.font(.system(size: 48, weight: .bold))
						.foregroundColor(.secondary)
						.multilineTextAlignment(.leading)
						.focused($focusedField, equals: .amount)
						.fixedSize(horizontal: true, vertical: false)
						.onChange(of: focusedField) { newValue in
							if newValue == .amount {
								rawAmount = ""
							}
						}
				}
				.lineLimit(1)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 12)
			}
			.listRowBackground(Color.clear)
			.listRowSeparator(.hidden)

			// MARK: - Required Info
			Section {
				ZStack(alignment: .trailing) {
					TextField("Name", text: $name)
						.focused($focusedField, equals: .name)
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

				DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

				NavigationLink(destination: categoryPickerList, isActive: $showingCategorySelection) {
					HStack {
						Text("Category")
						Spacer()
						ZStack(alignment: .trailing) {
							if let item = store.categories.first(where: { $0.name == category }) {
								HStack(spacing: 6) {
									ZStack {
										Circle()
											.fill(item.color.color.opacity(0.15))
											.frame(width: 24, height: 24)
										Image(systemName: item.symbol)
											.font(.system(size: 12))
											.foregroundColor(item.color.color)
									}
									Text(category)
										.foregroundColor(.secondary)
								}
							} else {
								Text(category)
									.foregroundColor(.secondary)
							}

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

			// MARK: - Rating
			if showRating && !isRecurring {
				Section("Rating") {
					HStack(spacing: 6) {
						ForEach(1...5, id: \.self) { index in
							Button {
								rating = index
							} label: {
								Image(systemName: index <= rating ? "star.fill" : "star")
									.font(.system(size: 22))
									.foregroundColor(index <= rating ? .yellow : Color(.systemGray3))
							}
							.buttonStyle(.plain)
						}
						Spacer()
					}
					.padding(.vertical, 2)
				}
			}

			// MARK: - Optional Details
			Section {
				TextField("Details", text: $details)
					.focused($focusedField, equals: .details)
					.onChange(of: details) { newValue in
						if newValue.count > 100 {
							details = String(newValue.prefix(100))
						}
					}
				TextField("Note", text: $memo)
					.focused($focusedField, equals: .memo)
					.onChange(of: memo) { newValue in
						if newValue.count > 500 {
							memo = String(newValue.prefix(500))
						}
					}
			}

			// MARK: - Options
			Section {
				Toggle("Exclude from budget", isOn: $excludeFromBudget)
			}

			if expenseID == nil {
				Section {
					if store.isProUser {
						NavigationLink(destination: RepeatExpenseView(draft: $recurrenceDraft), isActive: $showingRepeatSelection) {
							HStack {
								Text("Repeat")
								Spacer()
								Text(repeatDescription)
									.foregroundColor(.secondary)
							}
						}
					} else {
						NavigationLink(destination: ProUpgradeModalView(isPresented: .constant(true)), isActive: $showingProUpgrade) {
							HStack {
								Text("Repeat")
								Spacer()
								Text(repeatDescription)
									.foregroundColor(.secondary)
							}
						}
					}
				}
			}

			// MARK: - Delete
			if expenseID != nil {
				Section {
					Button(role: .destructive) {
						showingDeleteAlert = true
					} label: {
						Text("Delete Expense")
							.frame(maxWidth: .infinity, alignment: .center)
					}
					.confirmationDialog("Delete this expense?", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
						deleteDialogButtons
					}
				}
			}
		}
		.alert("Duplicate Expense", isPresented: $showingDuplicateAlert) {
			Button("Add Anyway", role: .destructive) {
				let parsedAmount = (abs(Double(rawAmount) ?? 0) * 100).rounded() / 100
				let recurringID: UUID? = nil
				let newExpense = Expense(
					id: expenseID ?? UUID(),
					date: date,
					name: name,
					amount: parsedAmount,
					category: category,
					details: details.isEmpty ? nil : details,
					rating: showRating ? rating : (expenseID != nil ? self.rating : 5),
					memo: memo.isEmpty ? nil : memo,
					isRecurring: isRecurring,
					parentRecurringID: recurringID,
					excludeFromBudget: excludeFromBudget
				)
				onSave(newExpense)
				dismiss()
			}
			Button("Cancel", role: .cancel) { }
		} message: {
			Text("A similar expense already exists. Are you sure you want to add this?")
		}
		.alert("Amount Too Large", isPresented: $showAmountTooLargeAlert) {
			Button("OK", role: .cancel) { }
		} message: {
			Text("The entered amount exceeds the maximum allowed. Please double-check the amount.")
		}
		.onAppear {
			if let expenseID = expenseID {
				if let expense = store.expenses.first(where: { $0.id == expenseID }) {
					self.isRecurring = expense.isRecurring
				}
			}
			if category.isEmpty, let firstCategory = store.categories.first?.name {
				category = firstCategory
			}
		}
		.navigationTitle(name.isEmpty ? "Edit Expense" : "Edit \(name)")
		.navigationBarTitleDisplayMode(.inline)
		.onChange(of: showingRepeatSelection) { newValue in
			if newValue { focusedField = nil }
		}
		.onChange(of: showingProUpgrade) { newValue in
			if newValue { focusedField = nil }
		}
		.onChange(of: showingCategorySelection) { newValue in
			if newValue { focusedField = nil }
		}
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Cancel") { dismiss() }
			}
			ToolbarItem(placement: .navigationBarTrailing) {
				Button("Save") { saveExpense() }
			}
		}
	}

	// MARK: - Category Picker

	private var categoryPickerList: some View {
		List {
			ForEach(store.categories) { item in
				Button {
					category = item.name
					showingCategorySelection = false
				} label: {
					HStack(spacing: 12) {
						ZStack {
							Circle()
								.fill(item.color.color)
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
								.foregroundColor(.accentColor)
						}
					}
				}
			}
		}
		.navigationTitle("Select Category")
	}

	// MARK: - Delete Dialog

	@ViewBuilder
	private var deleteDialogButtons: some View {
		let parentExists = store.recurringExpenses.first { $0.id == store.expenses.first(where: { $0.id == expenseID })?.parentRecurringID } != nil
		if let id = expenseID, let parentID = store.expenses.first(where: { $0.id == id })?.parentRecurringID, parentExists {
			Button("Delete only this expense", role: .destructive) {
				onSave(makeDeleteExpense(id: id, parentRecurringID: parentID))
				dismiss()
			}
			Button("Delete this and recurring rule", role: .destructive) {
				store.removeRecurringExpense(id: parentID)
				onSave(makeDeleteExpense(id: id, parentRecurringID: parentID))
				dismiss()
			}
			Button("Delete rule and all related expenses", role: .destructive) {
				store.removeAllExpenses(withParentID: parentID)
				store.removeRecurringExpense(id: parentID)
				onSave(makeDeleteExpense(id: id, parentRecurringID: parentID))
				dismiss()
			}
		} else if let id = expenseID {
			Button("Delete", role: .destructive) {
				onSave(makeDeleteExpense(id: id, parentRecurringID: nil))
				dismiss()
			}
		}
		Button("Cancel", role: .cancel) {}
	}

	// MARK: - Helpers

	private func makeDeleteExpense(id: UUID, parentRecurringID: UUID?) -> Expense {
		Expense(
			id: id,
			date: date,
			name: name,
			amount: -1,
			category: category,
			details: details,
			rating: rating,
			memo: memo,
			isRecurring: isRecurring,
			parentRecurringID: parentRecurringID
		)
	}

	private func saveExpense() {
		showFieldValidation = true
		guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
			  !rawAmount.trimmingCharacters(in: .whitespaces).isEmpty,
			  !category.isEmpty else {
			return
		}
		if expenseID == nil {
			isRecurring = recurrenceDraft.selectedPeriod != .never
		} else {
			isRecurring = store.expenses.first(where: { $0.id == expenseID })?.isRecurring ?? false
		}

		let rawDouble = Double(rawAmount) ?? 0
		let parsedAmount = (abs(rawDouble) * 100).rounded() / 100
		let maxAllowedAmount: Double = 100_000_000
		if parsedAmount > maxAllowedAmount {
			showAmountTooLargeAlert = true
			return
		}

		let isDuplicate = store.expenses.contains {
			$0.id != expenseID &&
			$0.name == name &&
			Calendar.current.isDate($0.date, inSameDayAs: date) &&
			$0.amount == parsedAmount &&
			$0.category == category
		}
		if isDuplicate {
			showingDuplicateAlert = true
			return
		}

		let frequencyType = recurrenceDraft.frequencyType
		var recurringID: UUID? = nil

		if expenseID == nil && isRecurring {
			let rule = RecurrenceRule(
				period: RecurrenceRule.Period(rawValue: recurrenceDraft.selectedPeriod.rawValue.lowercased()) ?? .daily,
				frequencyType: frequencyType,
				interval: recurrenceDraft.dayInterval,
				selectedWeekdays: recurrenceDraft.selectedWeekdays.isEmpty ? nil : recurrenceDraft.selectedWeekdays,
				selectedMonthDays: recurrenceDraft.selectedMonthDays.isEmpty ? nil : recurrenceDraft.selectedMonthDays,
				startDate: date,
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
				startDate: date,
				recurrenceRule: rule,
				lastGeneratedDate: nil
			)

			recurringID = newRecurring.id
			store.addRecurringExpense(newRecurring)
		}

		let newExpense = Expense(
			id: expenseID ?? UUID(),
			date: date,
			name: name,
			amount: parsedAmount,
			category: category,
			details: details.isEmpty ? nil : details,
			rating: isRecurring ? nil : (showRating ? rating : 5),
			memo: memo.isEmpty ? nil : memo,
			isRecurring: isRecurring,
			parentRecurringID: recurringID,
			excludeFromBudget: excludeFromBudget
		)

		if expenseID == nil && isRecurring {
			// Do not save Expense; handled by RecurringExpense logic
		} else {
			onSave(newExpense)
		}
		dismiss()
	}
}
