import SwiftUI
import StoreKit
import Charts

struct ContentView: View {
	@EnvironmentObject var store: ExpenseStore
	@EnvironmentObject var settings: AppSettings
	@Environment(\.colorScheme) private var colorScheme
	@State private var showingAddExpense = false
	@State private var showingSettings = false
	@State private var selectedMonth: String
	@State private var currentCardIndex: Int? = 0
	@State private var showingCardSettings = false

	private var currencyCode: String { settings.currencyCode }
	private var hasSeenTutorial: Bool { settings.hasSeenTutorial }
	private var displayMode: String { settings.displayMode }
	private var budgetPeriod: String { settings.budgetPeriod }
	private var appearanceMode: String { settings.appearanceMode }
	private var groupByDay: Bool { settings.groupByDay }
	private var showRating: Bool { settings.showRating }
	private var decimalDisplayMode: DecimalDisplayMode { settings.decimalDisplayMode }
	private var monthlyStartDay: Int { settings.monthlyStartDay }

	// MARK: - Date & Filter Logic

	private var budgetDates: (startDate: Date, endDate: Date) {
		let calendar = Calendar.current
		let startDay = monthlyStartDay
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

	private var filteredExpenses: [Binding<Expense>] {
		if !selectedMonth.isEmpty {
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
		_selectedMonth = State(initialValue: formatter.string(from: Date()))
	}

	// MARK: - Body

	var body: some View {
		if hasSeenTutorial {
			mainBody
		} else {
			TutorialView()
		}
	}

	// MARK: - Main Layout

	private var mainBody: some View {
		NavigationStack {
			ZStack {
				Color(.systemGroupedBackground)
					.ignoresSafeArea()

				ScrollView {
					VStack(spacing: 16) {
						statsCardsSection

						expenseListContent
					}
					.padding(.horizontal, 16)
					.padding(.top, 16)
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button {
						showingSettings = true
					} label: {
						Image(systemName: "gearshape")
					}
				}
				ToolbarItem(placement: .principal) {
					periodPill
				}
				ToolbarItemGroup(placement: .bottomBar) {
					Button { } label: {
						Image(systemName: "magnifyingglass")
					}
					Spacer()
					Button {
						showingAddExpense = true
					} label: {
						Image(systemName: "plus")
					}
				}
			}
			.navigationDestination(for: UUID.self) { id in
				ExpenseDetailView(expenseID: id, store: store)
			}
			.navigationDestination(isPresented: $showingSettings) {
				SettingsView()
			}
			.navigationDestination(isPresented: $showingCardSettings) {
				StatsCardSettingsView()
			}
		}
		.sheet(isPresented: $showingAddExpense) {
			NavigationStack {
				AddExpenseView { newExpense in
					store.add(newExpense)
				}
			}
		}
		.environmentObject(store)
		.onAppear {
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
					store.productID = "free"
				}
			}
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

	// MARK: - Period Pill Selector

	private var periodPill: some View {
		Menu {
			ForEach(monthsWithExpenses, id: \.self) { month in
				Button {
					selectedMonth = month
				} label: {
					Text(displayMonth(month))
				}
			}
		} label: {
			HStack(spacing: 4) {
				Text(displayMonth(selectedMonth))
				Image(systemName: "chevron.down")
					.font(.system(size: 12, weight: .medium))
			}
			.font(.system(size: 17, weight: .semibold))
		}
	}

	// MARK: - Stats Cards Section

	private var enabledCards: [StatsCardType] {
		settings.enabledStatsCards
	}

	private var totalCardCount: Int {
		enabledCards.count + 1
	}

	private var statsCardsSection: some View {
		VStack(spacing: 8) {
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 0) {
					ForEach(Array(enabledCards.enumerated()), id: \.element) { index, card in
						statsCard(for: card)
							.containerRelativeFrame(.horizontal)
							.id(index)
					}
					addStatsCard
						.containerRelativeFrame(.horizontal)
						.id(enabledCards.count)
				}
				.scrollTargetLayout()
			}
			.scrollTargetBehavior(.paging)
			.scrollPosition(id: $currentCardIndex)
			.frame(height: 165)
			.onChange(of: enabledCards) { _ in
				if let idx = currentCardIndex, idx >= totalCardCount {
					currentCardIndex = max(totalCardCount - 1, 0)
				}
			}

			if totalCardCount > 1 {
				progressBar
			}
		}
	}

