import SwiftUI
import StoreKit

struct ContentView: View {
	@EnvironmentObject var store: ExpenseStore
	@EnvironmentObject var settings: AppSettings
	@State private var pressedExpenseID: UUID?
	@State private var showingAddExpense = false
	@State private var showingSettings = false
	@State private var selectedMonth: String
	@State private var selectedWeekStart: Date = Calendar.current.startOfDay(for: Date())
	@State private var selectedExpenseID: UUID?

	private var currencyCode: String { settings.currencyCode }
	private var currencySymbol: String { CurrencyManager.symbol(for: currencyCode) }
	private var hasSeenTutorial: Bool { settings.hasSeenTutorial }
	private var displayMode: String { settings.displayMode }
	private var budgetPeriod: String { settings.budgetPeriod }
	private var appearanceMode: String { settings.appearanceMode }
	private var groupByDay: Bool { settings.groupByDay }
	private var showRating: Bool { settings.showRating }
	private var decimalDisplayMode: DecimalDisplayMode { settings.decimalDisplayMode }
	private var budgetByCategory: Bool { settings.budgetByCategory }
	private var monthlyBudget: Double { settings.monthlyBudget }
	private var weeklyStartDay: Int { settings.weeklyStartDay }
	private var monthlyStartDay: Int { settings.monthlyStartDay }
	
	private var displayedDateRange: String {
		if budgetPeriod == "Weekly" {
			let calendar = Calendar.current
			let today = Date()
			let startDay = weeklyStartDay
			let weekdayToday = calendar.component(.weekday, from: today)
			let delta = (weekdayToday - startDay + 7) % 7
			
			guard let weekStart = calendar.date(byAdding: .day, value: -Int(delta), to: today) else {
				return ""
			}
			
			let formatter = DateFormatter()
			formatter.dateFormat = "MMM d"
			return "Week of \(formatter.string(from: weekStart))"
		} else {
			return "\(displayMonth(selectedMonth)) (\(formattedRange(budgetDates)))"
		}
	}
	
