import SwiftUI
import Charts

func indexForDrag(location: CGPoint, in list: [InsightCardType], current: Int) -> Int? {
	let cardHeight: CGFloat = 248  // 240 height + 8 vertical padding
	let relativeY = location.y
	let toIndex = Int(relativeY / cardHeight)
	if toIndex >= 0 && toIndex < list.count {
		return toIndex
	}
	return nil
}

struct InsightsView: View {
	@AppStorage("favouriteInsightCards") private var favouriteInsightCardsRaw: Data = Data()
	@State private var favourites: [InsightCardType] = []
	@State private var deleteTrigger = UUID()
	@StateObject private var store = ExpenseStore()
	
	private var currentBudgetDates: (startDate: Date, endDate: Date) {
		let calendar = Calendar.current
		let today = Date()
		let period = UserDefaults.standard.string(forKey: "budgetPeriod") ?? "Monthly"
		let startDay = UserDefaults.standard.integer(forKey: period == "Weekly" ? "weeklyStartDay" : "monthlyStartDay")
		
		if period == "Weekly" {
			let weekdayToday = calendar.component(.weekday, from: today)
			let delta = (weekdayToday - startDay + 7) % 7
			let weekStart = calendar.date(byAdding: .day, value: -delta, to: today)!
			let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
			return (calendar.startOfDay(for: weekStart), calendar.startOfDay(for: weekEnd))
		} else {
			let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
			let monthStart = calendar.date(byAdding: .day, value: startDay - 1, to: currentMonth)!
			let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
			let endDate = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
			return (calendar.startOfDay(for: monthStart), calendar.startOfDay(for: endDate))
		}
	}
	
	private var currentExpenses: [Expense] {
		store.expenses.filter {
			let date = Calendar.current.startOfDay(for: $0.date)
			return date >= currentBudgetDates.startDate && date <= currentBudgetDates.endDate
		}
	}
	var body: some View {
		ZStack {
			ScrollView {
				
				LazyVStack(spacing: 16) {
					Section {
						ForEach(InsightCardType.allCases, id: \.rawValue) { type in
							ZStack(alignment: .topLeading) {
								InsightCardView(
									type: type,
									expenses: currentExpenses,
									startDate: currentBudgetDates.startDate,
									endDate: currentBudgetDates.endDate
								)
								.id(type) // ensure stable identity
								.transition(.asymmetric(insertion: .identity, removal: .move(edge: .top)))
								.animation(.interpolatingSpring(stiffness: 300, damping: 20), value: deleteTrigger)
								.contextMenu {
									if isFavourited(type) {
										Button {
											toggleFavourite(type)
										} label: {
											Label("Remove from Favourite", systemImage: "star.slash")
										}
									} else {
										Button {
											toggleFavourite(type)
										} label: {
											Label("Add to Favourite", systemImage: "star")
										}
									}
									Button(role: .cancel) {
										// Cancel logic or nothing
									} label: {
										Label("Cancel", systemImage: "xmark")
									}
								}
								.padding(.horizontal, 20)
								.padding(.vertical, 2)
							}
						}
					}
				}
				.environment(\.editMode, .constant(.active))
				.padding(.vertical)
				.onAppear {
					favourites = loadFavourites()
				}
				.onChange(of: favourites) { _ in
					saveFavourites()
				}
			}
			.navigationTitle("Insights")
			.navigationBarTitleDisplayMode(.inline)
			
		}
	}
	
	func currentMonth() -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM"
		return formatter.string(from: Date())
	}
	
	
	
	private func loadFavourites() -> [InsightCardType] {
		guard let decoded = try? JSONDecoder().decode([InsightCardType].self, from: favouriteInsightCardsRaw) else {
			return []
		}
		return decoded
	}
	
	private func saveFavourites() {
		if let encoded = try? JSONEncoder().encode(favourites) {
			favouriteInsightCardsRaw = encoded
		}
	}
	
	private func toggleFavourite(_ type: InsightCardType) {
		if let index = favourites.firstIndex(of: type) {
			favourites.remove(at: index)
		} else {
			favourites.append(type)
		}
		saveFavourites()
		favourites = loadFavourites()
		NotificationCenter.default.post(name: Notification.Name("favouritesUpdated"), object: nil)
	}
	
	private func isFavourited(_ type: InsightCardType) -> Bool {
		favourites.contains(type)
	}
}