	private var progressBar: some View {
		HStack(spacing: 0) {
			ForEach(0..<totalCardCount, id: \.self) { index in
				Rectangle()
					.fill((currentCardIndex ?? 0) == index ? Color.primary.opacity(0.6) : Color.secondary.opacity(0.2))
					.frame(height: 3)
			}
		}
		.frame(width: CGFloat(totalCardCount) * 20)
	}

	private var addStatsCard: some View {
		Button {
			showingCardSettings = true
		} label: {
			VStack(spacing: 12) {
				Image(systemName: "plus.circle")
					.font(.system(size: 32))
					.foregroundColor(.secondary)
				Text("Edit Cards")
					.font(.system(size: 13, weight: .medium))
					.foregroundColor(.secondary)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
			.padding(.horizontal, 6)
		}
		.buttonStyle(.plain)
	}

	@ViewBuilder
	private func statsCard(for type: StatsCardType) -> some View {
		Group {
			switch type {
			case .monthlyTotal:
				monthlyTotalCard
			case .budgetProgress:
				budgetCard
			case .dailyTrend:
				spendingTrendCard
			}
		}
		.padding(16)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
		.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
		.padding(.horizontal, 6)
	}

	private var monthlyTotalCard: some View {
		let total = filteredExpenses.reduce(0.0) { $0 + $1.wrappedValue.amount }
		let count = filteredExpenses.count

		return VStack(alignment: .leading, spacing: 0) {
			HStack {
				Text("Total Spending")
					.font(.system(size: 13, weight: .medium))
					.foregroundColor(.secondary)
				Spacer()
				Text("\(count) items")
					.font(.system(size: 12))
					.foregroundColor(.secondary.opacity(0.5))
			}

			Spacer()

			Text(NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: total)) ?? "")
				.font(.system(size: 34, weight: .bold))
				.foregroundColor(.primary)
				.minimumScaleFactor(0.4)
				.lineLimit(1)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	private var budgetCard: some View {
		let spent = filteredExpenses
			.filter { !$0.wrappedValue.excludeFromBudget }
			.reduce(0.0) { $0 + $1.wrappedValue.amount }
		let budget = settings.monthlyBudget
		let ratio = budget > 0 ? spent / budget : 0
		let clampedRatio = min(ratio, 1.0)
		let remaining = budget - spent
		let overBudget = remaining < 0
		let barColor: Color = overBudget ? .red : .blue
		let formatter = NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode)

		return VStack(alignment: .leading, spacing: 0) {
			HStack {
				Text("Budget")
					.font(.system(size: 13, weight: .medium))
					.foregroundColor(.secondary)
				Spacer()
				Text("\(Int(ratio * 100))%")
					.font(.system(size: 13, weight: .semibold))
					.foregroundColor(barColor)
			}

			Spacer()

			HStack(alignment: .firstTextBaseline, spacing: 4) {
				Text(formatter.string(from: NSNumber(value: spent)) ?? "")
					.font(.system(size: 28, weight: .bold))
					.foregroundColor(.primary)
					.minimumScaleFactor(0.4)
					.lineLimit(1)
				Text("/ \(formatter.string(from: NSNumber(value: budget)) ?? "")")
					.font(.system(size: 13))
					.foregroundColor(.secondary)
					.lineLimit(1)
			}

			GeometryReader { geo in
				ZStack(alignment: .leading) {
					RoundedRectangle(cornerRadius: 3)
						.fill(Color.secondary.opacity(0.1))
					RoundedRectangle(cornerRadius: 3)
						.fill(barColor)
						.frame(width: geo.size.width * clampedRatio)
				}
			}
			.frame(height: 5)
			.padding(.top, 10)

			Text(overBudget ? "Over budget" : "\(formatter.string(from: NSNumber(value: remaining)) ?? "") left")
				.font(.system(size: 12))
				.foregroundColor(overBudget ? .red : .secondary.opacity(0.5))
				.padding(.top, 6)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	private var spendingTrendCard: some View {
		let dates = budgetDates
		let sorted = filteredExpenses
			.map { $0.wrappedValue }
			.sorted { $0.date < $1.date }
		let today = min(Calendar.current.startOfDay(for: Date()), dates.endDate)
		let cumulative: [(date: Date, total: Double)] = {
			var points: [(Date, Double)] = []
			var running = 0.0
			let calendar = Calendar.current

			points.append((dates.startDate, 0))

			let grouped = Dictionary(grouping: sorted) { calendar.startOfDay(for: $0.date) }
			for date in grouped.keys.sorted() {
				running += grouped[date]!.reduce(0) { $0 + $1.amount }
				points.append((date, running))
			}

			if let last = points.last, last.0 < today {
				points.append((today, running))
			}

			return points
		}()

		return VStack(alignment: .leading, spacing: 11) {
			HStack {
				Text("Spending Trend")
					.font(.system(size: 13, weight: .medium))
					.foregroundColor(.secondary)
				Spacer()
			}

			Chart {
				ForEach(cumulative, id: \.date) { item in
					AreaMark(
						x: .value("Date", item.date),
						y: .value("Total", item.total)
					)
					.foregroundStyle(
						LinearGradient(
							colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)],
							startPoint: .top,
							endPoint: .bottom
						)
					)
					.interpolationMethod(.linear)

					LineMark(
						x: .value("Date", item.date),
						y: .value("Total", item.total)
					)
					.foregroundStyle(Color.blue)
					.interpolationMethod(.linear)
					.lineStyle(StrokeStyle(lineWidth: 2))
				}

				if let last = cumulative.last, last.total > 0 {
					let totalDuration = dates.endDate.timeIntervalSince(dates.startDate)
					let elapsed = last.date.timeIntervalSince(dates.startDate)
					let progress = totalDuration > 0 ? elapsed / totalDuration : 0
					let labelPosition: AnnotationPosition = progress > 0.8 ? .topLeading : .trailing

					PointMark(
						x: .value("Date", last.date),
						y: .value("Total", last.total)
					)
					.symbol(Circle())
					.symbolSize(20)
					.foregroundStyle(Color.blue)
					.annotation(position: labelPosition, spacing: 4) {
						Text(NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: last.total)) ?? "")
							.font(.system(size: 10, weight: .medium))
							.foregroundColor(.secondary)
							.offset(x: progress > 0.8 ? 2 : 0, y: progress > 0.8 ? 2 : 0)
					}
				}
			}
			.chartXScale(domain: dates.startDate...dates.endDate)
			.chartXAxis(.hidden)
			.chartYAxis(.hidden)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	// MARK: - Expense List