	private var budgetDates: (startDate: Date, endDate: Date) {
		let calendar = Calendar.current
		let startDay = budgetPeriod == "Weekly" ? weeklyStartDay : monthlyStartDay
		
		if budgetPeriod == "Weekly" {
			let start = calendar.startOfDay(for: selectedWeekStart)
			let end = calendar.date(byAdding: .day, value: 6, to: start)!
			return (start, end)
		} else {
			let inputFormatter = DateFormatter()
			inputFormatter.dateFormat = "yyyy-MM"
			
			guard let baseDate = inputFormatter.date(from: selectedMonth) else {
				return (Date(), Date())
			}
			
			let monthStart = calendar.date(byAdding: .day, value: startDay - 1, to: baseDate)!
			let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
			let endDate = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
			return (calendar.startOfDay(for: monthStart), calendar.startOfDay(for: endDate))
		}
	}
	private var monthsWithExpenses: [String] {
		let calendar = Calendar.current
		let startDay = monthlyStartDay
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM"
		
		let adjustedMonths = store.expenses.map { expense -> String in
			let date = expense.date
			let monthStart: Date = {
				if calendar.component(.day, from: date) >= startDay {
					let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
					return calendar.date(byAdding: .day, value: startDay - 1, to: thisMonth)!
				} else {
					let previousMonth = calendar.date(byAdding: .month, value: -1, to: date)!
					let prevStart = calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth))!
					return calendar.date(byAdding: .day, value: startDay - 1, to: prevStart)!
				}
			}()
			return formatter.string(from: monthStart)
		}
		
		return Set(adjustedMonths).sorted(by: >)
	}
	private func formattedRange(_ range: (startDate: Date, endDate: Date)) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMM d"
		return "\(formatter.string(from: range.startDate)) - \(formatter.string(from: range.endDate))"
	}
	
	private var filteredExpenses: [Binding<Expense>] {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM"
		
		if budgetPeriod == "Weekly" {
			let calendar = Calendar.current
			let weekStart = selectedWeekStart
			guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
				return []
			}
			return $store.expenses
				.filter {
					let startOfDay = calendar.startOfDay(for: $0.wrappedValue.date)
					return startOfDay >= calendar.startOfDay(for: weekStart) && startOfDay <= calendar.startOfDay(for: weekEnd)
				}
				.sorted { $0.wrappedValue.date > $1.wrappedValue.date }
		} else if !selectedMonth.isEmpty {
			let dates = budgetDates
			let calendar = Calendar.current
			let start = calendar.startOfDay(for: dates.startDate)
			let end = calendar.startOfDay(for: dates.endDate)
			
			return $store.expenses
				.filter {
					let date = calendar.startOfDay(for: $0.wrappedValue.date)
					return date >= start && date <= end
				}
				.sorted { $0.wrappedValue.date > $1.wrappedValue.date }
		} else {
			return $store.expenses
				.sorted { $0.wrappedValue.date > $1.wrappedValue.date }
		}
	}
	
	init() {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM"
		let recentMonth = formatter.string(from: Date())
		_selectedMonth = State(initialValue: recentMonth)
		
		let calendar = Calendar.current
		let today = Date()
		let startDay = calendar.firstWeekday
		let weekdayToday = calendar.component(.weekday, from: today)
		let delta = (weekdayToday - startDay + 7) % 7
		let correctedWeekStart = calendar.date(byAdding: .day, value: -delta, to: today) ?? today
		_selectedWeekStart = State(initialValue: calendar.startOfDay(for: correctedWeekStart))
	}
	
	@ViewBuilder
	private func expenseRow(for expense: Binding<Expense>) -> some View {
		if displayMode == "Compact" {
			Button {
				pressedExpenseID = expense.wrappedValue.id
				DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
					selectedExpenseID = expense.wrappedValue.id
				}
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					pressedExpenseID = nil
				}
			} label: {
				VStack(spacing: 0) {
					ZStack {
						HStack(spacing: 12) {
							if let categoryItem = store.categories.first(where: { $0.name == expense.wrappedValue.category }) {
								ZStack {
									Circle()
										.fill(categoryItem.color.color)
										.frame(width: 24, height: 24)
									Image(systemName: categoryItem.symbol)
										.font(.system(size: 12))
										.foregroundColor(.white)
								}
							} else {
								ZStack {
									Circle()
										.fill(Color.gray.opacity(0.3))
										.frame(width: 24, height: 24)
									Image(systemName: "questionmark")
										.font(.system(size: 12))
										.foregroundColor(.gray)
								}
							}
							HStack(spacing: 4) {
								Text(expense.wrappedValue.name)
									.font(.body)
									.foregroundColor(.primary)
									.lineLimit(1)
									.truncationMode(.tail)
								if expense.wrappedValue.isRecurring {
									Image(systemName: "arrow.triangle.2.circlepath")
										.font(.caption)
										.foregroundColor(.blue)
								}
								if expense.wrappedValue.excludeFromBudget {
									Image(systemName: "circle.slash")
										.font(.caption)
										.foregroundColor(.orange)
								}
							}
							.layoutPriority(0.5)
							Spacer()
														Text(NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: expense.wrappedValue.amount)) ?? "")
								.font(.system(size: 17, weight: .medium))
								.foregroundColor(.primary)
								.layoutPriority(1)
							Image(systemName: "chevron.right")
								.font(.caption)
								.foregroundColor(.gray)
						}
						.padding(.horizontal, 20)
						.padding(.vertical, 10)
						.background(
							pressedExpenseID == expense.wrappedValue.id
								? Color.gray.opacity(0.3)
								: Color(.systemBackground)
						)
					}
					Divider()
				}
			}
			.buttonStyle(.plain)
			NavigationLink(
				destination: ExpenseDetailView(expenseID: expense.wrappedValue.id, store: store),
				tag: expense.wrappedValue.id,
				selection: $selectedExpenseID
			) {
				EmptyView()
			}
			.hidden()
		} else if displayMode == "Standard" {
			Button {
				pressedExpenseID = expense.wrappedValue.id
				DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
					selectedExpenseID = expense.wrappedValue.id
				}
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					pressedExpenseID = nil
				}
			} label: {
				ZStack {
					VStack(spacing: 8) {
						HStack(alignment: .center, spacing: 12) {
							if let categoryItem = store.categories.first(where: { $0.name == expense.wrappedValue.category }) {
								ZStack {
									Circle()
										.fill(categoryItem.color.color)
										.frame(width: 32, height: 32)
									Image(systemName: categoryItem.symbol)
										.font(.system(size: 14))
										.foregroundColor(.white)
								}
							} else {
								ZStack {
									Circle()
										.fill(Color.gray.opacity(0.3))
										.frame(width: 32, height: 32)
									Image(systemName: "questionmark")
										.font(.system(size: 14))
										.foregroundColor(.gray)
								}
							}

							VStack(alignment: .leading, spacing: 2) {
								HStack(spacing: 4) {
									Text(expense.wrappedValue.name)
										.lineLimit(1)
										.truncationMode(.tail)
									if expense.wrappedValue.isRecurring {
										Image(systemName: "arrow.triangle.2.circlepath")
											.font(.caption)
											.foregroundColor(.blue)
									}
									if expense.wrappedValue.excludeFromBudget {
										Image(systemName: "circle.slash")
											.font(.caption)
											.foregroundColor(.orange)
									}
								}
								.font(.system(.body, design: .default))
								.fontWeight(.semibold)
								.foregroundColor(.primary)

								Text(expense.wrappedValue.category)
									.font(.footnote)
									.foregroundColor(.secondary)
							}

							Spacer()

							VStack(alignment: .trailing, spacing: 2) {
															Text(NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: expense.wrappedValue.amount)) ?? "")
									.font(.system(size: 17, weight: .medium))
									.foregroundColor(.primary)

								Text(expense.wrappedValue.date.formatted(date: .abbreviated, time: .shortened))
									.font(.caption2)
									.foregroundColor(.gray)
							}

							Image(systemName: "chevron.right")
								.font(.caption)
								.foregroundColor(.gray)
						}
					}
					.padding(.horizontal)
					.padding(.vertical, 8)
					.background(
							pressedExpenseID == expense.wrappedValue.id
							? Color.gray.opacity(0.3) // ✅ 눌렀을 때 색상
							: Color(.systemBackground) // 기본 배경
					)
				}
			}
			.buttonStyle(.plain)

			NavigationLink(
				destination: ExpenseDetailView(expenseID: expense.wrappedValue.id, store: store),
				tag: expense.wrappedValue.id,
				selection: $selectedExpenseID
			) {
				EmptyView()
			}
			.hidden()
			Divider()
		} else if displayMode == "Detailed" {
			Button {
				pressedExpenseID = expense.wrappedValue.id
				DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
					selectedExpenseID = expense.wrappedValue.id
				}
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					pressedExpenseID = nil
				}
			} label: {
				VStack(spacing: 0) {
					ZStack {
						Color(.systemGray5).opacity(0.01)
						HStack(alignment: .top) {
							VStack(alignment: .leading, spacing: 8) {
								HStack {
									HStack(spacing: 4) {
										Text(expense.wrappedValue.name)
											.lineLimit(1)
											.truncationMode(.tail)
										if expense.wrappedValue.isRecurring {
											Image(systemName: "arrow.triangle.2.circlepath")
												.font(.caption)
												.foregroundColor(.blue)
										}
										if expense.wrappedValue.excludeFromBudget {
											Image(systemName: "circle.slash")
												.font(.caption)
												.foregroundColor(.orange)
										}
									}
									.font(.headline)
									.fontWeight(.semibold)
									.foregroundColor(.primary)
									Spacer()
																Text(NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: expense.wrappedValue.amount)) ?? "")
										.font(.system(size: 17, weight: .medium))
										.foregroundColor(.primary)
								}
								HStack {
									if let details = expense.wrappedValue.details, !details.isEmpty {
										Text(details)
											.font(.subheadline)
											.foregroundColor(.secondary)
									} else {
										Text(" ")
											.font(.subheadline)
									}
									Spacer()
									if showRating, let rating = expense.wrappedValue.rating {
										HStack(spacing: 2) {
											ForEach(1...5, id: \.self) { star in
												Image(systemName: star <= rating ? "star.fill" : "star")
													.font(.caption2)
													.foregroundColor(.yellow)
											}
										}
									}
								}
								HStack {
									Text(expense.wrappedValue.category)
										.font(.subheadline)
										.foregroundColor(.secondary)
									Spacer()
									Text(expense.wrappedValue.date.formatted(date: .abbreviated, time: .shortened))
										.font(.subheadline)
										.foregroundColor(.secondary)
								}
							}
							.padding(.trailing, 12)
							Spacer(minLength: 0)
						}
						.padding()
						.background(
							pressedExpenseID == expense.wrappedValue.id
								? Color.gray.opacity(0.3)
								: Color(.systemBackground)
						)
					}
				}
			}
			.buttonStyle(.plain)
			.overlay(
				HStack {
					Spacer()
					Image(systemName: "chevron.right")
						.foregroundColor(.gray)
						.padding(.trailing, 8)
				}
			)
			NavigationLink(
				destination: ExpenseDetailView(expenseID: expense.wrappedValue.id, store: store),
				tag: expense.wrappedValue.id,
				selection: $selectedExpenseID
			) {
				EmptyView()
			}
			.hidden()
			Divider()
		}
	}
	
	var body: some View {
		if hasSeenTutorial {
			mainBody
		} else {
			TutorialView()
		}
	}
	
	private var mainBody: some View {
		NavigationStack {
				ScrollView {
					VStack(spacing: 0) {
						let groupedByDate: [Date: [Binding<Expense>]] = Dictionary(
							grouping: filteredExpenses,
							by: { Calendar.current.startOfDay(for: $0.wrappedValue.date) }
						)
						let sortedDates = groupedByDate.keys.sorted(by: >)
						
						LazyVStack(spacing: 0) {
							if filteredExpenses.isEmpty {
								VStack(spacing: 16) {
									Text("No expenses here yet 💸")
										.font(.subheadline)
										.foregroundColor(.secondary)
										.padding(.top, 40)
									Text("Tap the ➕ up there and record your first glorious impulse buy.")
										.font(.footnote)
										.foregroundColor(.gray)
										.multilineTextAlignment(.center)
										.padding(.horizontal, 40)
								}
								.frame(maxWidth: .infinity)
							} else {
								if groupByDay {
									ForEach(sortedDates, id: \.self) { date in
										Section(header:
											HStack {
												Text(DateFormatter.m0neeListSection.string(from: date))
													.font(.caption)
													.foregroundColor(Color.blue.opacity(0.7))
												Spacer()
											}
											.padding(.horizontal, 16)
											.padding(.top, 15)
											.padding(.bottom, 8)
										) {
											ForEach(groupedByDate[date]!, id: \.id) { $expense in
												expenseRow(for: $expense)
											}
										}
									}
								} else {
									ForEach(filteredExpenses, id: \.id) { $expense in
										expenseRow(for: $expense)
									}
								}
							}
						}
					}
				}
				.toolbar {
					ToolbarItem(placement: .navigationBarLeading) {
							Button {
								showingSettings = true
							} label: {
								Image(systemName: "gearshape")
							}
					}
					ToolbarItem(placement: .principal) {
						if budgetPeriod == "Weekly" {
							Menu {
								ForEach(recentWeeks(), id: \.self) { weekStart in
									Button {
										selectedWeekStart = weekStart
									} label: {
										Text("Week of \(weekStart.formatted(.dateTime.month().day()))")
									}
								}
							} label: {
								HStack {
									Text("Week of \(selectedWeekStart.formatted(.dateTime.month().day()))")
										.font(.headline)
									Image(systemName: "chevron.down")
										.font(.caption)
								}
							}
						} else {
							Menu {
								ForEach(monthsWithExpenses, id: \.self) { month in
									Button {
										selectedMonth = month
									} label: {
										Text(displayMonth(month))
									}
								}
							} label: {
								HStack {
									Text(displayMonth(selectedMonth))
										.font(.headline)
									Image(systemName: "chevron.down")
										.font(.caption)
								}
							}
						}
					}
					ToolbarItem(placement: .navigationBarTrailing) {
						Button {
							showingAddExpense = true
						} label: {
							Image(systemName: "plus")
						}
					}
				}
				.sheet(isPresented: $showingAddExpense) {
					NavigationStack {
						AddExpenseView { newExpense in
							store.add(newExpense)
						}
					}
				}
				.navigationDestination(isPresented: $showingSettings) {
					VStack {
						SettingsView()
					}
				}
			.navigationBarTitleDisplayMode(.inline)
		}
		.environmentObject(store)
		.onAppear {
			updateSelectedWeekStart()
			Task {
				do {
					var foundEntitlement = false
					for await result in Transaction.currentEntitlements {
						if case .verified(let transaction) = result {
							if transaction.productID == "com.chan.monir.pro.lifetime" {
								store.productID = transaction.productID
								foundEntitlement = true
								break
							}
						}
					}
					if !foundEntitlement {
						store.productID = "free"
					}
				} catch {
					// Failed to check entitlements
					store.productID = "free"
				}
			}
		}
		.onChange(of: settings.weeklyStartDay) { _ in
			updateSelectedWeekStart()
		}
		.onChange(of: settings.monthlyStartDay) { _ in
			selectedMonth = currentMonthIdentifier()
		}
		.preferredColorScheme(preferredScheme)
		.alert("Error", isPresented: Binding(
			get: { store.errorMessage != nil },
			set: { if !$0 { store.errorMessage = nil } }
		)) {
			Button("OK") {
				store.errorMessage = nil
			}
		} message: {
			if let errorMessage = store.errorMessage {
				Text(errorMessage)
			}
		}
	}
	
	private func displayMonth(_ month: String) -> String {
		let inputFormatter = DateFormatter()
		inputFormatter.dateFormat = "yyyy-MM"
		let outputFormatter = DateFormatter()
		outputFormatter.dateFormat = "MMMM yyyy"
		if let date = inputFormatter.date(from: month) {
			return outputFormatter.string(from: date)
		}
		return month
	}
}