extension NumberFormatter {
	static var currency: NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "£"
		return formatter
	}
}

struct ContentView: View {
	@AppStorage("currencySymbol") private var currencySymbol: String = "£"
	@AppStorage("displayMode") private var displayMode: String = "Standard"
	@AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
	@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
	@ObservedObject var store: ExpenseStore
	@State private var showingAddExpense = false
	@State private var showingSettings = false
	@State private var showingInsights = false
	@State private var selectedMonth: String
	@State private var selectedWeekStart: Date = Calendar.current.startOfDay(for: Date())
	@AppStorage("budgetByCategory") private var budgetByCategory: Bool = false
	@AppStorage("categoryBudgets") private var categoryBudgets: String = ""
	@AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
	@AppStorage("weeklyStartDay") private var weeklyStartDay: Int = 1
	@AppStorage("monthlyStartDay") private var monthlyStartDay: Int = 1
	@State private var favouriteCards: [InsightCardType] = []
	@State private var cardRefreshTokens: [InsightCardType: UUID] = [:]
	
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
	
	
	init(store: ExpenseStore) {
		self.store = store
		
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM"
		let recentMonth = formatter.string(from: Date())
		_selectedMonth = State(initialValue: recentMonth)
		
		let calendar = Calendar.current
		let today = Date()
		let startDay = UserDefaults.standard.integer(forKey: "weeklyStartDay")
		let weekdayToday = calendar.component(.weekday, from: today)
		let delta = (weekdayToday - startDay + 7) % 7
		let correctedWeekStart = calendar.date(byAdding: .day, value: -delta, to: today) ?? today
		_selectedWeekStart = State(initialValue: calendar.startOfDay(for: correctedWeekStart))
	}
	
