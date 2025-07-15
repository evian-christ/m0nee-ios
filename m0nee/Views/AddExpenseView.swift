import SwiftUI

enum Period: String, CaseIterable, Identifiable, Codable, LocalizedCaseIterable {
	case never = "Never"
	case daily = "Daily"
	case weekly = "Weekly"
	case monthly = "Monthly"
	
	var id: String { self.rawValue }
	
	var localizedStringKey: LocalizedStringKey {
		switch self {
		case .never: return "Never"
		case .daily: return "Daily"
		case .weekly: return "Weekly"
		case .monthly: return "Monthly"
		}
	}
}

struct RecurrenceDraft {
	var selectedPeriod: Period = .never
	var frequencyType: RecurrenceRule.FrequencyType = .everyN
	var selectedWeekdays: [Int] = []
	var selectedMonthDays: [Int] = []
	var dayInterval: Int = 1 {
		didSet {
			if dayInterval < 1 {
				dayInterval = 1
			}
		}
	}
}


struct AddExpenseView: View {
	@Environment(\.dismiss) private var dismiss
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
	@AppStorage("currencyCode", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
	@State private var rawAmount: String = ""
	@State private var showingCategorySelection = false
	@State private var showingRepeatSelection = false
	@State private var showingProUpgrade = false
	@EnvironmentObject var store: ExpenseStore
	
	@AppStorage("categories") private var categoriesString: String = "Food,Transport,Other"
	@AppStorage("showRating") private var showRating: Bool = true
	@AppStorage("decimalDisplayMode") private var decimalDisplayMode: DecimalDisplayMode = .automatic
	@State private var showingDeleteAlert = false
	@State private var showingDuplicateAlert = false
	@State private var showAmountTooLargeAlert = false
		
	
	@ViewBuilder
	private var deleteDialogButtons: some View {
		let parentExists = store.recurringExpenses.first { $0.id == store.expenses.first(where: { $0.id == expenseID })?.parentRecurringID } != nil
		if let id = expenseID, let parentID = store.expenses.first(where: { $0.id == id })?.parentRecurringID, parentExists {
					Button("Delete only this expense", role: .destructive) {
						let expense = Expense(
							id: id,
							date: date,
							name: name,
							amount: -1,
							category: category,
							details: details,
							rating: rating,
							memo: memo,
							isRecurring: isRecurring,
							parentRecurringID: parentID
						)
						onSave(expense)
						dismiss()
					}
					Button("Delete this and recurring rule", role: .destructive) {
						store.removeRecurringExpense(id: parentID)
						let expense = Expense(
							id: id,
							date: date,
							name: name,
							amount: -1,
							category: category,
							details: details,
							rating: rating,
							memo: memo,
							isRecurring: isRecurring,
							parentRecurringID: parentID
						)
						onSave(expense)
						dismiss()
					}
					Button("Delete rule and all related expenses", role: .destructive) {
						store.removeAllExpenses(withParentID: parentID)
						store.removeRecurringExpense(id: parentID)
						let expense = Expense(
							id: id,
							date: date,
							name: name,
							amount: -1,
							category: category,
							details: details,
							rating: rating,
							memo: memo,
							isRecurring: isRecurring,
							parentRecurringID: parentID
						)
						onSave(expense)
						dismiss()
					}
			} else if let id = expenseID {
					Button("Delete", role: .destructive) {
						let expense = Expense(
							id: id,
							date: date,
							name: name,
							amount: -1,
							category: category,
							details: details,
							rating: rating,
							memo: memo,
							isRecurring: isRecurring
						)
						onSave(expense)
						dismiss()
					}
			}
			Button("Cancel", role: .cancel) {}
	}
	
	var categoryList: [String] {
		categoriesString.split(separator: ",").map { String($0) }
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
		self.onSave = onSave
	}
	
	private var currencySymbol: String {
		CurrencyManager.symbol(for: currencyCode)
	}
	
	private var formattedAmount: String {
		let digits = rawAmount.filter { $0.isWholeNumber }
		let doubleValue = (Double(digits) ?? 0) / 100
		return NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: doubleValue)) ?? ""
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
		Form {
			Section(header: Text("Amount").font(.caption)) {
				VStack(spacing: 8) {
					HStack {
						Text(currencySymbol)
							.font(.system(size: 20, weight: .bold))
						TextField("0.00", text: $rawAmount)
							.keyboardType(.decimalPad)
							.font(.system(size: 20, weight: .bold))
							.focused($focusedField, equals: .amount)
					}
					.listRowSeparator(.hidden)
				}
			}
			
			Section(header: Text("Required").font(.caption)) {
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
			
			if showRating && !isRecurring {
				Section(header: Text("Rating").font(.caption)) {
					HStack {
						Text("Rating")
							.font(.body)
							.foregroundColor(.primary)

						Spacer()

						GeometryReader { geometry in
							HStack(spacing: 6) {
								ForEach(1...5, id: \.self) { index in
									Image(systemName: index <= rating ? "star.fill" : "star")
										.resizable()
										.frame(width: 22, height: 22)
										.foregroundColor(.yellow)
								}
							}
							.frame(maxWidth: .infinity, alignment: .trailing)
							.contentShape(Rectangle())
							.gesture(
								DragGesture(minimumDistance: 0)
									.onChanged { value in
										let spacing: CGFloat = 6
										let starWidth: CGFloat = 22
										let width = geometry.size.width
										let totalWidth = (starWidth * 5) + (spacing * 4)
										let startX = width - totalWidth
										let relativeX = value.location.x - startX
										let newRating = min(5, max(1, Int(relativeX / (starWidth + spacing)) + 1))
										if newRating != rating {
											rating = newRating
										}
									}
							)
						}
						.frame(height: 24)
					}
					.padding(.vertical, 4)
				}
			}
			
			Section(header: Text("Optional").font(.caption)) {
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
	
			if let id = expenseID {
				let parentID = store.expenses.first(where: { $0.id == id })?.parentRecurringID
				Section(header: Text("Danger Zone").font(.caption)) {
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
				let recurringID: UUID? = nil // duplicate check only occurs for non-recurring
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
					parentRecurringID: recurringID
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
		.navigationTitle(name.isEmpty ? "Add Expense" : "Edit \(name)")
		.navigationBarTitleDisplayMode(.inline)
		.onChange(of: showingRepeatSelection) { newValue in
			if newValue {
				focusedField = nil
			}
		}
		.onChange(of: showingProUpgrade) { newValue in
			if newValue {
				focusedField = nil
			}
		}
		.onChange(of: showingCategorySelection) { newValue in
			if newValue {
				focusedField = nil
			}
		}
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
								!category.isEmpty else {
						return
					}
					if expenseID == nil {
						isRecurring = recurrenceDraft.selectedPeriod != .never
					} else {
						isRecurring = store.expenses.first(where: { $0.id == expenseID })?.isRecurring ?? false
					}
					// Removed old rawDouble declaration
					let rawDouble = Double(rawAmount) ?? 0
					let parsedAmount = (abs(rawDouble) * 100).rounded() / 100
					let maxAllowedAmount: Double = 100_000_000
					if parsedAmount > maxAllowedAmount {
							showAmountTooLargeAlert = true
							return
					}
					let frequencyType = recurrenceDraft.frequencyType

					var recurringID: UUID? = nil

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
						parentRecurringID: recurringID
					)

					if expenseID == nil && isRecurring {
						// Do not save Expense; handled by RecurringExpense logic
					} else {
						onSave(newExpense)
					}
					dismiss()
				}
			}
		}
	}
}