extension Array where Element: Equatable {
	func uniqued() -> [Element] {
		var result = [Element]()
		for value in self {
			if !result.contains(value) {
				result.append(value)
			}
		}
		return result
	}
}

extension ContentView {
	private func recentWeeks() -> [Date] {
		let calendar = Calendar.current
		let startDay = weeklyStartDay
		
		let allWeekStarts = store.expenses.map { expense -> Date in
			let weekday = calendar.component(.weekday, from: expense.date)
			let delta = (weekday - startDay + 7) % 7
			return calendar.startOfDay(for: calendar.date(byAdding: .day, value: -delta, to: expense.date)!)
		}
		
		let uniqueWeekStarts = Set(allWeekStarts)
		return uniqueWeekStarts.sorted(by: >)
	}

	private func updateSelectedWeekStart() {
		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		let delta = (calendar.component(.weekday, from: today) - settings.weeklyStartDay + 7) % 7
		if let adjusted = calendar.date(byAdding: .day, value: -delta, to: today) {
			selectedWeekStart = calendar.startOfDay(for: adjusted)
		}
	}

	private func currentMonthIdentifier() -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM"
		return formatter.string(from: Date())
	}

	private var preferredScheme: ColorScheme? {
		switch appearanceMode {
		case "Dark":
			return .dark
		case "Light":
			return .light
		default:
			return nil
		}
	}
}
