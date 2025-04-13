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

struct ContentView: View {
	@AppStorage("currencySymbol") private var currencySymbol: String = "£"
	@AppStorage("displayMode") private var displayMode: String = "Standard"
	@AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
	@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
	@AppStorage("useFixedInsightCards") private var useFixedInsightCards: Bool = false
	@AppStorage("groupExpensesByDay") private var groupExpensesByDay: Bool = false
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
	
	private var insightCardsView: some View {
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
			.id(cardRefreshTokens)
			.tabViewStyle(.page)
			.indexViewStyle(.page(backgroundDisplayMode: .never))
			.padding(.top, 16)
			.padding(.bottom, 16)
			.frame(height: 272)
			.background(Color(.systemBackground))
	}
	
	var body: some View {
		NavigationStack {
			ZStack(alignment: .top) {
				ScrollView {
					VStack(spacing: 0) {
						if !useFixedInsightCards {
							insightCardsView
						}
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
					.padding(.top, useFixedInsightCards ? 272 : 0)
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
				if useFixedInsightCards {
					insightCardsView
				}
			}
			.navigationBarTitleDisplayMode(.inline)
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