	private var expenseListContent: some View {
		LazyVStack(spacing: 20) {
			if filteredExpenses.isEmpty {
				emptyState
			} else if groupByDay {
				let grouped = Dictionary(
					grouping: filteredExpenses,
					by: { Calendar.current.startOfDay(for: $0.wrappedValue.date) }
				)
				let sortedDates = grouped.keys.sorted(by: >)

				ForEach(sortedDates, id: \.self) { date in
					VStack(spacing: 8) {
						datePillHeader(date)
						expenseCard(grouped[date]!)
					}
				}
			} else {
				expenseCard(filteredExpenses)
			}
		}
	}

	// MARK: - Date Pill Header

	private func datePillHeader(_ date: Date) -> some View {
		HStack {
			Text(DateFormatter.m0neeListSection.string(from: date))
				.font(.system(size: 13, weight: .semibold))
				.foregroundColor(.secondary)
				.padding(.horizontal, 12)
				.padding(.vertical, 4)
				.background(Color.secondary.opacity(0.1))
				.clipShape(Capsule())
			Spacer()
		}
	}

	// MARK: - Expense Card (Rounded Container)

	private func expenseCard(_ expenses: [Binding<Expense>]) -> some View {
		VStack(spacing: 0) {
			ForEach(Array(expenses.enumerated()), id: \.element.wrappedValue.id) { item in
				VStack(spacing: 0) {
					expenseRow(for: item.element)
					if item.offset < expenses.count - 1 {
						Rectangle()
							.fill(Color.secondary.opacity(0.1))
							.frame(height: 0.5)
							.padding(.leading, 70)
					}
				}
			}
		}
		.background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
		.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
	}

