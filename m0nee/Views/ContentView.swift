import SwiftUI
import Charts
import StoreKit

func indexForDrag(location: CGPoint, in list: [InsightCardType], current: Int) -> Int? {
    let cardHeight: CGFloat = 248  // 240 height + 8 vertical padding
    let relativeY = location.y
    let toIndex = Int(relativeY / cardHeight)
    if toIndex >= 0 && toIndex < list.count {
        return toIndex
    }
    return nil
}

struct ContentView: View {
    @EnvironmentObject private var store: ExpenseStore
    @EnvironmentObject private var settings: AppSettings

    @State private var pressedExpenseID: UUID?
    @State private var showingAddExpense = false
    @State private var showingSettings = false
    @State private var showingInsights = false
    @State private var selectedExpenseID: UUID?

    @StateObject private var viewModel: ContentViewModel

    init(viewModel: ContentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var currencyFormatter: NumberFormatter { viewModel.currencyFormatter() }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        if !viewModel.useFixedInsightCards {
                            insightCardsView
                        }

                        let expenseBindings = filteredExpenseBindings

                        if expenseBindings.isEmpty {
                            emptyStateView
                        } else if viewModel.shouldGroupByDay {
                            groupedExpenseSections
                        } else {
                            ForEach(Array(expenseBindings.enumerated()), id: \.element.wrappedValue.id) { _, binding in
                                expenseRow(for: binding)
                            }
                        }
                    }
                    .padding(.top, viewModel.useFixedInsightCards ? 290 : 0)
                }

                if viewModel.useFixedInsightCards {
                    insightCardsView
                        .padding(.top, 16)
                        .offset(y: -24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        Button { showingSettings = true } label: {
                            Image(systemName: "gearshape")
                        }

                        Button { showingInsights = true } label: {
                            Image(systemName: "chart.bar")
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    if viewModel.budgetPeriod == "Weekly" {
                        Menu {
                            ForEach(viewModel.recentWeeks, id: \.self) { weekStart in
                                Button {
                                    viewModel.selectedWeekStart = weekStart
                                } label: {
                                    Text("Week of \(weekStart.formatted(.dateTime.month().day()))")
                                }
                            }
                        } label: {
                            HStack {
                                Text("Week of \(viewModel.selectedWeekStart.formatted(.dateTime.month().day()))")
                                    .font(.headline)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                        }
                    } else {
                        Menu {
                            ForEach(viewModel.monthsWithExpenses, id: \.self) { month in
                                Button {
                                    viewModel.selectedMonth = month
                                } label: {
                                    Text(viewModel.displayMonth(month))
                                }
                            }
                        } label: {
                            HStack {
                                Text(viewModel.displayMonth(viewModel.selectedMonth))
                                    .font(.headline)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddExpense = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                NavigationStack {
                    AddExpenseView { newExpense in
                        store.add(newExpense)
                    }
                    .environmentObject(store)
                    .environmentObject(settings)
                }
            }
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(store)
                    .environmentObject(settings)
            }
            .navigationDestination(isPresented: $showingInsights) {
                InsightsView(viewModel: InsightsViewModel(store: store, settings: settings))
                    .environmentObject(store)
                    .environmentObject(settings)
            }
            .onAppear {
                viewModel.onAppear()

                Task {
                    do {
                        var foundEntitlement = false
                        for await result in Transaction.currentEntitlements {
                            if case .verified(let transaction) = result,
                               transaction.productID == "com.chan.monir.pro.lifetime" {
                                store.productID = transaction.productID
                                foundEntitlement = true
                                break
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
        }
        .preferredColorScheme(viewModel.preferredColorScheme)
    }

    private var emptyStateView: some View {
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
    }

    private var groupedExpenseSections: some View {
        let groups = groupedExpenseBindings
        return ForEach(groups, id: \.date) { section in
            Section(
                header: HStack {
                    Text(DateFormatter.m0neeListSection.string(from: section.date))
                        .font(.caption)
                        .foregroundColor(Color.blue.opacity(0.7))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 15)
                .padding(.bottom, 8)
            ) {
                ForEach(Array(section.bindings.enumerated()), id: \.element.wrappedValue.id) { _, binding in
                    expenseRow(for: binding)
                }
            }
        }
    }

    private var insightCardsView: some View {
        VStack {
            TabView {
                if viewModel.favouriteCards.isEmpty {
                    VStack {
                        VStack(spacing: 12) {
                            Text("No Insight Cards Added")
                                .font(.headline)
                            Text("Go to the Insights tab and long-press on cards to add them here.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .frame(height: 240)
                        Spacer()
                    }
                } else {
                    let expenses = filteredExpenseBindings.map(\.wrappedValue)
                    ForEach(viewModel.favouriteCards, id: \.self) { type in
                        VStack {
                            InsightCardView(
                                type: type,
                                expenses: expenses,
                                startDate: viewModel.budgetDates.start,
                                endDate: viewModel.budgetDates.end,
                                categories: store.categories,
                                isProUser: store.isProUser
                            )
                            .padding(.horizontal, 16)
                            Spacer()
                        }
                    }
                }
            }
            .id(viewModel.cardRefreshTokens)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .frame(height: 270)
            .background(Color(.systemBackground))
        }
        .frame(height: 300)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func expenseRow(for expense: Binding<Expense>) -> some View {
        switch viewModel.displayMode {
        case "Compact":
            compactRow(for: expense)
        case "Detailed":
            detailedRow(for: expense)
        default:
            standardRow(for: expense)
        }
    }

    private func compactRow(for expense: Binding<Expense>) -> some View {
        Button {
            pressedExpenseID = expense.wrappedValue.id
            DispatchQueue.main.async {
                selectedExpenseID = expense.wrappedValue.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pressedExpenseID = nil
            }
        } label: {
            VStack(spacing: 0) {
                rowContent(for: expense, iconSize: 24, showCategorySubtitle: false)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(pressedExpenseID == expense.wrappedValue.id ? Color.gray.opacity(0.3) : Color(.systemBackground))
                Divider()
            }
        }
        .buttonStyle(.plain)
        .background(NavigationLink(destination: ExpenseDetailView(expenseID: expense.wrappedValue.id, store: store), tag: expense.wrappedValue.id, selection: $selectedExpenseID) { EmptyView() }.hidden())
    }

    private func standardRow(for expense: Binding<Expense>) -> some View {
        Button {
            pressedExpenseID = expense.wrappedValue.id
            DispatchQueue.main.async {
                selectedExpenseID = expense.wrappedValue.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pressedExpenseID = nil
            }
        } label: {
            ZStack {
                rowContent(for: expense, iconSize: 32, showCategorySubtitle: true)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(pressedExpenseID == expense.wrappedValue.id ? Color.gray.opacity(0.3) : Color(.systemBackground))
            }
        }
        .buttonStyle(.plain)
        .background(NavigationLink(destination: ExpenseDetailView(expenseID: expense.wrappedValue.id, store: store), tag: expense.wrappedValue.id, selection: $selectedExpenseID) { EmptyView() }.hidden())
    }

    private func detailedRow(for expense: Binding<Expense>) -> some View {
        Button {
            pressedExpenseID = expense.wrappedValue.id
            DispatchQueue.main.async {
                selectedExpenseID = expense.wrappedValue.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pressedExpenseID = nil
            }
        } label: {
            VStack(spacing: 0) {
                detailedRowContent(for: expense)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(pressedExpenseID == expense.wrappedValue.id ? Color.gray.opacity(0.1) : Color(.systemGray5).opacity(0.01))
                Divider()
            }
        }
        .buttonStyle(.plain)
        .background(NavigationLink(destination: ExpenseDetailView(expenseID: expense.wrappedValue.id, store: store), tag: expense.wrappedValue.id, selection: $selectedExpenseID) { EmptyView() }.hidden())
    }

    private func rowContent(for expense: Binding<Expense>, iconSize: CGFloat, showCategorySubtitle: Bool) -> some View {
        HStack(spacing: 12) {
            if let categoryItem = store.categories.first(where: { $0.name == expense.wrappedValue.category }) {
                ZStack {
                    Circle()
                        .fill(categoryItem.color.color)
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: categoryItem.symbol)
                        .font(.system(size: iconSize / 2, weight: .medium))
                        .foregroundColor(.white)
                }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: "questionmark")
                        .font(.system(size: iconSize / 2))
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
                }
                .font(.body.weight(.semibold))
                .foregroundColor(.primary)

                if showCategorySubtitle {
                    Text(expense.wrappedValue.category)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(currencyFormatter.string(from: NSNumber(value: expense.wrappedValue.amount)) ?? "")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)

                if showCategorySubtitle {
                    Text(expense.wrappedValue.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private func detailedRowContent(for expense: Binding<Expense>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                rowContent(for: expense, iconSize: 40, showCategorySubtitle: true)
            }

            if let memo = expense.wrappedValue.memo, !memo.isEmpty {
                Text(memo)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
            }

            if viewModel.showRating, let rating = expense.wrappedValue.rating {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var filteredExpenseBindings: [Binding<Expense>] {
        viewModel.filteredExpenseIDs.compactMap { store.binding(for: $0) }
    }

    private var groupedExpenseBindings: [(date: Date, bindings: [Binding<Expense>])] {
        viewModel.groupedExpenseIDs.map { tuple in
            let bindings = tuple.ids.compactMap { store.binding(for: $0) }
            return (date: tuple.date, bindings: bindings)
        }
        .filter { !$0.bindings.isEmpty }
    }
}