	var body: some View {
		NavigationStack {
			
			ScrollView {
				VStack(spacing: 0) {
					TabView {
						ForEach(favouriteCards, id: \.self) { type in
							InsightCardView(
								type: type,
								expenses: filteredExpenses.map(\.wrappedValue),
								startDate: budgetDates.startDate,
								endDate: budgetDates.endDate
							)
							.padding(.horizontal, 16)
						}
					}
					.id(cardRefreshTokens) // apply UUID refresh to entire TabView
					.frame(height: 240)
					.tabViewStyle(.page)
					.indexViewStyle(.page(backgroundDisplayMode: .never))
					.padding(.vertical, 16)
					
					
					LazyVStack(spacing: 0) {
						ForEach(filteredExpenses, id: \.id) { $expense in
							// COMPACT MODE
							if displayMode == "Compact" {
								VStack(spacing: 0) {
									NavigationLink(destination: ExpenseDetailView(expenseID: expense.id, store: store)) {
										HStack(spacing: 8) {
											Text(expense.name)
												.font(.body)
												.foregroundColor(.primary)
												.lineLimit(1)
											
											Spacer()
											
											Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
												.font(.system(size: 17, weight: .medium))
												.foregroundColor(expense.amount > 100 ? .red : .primary)
											
											Image(systemName: "chevron.right")
												.font(.caption)
												.foregroundColor(.gray)
										}
										.padding(.horizontal, 20)
										.padding(.vertical, 10)
									}
									Divider()
								}
							}
							// STANDARD MODE
							else if displayMode == "Standard" {
								NavigationLink(destination: ExpenseDetailView(expenseID: expense.id, store: store)) {
									VStack(spacing: 8) {
										HStack(alignment: .center, spacing: 12) {
											VStack(alignment: .leading, spacing: 2) {
												Text(expense.name)
													.font(.system(.body, design: .default))
													.fontWeight(.semibold)
													.foregroundColor(.primary)
												
												Text(expense.category)
													.font(.footnote)
													.foregroundColor(.secondary)
											}
											
											Spacer()
											
											VStack(alignment: .trailing, spacing: 2) {
												Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
													.font(.system(size: 17, weight: .medium))
													.foregroundColor(expense.amount > 100 ? .red : .primary)
												
												Text(expense.date.formatted(date: .abbreviated, time: .shortened))
													.font(.caption2)
													.foregroundColor(.gray)
											}
											Image(systemName: "chevron.right")
												.font(.caption)
												.foregroundColor(.gray)
										}
										Divider()
									}
									.padding(.horizontal)
									.padding(.vertical, 8)
									.background(Color(.systemBackground))
								}
								.swipeActions {
									Button(role: .destructive) {
										store.delete(expense)
									} label: {
										Label("Delete", systemImage: "trash")
									}
								}
							}
							// DETAILED MODE
							else if displayMode == "Detailed" {
								NavigationLink(destination: ExpenseDetailView(expenseID: expense.id, store: store)) {
									HStack(alignment: .top) {
										VStack(alignment: .leading, spacing: 8) {
											// Top row: Name and Amount
											HStack {
												Text(expense.name)
													.font(.headline)
													.fontWeight(.semibold)
													.foregroundColor(Color.primary)
												Spacer()
												Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
													.font(.system(size: 17, weight: .medium))
													.foregroundColor(expense.amount > 100 ? .red : .primary)
											}
											
											// Middle row: Detail and Rating
											HStack(alignment: .center) {
												if let details = expense.details, !details.isEmpty {
													Text(details)
														.font(.subheadline)
														.foregroundColor(.secondary)
												} else {
													Text(" ")
														.font(.subheadline)
												}
												
												Spacer()
												
												if let rating = expense.rating {
													HStack(spacing: 2) {
														ForEach(1...5, id: \.self) { star in
															Image(systemName: star <= rating ? "star.fill" : "star")
																.font(.caption2)
																.foregroundColor(.yellow)
														}
													}
												}
											}
											
											// Bottom row: Category and Date
											HStack {
												Text(expense.category)
													.font(.subheadline)
													.foregroundColor(.secondary)
												Spacer()
												Text(expense.date.formatted(date: .abbreviated, time: .shortened))
													.font(.subheadline)
													.foregroundColor(.secondary)
											}
											
											Divider()
										}
										.padding(.trailing, 12)
										Spacer(minLength: 0)
									}
									.padding()
									.background(Color(.systemBackground))
								}
								.overlay(
									HStack {
										Spacer()
										Image(systemName: "chevron.right")
											.foregroundColor(.gray)
											.padding(.trailing, 8)
									}
								)
								.swipeActions {
									Button(role: .destructive) {
										store.delete(expense)
									} label: {
										Label("Delete", systemImage: "trash")
									}
								}
							}
						}
					}
				}
				.padding(.top, -43)
			}
			.toolbar {
				ToolbarItemGroup(placement: .navigationBarLeading) {
					HStack(spacing: 12) {
						Button {
							showingSettings = true
						} label: {
							Image(systemName: "gearshape")
						}
						
						Button {
							showingInsights = true
						} label: {
							Image(systemName: "chart.bar")
						}
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
				SettingsView(store: store)
			}
			.navigationDestination(isPresented: $showingInsights) {
				InsightsView()
			}
			.onChange(of: weeklyStartDay) { _ in
				let calendar = Calendar.current
				let today = Date()
				let weekdayToday = calendar.component(.weekday, from: today)
				let delta = (weekdayToday - weeklyStartDay + 7) % 7
				if let correctedWeekStart = calendar.date(byAdding: .day, value: -delta, to: today) {
					selectedWeekStart = calendar.startOfDay(for: correctedWeekStart)
				}
			}
			.onChange(of: monthlyStartDay) { _ in
				selectedMonth = selectedMonth + ""
			}
		}
		.onAppear {
			if let data = UserDefaults.standard.data(forKey: "favouriteInsightCards"),
				 let decoded = try? JSONDecoder().decode([InsightCardType].self, from: data) {
				favouriteCards = decoded
			} else {
				favouriteCards = []
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: Notification.Name("favouritesUpdated")), perform: { _ in
			if let data = UserDefaults.standard.data(forKey: "favouriteInsightCards"),
				 let decoded = try? JSONDecoder().decode([InsightCardType].self, from: data) {
				favouriteCards = decoded
			} else {
				favouriteCards = []
			}
		})
		.onReceive(NotificationCenter.default.publisher(for: Notification.Name("expensesUpdated")), perform: { _ in
			if let data = UserDefaults.standard.data(forKey: "favouriteInsightCards"),
				 let decoded = try? JSONDecoder().decode([InsightCardType].self, from: data) {
				favouriteCards = decoded
				for type in decoded {
					cardRefreshTokens[type] = UUID()
				}
			} else {
				favouriteCards = []
			}
		})
		.onReceive(NotificationCenter.default.publisher(for: Notification.Name("categoriesUpdated")), perform: { _ in
			if let data = UserDefaults.standard.data(forKey: "favouriteInsightCards"),
				 let decoded = try? JSONDecoder().decode([InsightCardType].self, from: data) {
				favouriteCards = decoded
				for type in decoded {
					cardRefreshTokens[type] = UUID()
				}
			} else {
				favouriteCards = []
			}
		})
		.preferredColorScheme(
			appearanceMode == "Dark" ? .dark :
				appearanceMode == "Light" ? .light : nil
		)
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

struct ExpenseDetailView: View {
	@AppStorage("currencySymbol") private var currencySymbol: String = "£"
	@Environment(\.dismiss) private var dismiss
	let expenseID: UUID
	@ObservedObject var store: ExpenseStore
	@State private var isEditing = false
	
	private var expense: Expense? {
		store.expenses.first(where: { $0.id == expenseID })
	}
	
	var body: some View {
		if let expense = expense {
			List {
				Section(header: EmptyView()) {
					HStack {
						Label("Date", systemImage: "calendar")
						Spacer()
						Text(expense.date.formatted(date: .abbreviated, time: .shortened))
							.foregroundColor(.secondary)
					}
					
					HStack {
						Label("Amount", systemImage: "dollarsign.circle")
						Spacer()
						Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
							.foregroundColor(.green)
					}
					
					HStack {
						Label("Category", systemImage: "tag")
						Spacer()
						Text(expense.category)
							.foregroundColor(.purple)
					}
					
					if let rating = expense.rating {
						HStack {
							Label("Rating", systemImage: "star.fill")
							Spacer()
							HStack(spacing: 4) {
								ForEach(1...5, id: \.self) { index in
									Image(systemName: index <= rating ? "star.fill" : "star")
										.foregroundColor(.yellow)
								}
							}
						}
					}
				}
				
				if let details = expense.details, !details.isEmpty {
					Section {
						VStack(alignment: .leading, spacing: 15) {
							Label("Details", systemImage: "text.alignleft")
							Text(details)
								.font(.body)
								.foregroundColor(.secondary)
						}
						.padding(.vertical, 4)
					}
				}
				
				if let memo = expense.memo, !memo.isEmpty {
					Section {
						VStack(alignment: .leading, spacing: 15) {
							Label("Note", systemImage: "note.text")
							Text(memo)
								.font(.body)
								.foregroundColor(.secondary)
						}
						.padding(.vertical, 4)
					}
				}
			}
			.listStyle(.insetGrouped)
			.listSectionSpacing(24)
			.padding(.top, -20)
			.navigationTitle(expense.name)
			.navigationBarTitleDisplayMode(.inline)
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
								// Pop back
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
	@AppStorage("currencySymbol") private var currencySymbol: String = "£"
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
		self.onSave = onSave
	}
	
	private var formattedAmount: String {
		let digits = rawAmount.filter { $0.isWholeNumber }
		let doubleValue = (Double(digits) ?? 0) / 100
		return String(format: "\(currencySymbol)%.2f", doubleValue)
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			VStack {
				Spacer().frame(height: 24)
				
				Text(formattedAmount)
					.font(.system(size: 50, weight: .bold))
					.foregroundColor(.primary)
					.frame(maxWidth: .infinity, alignment: .center)
					.padding(.vertical, 16)
					.contentShape(Rectangle())
					.background(Color(.systemBackground))
					.onTapGesture {
						isAmountFocused = true
					}
				
				TextField("", text: $rawAmount)
					.keyboardType(.numberPad)
					.focused($isAmountFocused)
					.opacity(0.01)
					.frame(height: 1)
					.disabled(false)
			}
			
			HStack {
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
			}
			.padding(.bottom, 8)
			
			Form {
				Section(header: Text("Required")) {
					TextField("Name", text: $name)
						.overlay(
							RoundedRectangle(cornerRadius: 4)
								.stroke(showFieldValidation && name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.red : Color.clear, lineWidth: 1)
						)
					DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
					Picker("Category", selection: $category) {
						ForEach(categoryList, id: \.self) { Text($0) }
					}
					.pickerStyle(.menu)
				}
				
				Section(header: Text("Optional")) {
					TextField("Details", text: $details)
					TextField("Note", text: $memo)
				}
				
			}
			if let id = expenseID {
				VStack {
					Button(role: .destructive) {
						onSave(Expense(
							id: id,
							date: date,
							name: name,
							amount: -1, // sentinel to mark deletion
							category: category,
							details: details,
							rating: rating,
							memo: memo
						))
						dismiss()
					} label: {
						Text("Delete Expense")
							.foregroundColor(.red)
							.frame(maxWidth: .infinity)
					}
					.padding()
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
						rating: rating,
						memo: memo.isEmpty ? nil : memo
					)
					onSave(newExpense)
					dismiss()
				}
			}
		}
		
	}
}

struct ManageCategoriesView: View {
	@ObservedObject var store: ExpenseStore
	@AppStorage("categoryBudgets") private var categoryBudgets: String = ""
	@AppStorage("categories") private var categories: String = "Food,Transport,Other"
	@State private var newCategory = ""
	@State private var showingAddSheet = false
	@State private var categoryToDelete: String? = nil
	@State private var isEditing = false
	
	
	var categoryList: [String] {
		categories.split(separator: ",").map { String($0) }
	}
	
	func saveCategories(_ updated: [String]) {
		categories = updated.joined(separator: ",")
	}
	
	var body: some View {
		NavigationStack {
			List {
				Section {
					ForEach(categoryList, id: \.self) { category in
						HStack {
							Image(systemName: "line.3.horizontal")
								.foregroundColor(.gray)
							Text(category)
							Spacer()
							if isEditing {
								Button(role: .destructive) {
									categoryToDelete = category
								} label: {
									Image(systemName: "trash")
										.foregroundColor(.red)
										.frame(maxWidth: .infinity, alignment: .trailing)
								}
							}
						}
					}
				}
				Section {
					Button("Add New") {
						showingAddSheet = true
					}
					.foregroundColor(.blue)
					.frame(maxWidth: .infinity, alignment: .center)
				}
			}
			.navigationTitle("Manage Categories")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(isEditing ? "Done" : "Edit") {
						isEditing.toggle()
					}
				}
			}
			.sheet(isPresented: $showingAddSheet) {
				NavigationStack {
					Form {
						Section {
							TextField("Category Name", text: $newCategory)
						}
					}
					.navigationTitle("New Category")
					.navigationBarTitleDisplayMode(.inline)
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							Button("Cancel") {
								newCategory = ""
								showingAddSheet = false
							}
						}
						ToolbarItem(placement: .navigationBarTrailing) {
							Button("Add") {
								let trimmed = newCategory.trimmingCharacters(in: .whitespaces)
								guard !trimmed.isEmpty, !categoryList.contains(trimmed) else { return }
								var updated = categoryList
								updated.append(trimmed)
								saveCategories(updated)
								NotificationCenter.default.post(name: Notification.Name("categoriesUpdated"), object: nil)
								newCategory = ""
								showingAddSheet = false
							}
						}
					}
				}
			}
		}
		.alert("Delete \"\(categoryToDelete ?? "")\"?", isPresented: Binding<Bool>(
			get: { categoryToDelete != nil },
			set: { if !$0 { categoryToDelete = nil } }
		)) {
			Button("Delete", role: .destructive) {
				if let category = categoryToDelete {
					let updated = categoryList.filter { $0 != category }
					saveCategories(updated)
					
					// Remove from categoryBudgets
					let updatedBudgetDict = categoryBudgets
						.split(separator: ",")
						.compactMap { pair -> (String, String)? in
							let parts = pair.split(separator: ":")
							guard parts.count == 2 else { return nil }
							return (String(parts[0]), String(parts[1]))
						}
						.filter { $0.0 != category }
					categoryBudgets = updatedBudgetDict.map { "\($0):\($1)" }.joined(separator: ",")
					
					// Remove matching expenses using store.delete() so it's properly saved
					let toDelete = store.expenses.filter { $0.category == category }
					toDelete.forEach { store.delete($0) }
				}
				categoryToDelete = nil
			}
			Button("Cancel", role: .cancel) {
				categoryToDelete = nil
			}
		} message: {
			let count = categoryToDelete.map { category in
				store.expenses.filter { $0.category == category }.count
			} ?? 0
			if count > 0 {
				Text("This will also delete \(count) expense(s) under this category.")
			} else {
				Text("Are you sure you want to delete this category?")
			}
		}
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
}