	// MARK: - Expense Row

	private func expenseRow(for expense: Binding<Expense>) -> some View {
		NavigationLink(value: expense.wrappedValue.id) {
			HStack(spacing: 14) {
				categoryIcon(for: expense.wrappedValue.category)

				VStack(alignment: .leading, spacing: 3) {
					HStack(spacing: 6) {
						Text(expense.wrappedValue.name)
							.font(.system(size: 17, weight: .medium))
							.foregroundColor(.primary)
							.lineLimit(1)
						if expense.wrappedValue.isRecurring {
							Image(systemName: "arrow.triangle.2.circlepath")
								.font(.system(size: 11))
								.foregroundColor(.blue)
						}
						if expense.wrappedValue.excludeFromBudget {
							Image(systemName: "circle.slash")
								.font(.system(size: 11))
								.foregroundColor(.orange)
						}
					}

					if displayMode != "Compact" {
						HStack(spacing: 0) {
							Text(expense.wrappedValue.category)
								.font(.system(size: 13))
								.foregroundColor(.secondary)
							if displayMode == "Detailed" {
								Text(" · \(expense.wrappedValue.date.formatted(date: .abbreviated, time: .shortened))")
									.font(.system(size: 13))
									.foregroundColor(.secondary)
							}
						}
					}

					if displayMode == "Detailed",
					   let details = expense.wrappedValue.details, !details.isEmpty {
						Text(details)
							.font(.system(size: 13))
							.foregroundColor(.secondary)
							.lineLimit(1)
					}
				}
				.layoutPriority(0.5)

				Spacer()

				VStack(alignment: .trailing, spacing: 3) {
					Text(NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: expense.wrappedValue.amount)) ?? "")
						.font(.system(size: 16, weight: .semibold))
						.foregroundColor(.primary)

					if displayMode == "Detailed", showRating, let rating = expense.wrappedValue.rating {
						HStack(spacing: 1) {
							ForEach(1...5, id: \.self) { star in
								Image(systemName: star <= rating ? "star.fill" : "star")
									.font(.system(size: 9))
									.foregroundColor(star <= rating ? .yellow : Color(.systemGray3))
							}
						}
					}
				}
				.layoutPriority(1)

				Image(systemName: "chevron.right")
					.font(.system(size: 12, weight: .medium))
					.foregroundColor(.secondary)
					.opacity(0.5)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 13)
		}
		.buttonStyle(.plain)
	}

	// MARK: - Category Icon

	private func categoryIcon(for categoryName: String) -> some View {
		let item = store.categories.first(where: { $0.name == categoryName })
		let color = item?.color.color ?? Color.gray
		let symbol = item?.symbol ?? "questionmark"

		return ZStack {
			Circle()
				.fill(color.opacity(0.15))
				.frame(width: 40, height: 40)
			Image(systemName: symbol)
				.font(.system(size: 17))
				.foregroundColor(color)
		}
	}

	// MARK: - Empty State

	private var emptyState: some View {
		VStack(spacing: 24) {
			ZStack {
				Circle()
					.fill(Color.secondary.opacity(0.08))
					.frame(width: 80, height: 80)
				Image(systemName: "wallet.pass")
					.font(.system(size: 36))
					.foregroundColor(.secondary)
			}
			.padding(.top, 60)

			VStack(spacing: 8) {
				Text("No expenses yet")
					.font(.system(size: 18, weight: .semibold))
					.foregroundColor(.primary)
				Text("Tap the + button to record your first expense.")
					.font(.system(size: 15))
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 32)
			}
		}
		.frame(maxWidth: .infinity)
	}

	// MARK: - Helpers

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

// MARK: - Array Extension

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

// MARK: - ContentView Helpers

extension ContentView {
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
