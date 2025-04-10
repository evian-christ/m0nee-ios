import SwiftUI
import Charts
 
enum InsightCardType: String, Identifiable, Codable {
    case totalSpending
    case spendingTrend
    case categoryRating
    case budgetProgress
    case categoryBudgetProgress
 
    static var allCases: [InsightCardType] {
        return [.totalSpending, .spendingTrend, .categoryRating, .budgetProgress, .categoryBudgetProgress]
    }

    var id: String { self.rawValue }
 
    var title: String {
        switch self {
        case .totalSpending:
            let period = UserDefaults.standard.string(forKey: "budgetPeriod") ?? "Monthly"
            return period == "Weekly" ? "This Week's Total Spending" : "This Month's Total Spending"
        case .spendingTrend:
            return "Spending Trend"
        case .categoryRating:
            return "Category Satisfaction"
        case .budgetProgress:
            let period = UserDefaults.standard.string(forKey: "budgetPeriod") ?? "Monthly"
            return period == "Weekly" ? "Week's Progress" : "Month's Progress"
        case .categoryBudgetProgress:
            return "Category Budget Progress"
        }
    }
 
    var icon: String {
        switch self {
        case .totalSpending:
            return "creditcard"
        case .spendingTrend:
            return "chart.line.uptrend.xyaxis"
        case .categoryRating:
            return "star.lefthalf.fill"
        case .budgetProgress:
            return "gauge.with.needle"
        case .categoryBudgetProgress:
            return "chart.pie"
        }
    }
}

struct CategoryBudgetProgressCardView: View {
    let expenses: [Expense]
    let startDate: Date
    let endDate: Date
    let categoryBudgets: [String: Double]

    var body: some View {
        let calendar = Calendar.current
        let today = Date()
        let cappedToday = min(max(today, startDate), endDate)

        let daysElapsed = calendar.dateComponents([.day], from: startDate, to: cappedToday).day ?? 0
        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let timeProgress = Double(daysElapsed + 1) / Double(totalDays + 1)

        let grouped = Dictionary(grouping: expenses) { $0.category }
        let spendingPerCategory = grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }

        return ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                let allCategories = Set(categoryBudgets.keys)
                ForEach(Array(allCategories).sorted(), id: \.self) { category in
                    let budget = categoryBudgets[category] ?? 0
                    let spent = spendingPerCategory[category] ?? 0
                    let progress = budget > 0 ? spent / budget : (spent > 0 ? 1 : 0)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ProgressView(value: progress)
                            .accentColor(progress > timeProgress ? .red : .blue)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
    }
}

#if DEBUG
struct InsightCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExpenses = [
            Expense(id: UUID(), date: Date(), name: "Groceries", amount: 40, category: "Food", details: nil, rating: 4, memo: nil),
            Expense(id: UUID(), date: Date(), name: "Bus", amount: 15, category: "Transport", details: nil, rating: 3, memo: nil)
        ]
        let now = Date()
        return InsightCardView(
            type: .totalSpending,
            expenses: sampleExpenses,
            startDate: now.addingTimeInterval(-86400 * 7),
            endDate: now
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct SpendingTrendCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExpenses = [
            Expense(id: UUID(), date: Date(), name: "Lunch", amount: 12, category: "Food", details: nil, rating: nil, memo: nil),
            Expense(id: UUID(), date: Date().addingTimeInterval(-86400), name: "Coffee", amount: 4, category: "Food", details: nil, rating: nil, memo: nil)
        ]
        let now = Date()
        return SpendingTrendCardView(
            expenses: sampleExpenses,
            startDate: now.addingTimeInterval(-86400 * 5),
            endDate: now,
            monthlyBudget: 300
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct CategoryRatingCardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExpenses = [
            Expense(id: UUID(), date: Date(), name: "Dinner", amount: 30, category: "Food", details: nil, rating: 5, memo: nil),
            Expense(id: UUID(), date: Date(), name: "Taxi", amount: 20, category: "Transport", details: nil, rating: 2, memo: nil)
        ]
        return CategoryRatingCardView(expenses: sampleExpenses)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif

func indexForDrag(location: CGPoint, in list: [InsightCardType], current: Int) -> Int? {
    let cardHeight: CGFloat = 248  // 240 height + 8 vertical padding
    let relativeY = location.y
    let toIndex = Int(relativeY / cardHeight)
    if toIndex >= 0 && toIndex < list.count {
        return toIndex
    }
    return nil
}

struct CategoryRatingCardView: View {
    var expenses: [Expense]

    var body: some View {
        let grouped = Dictionary(grouping: expenses) { $0.category }
        let averageRatings = grouped.compactMapValues { items -> Double? in
            let ratings = items.compactMap { $0.rating }
            return ratings.isEmpty ? nil : Double(ratings.reduce(0, +)) / Double(ratings.count)
        }

        let sorted = averageRatings.sorted(by: { $0.value > $1.value })

        return Chart {
            ForEach(sorted, id: \.key) { category, avg in
                BarMark(
                    x: .value("Category", category),
                    y: .value("Rating", avg)
                )
                .foregroundStyle(getColor(for: avg))
            }
        }
        .chartYScale(domain: [0, 5])
        .chartYAxis {
            AxisMarks(values: Array(0...5)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartLegend(.hidden)
        .frame(height: 180)
    }

    func getColor(for rating: Double) -> Color {
        switch Int(rating.rounded()) {
        case 5: return Color.green
        case 4: return Color.mint
        case 3: return Color.yellow
        case 2: return Color.orange
        case 1: return Color.red
        default: return Color.gray.opacity(0.4)
        }
    }
}

struct BudgetProgressCardView: View {
    let expenses: [Expense]
    let startDate: Date
    let endDate: Date
    let monthlyBudget: Double

    var body: some View {
        let totalSpent = expenses.reduce(0) { $0 + $1.amount }
        let today = Calendar.current.startOfDay(for: Date())
        let cappedToday = min(max(today, startDate), endDate)
 
        let daysElapsed = Calendar.current.dateComponents([.day], from: startDate, to: cappedToday).day ?? 0
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let timeProgress = Double(daysElapsed + 1) / Double(totalDays + 1)
        let spendingProgress = monthlyBudget > 0 ? totalSpent / monthlyBudget : 0
 
        VStack(alignment: .leading, spacing: 8) {
            Label("Month's Progress", systemImage: "gauge.with.needle")
                .font(.headline)
                .padding(.bottom, 4)
 
            Text(String(format: "£%.2f / £%.2f", totalSpent, monthlyBudget))
                .font(.title3)
                .bold()
                .foregroundColor(spendingProgress > timeProgress ? .red : .primary)
 
            ProgressView(value: spendingProgress)
                .accentColor(spendingProgress > timeProgress ? .red : .blue)
 
            Text(String(format: "Time: %.0f%%", timeProgress * 100))
                .font(.subheadline)
                .foregroundColor(.secondary)
 
            ProgressView(value: timeProgress)
                .accentColor(.gray)
        }
        .padding(.horizontal, 0)
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
    }
}

struct InsightCardView: View {
    var type: InsightCardType
    let expenses: [Expense]
    let startDate: Date
    let endDate: Date
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
    @AppStorage("categoryBudgets") private var categoryBudgets: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if type != .budgetProgress {
                HStack {
                    Label(type.title, systemImage: type.icon)
                        .font(.headline)
                    Spacer()
                }
            }
 
            switch type {
            case .totalSpending:
                Group {
                    let amountSpent = expenses.reduce(0) { $0 + $1.amount }
            
                    VStack(alignment: .leading) {
                        Text(String(format: "£%.2f / £%.2f", amountSpent, monthlyBudget))
                            .font(.title2)
                            .bold()
                        ProgressView(value: amountSpent, total: monthlyBudget)
                            .accentColor(amountSpent > monthlyBudget ? .red : .blue)
                    }
                }
            case .spendingTrend:
                SpendingTrendCardView(
                    expenses: expenses,
                    startDate: startDate,
                    endDate: endDate,
                    monthlyBudget: monthlyBudget
                )
            case .categoryRating:
                CategoryRatingCardView(expenses: expenses)
            case .budgetProgress:
                BudgetProgressCardView(
                    expenses: expenses,
                    startDate: startDate,
                    endDate: endDate,
                    monthlyBudget: monthlyBudget
                )
            case .categoryBudgetProgress:
                let budgetPairs = categoryBudgets
                    .split(separator: ",")
                    .compactMap { pair -> (String, Double)? in
                        let parts = pair.split(separator: ":")
                        guard parts.count == 2, let value = Double(parts[1]) else { return nil }
                        return (String(parts[0]), value)
                    }
                let categoriesString = UserDefaults.standard.string(forKey: "categories") ?? ""
                let categoryList = categoriesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let categoryBudgetDict = Dictionary(uniqueKeysWithValues:
                    categoryList.map { category in
                        let budget = budgetPairs.first(where: { $0.0 == category })?.1 ?? 0
                        return (category, budget)
                    }
                )

                CategoryBudgetProgressCardView(
                    expenses: expenses,
                    startDate: startDate,
                    endDate: endDate,
                    categoryBudgets: categoryBudgetDict
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
        .padding(.vertical, 0)
    }
    
    
}

struct Expense: Identifiable, Codable {
    let id: UUID
    var date: Date
    var name: String
    var amount: Double
    var category: String
    var details: String?
    var rating: Int?
    var memo: String?
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

struct BudgetFrequencyView: View {
    @AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
    let frequencies = ["Weekly", "Monthly"]
    
    var body: some View {
        Form {
        Picker("Select Period", selection: $budgetPeriod) {
                ForEach(frequencies, id: \.self) { frequency in
                    Text(frequency).tag(frequency)
                }
            }
            .pickerStyle(.inline)
        }
        .navigationTitle("Budget Period")
    }
}

class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []

    private var saveURL: URL

    init() {
        let fileManager = FileManager.default
        let localURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("expenses.json")
        let iCloudURL: URL
        let useiCloud = UserDefaults.standard.bool(forKey: "useiCloud")

        if useiCloud, let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            try? fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
            iCloudURL = containerURL.appendingPathComponent("expenses.json")
 
            let localExists = fileManager.fileExists(atPath: localURL.path)
            let iCloudExists = fileManager.fileExists(atPath: iCloudURL.path)
 
            if localExists {
                let localDate = (try? fileManager.attributesOfItem(atPath: localURL.path)[.modificationDate] as? Date) ?? Date.distantPast
                let iCloudDate = (try? fileManager.attributesOfItem(atPath: iCloudURL.path)[.modificationDate] as? Date) ?? Date.distantPast
 
                if !iCloudExists || localDate > iCloudDate {
                    do {
                        try fileManager.copyItem(at: localURL, to: iCloudURL)
                        print("☁️ Copied local data to iCloud")
                    } catch {
                        print("❌ Failed to copy local data to iCloud: \(error)")
                    }
                }
            }
            self.saveURL = iCloudURL
            // Sync storage if iCloud is enabled
            syncStorageIfNeeded()
        } else {
            self.saveURL = localURL
        }

        print("💾 Using saveURL: \(saveURL.path)")
        load()
    }
}

extension ExpenseStore {
    func totalSpent(forMonth month: String) -> Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return expenses
            .filter { formatter.string(from: $0.date) == month }
            .reduce(0) { $0 + $1.amount }
    }

    func add(_ expense: Expense) {
        expenses.append(expense)
        save()
        NotificationCenter.default.post(name: Notification.Name("expensesUpdated"), object: nil)
    }

    func update(_ updated: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == updated.id }) {
            expenses[index] = updated
            save()
            NotificationCenter.default.post(name: Notification.Name("expensesUpdated"), object: nil)
        }
    }

    func delete(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses.remove(at: index)
            save() // Update the saved data after deletion
            NotificationCenter.default.post(name: Notification.Name("expensesUpdated"), object: nil)
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(expenses)
            try data.write(to: saveURL)
            let isICloud = saveURL.path.contains("Mobile Documents")
            print("\(isICloud ? "☁️" : "💾") Saved \(expenses.count) expenses")
        } catch {
            print("Failed to save: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            expenses = try JSONDecoder().decode([Expense].self, from: data)
        } catch {
            print("Failed to load: \(error)")
        }
    }

    func totalSpentByMonth() -> [String: Double] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return Dictionary(grouping: expenses, by: { formatter.string(from: $0.date) })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    func syncStorageIfNeeded() {
        let fileManager = FileManager.default
        let localURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("expenses.json")
        guard let iCloudDocsURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents/expenses.json") else {
            print("❌ iCloud URL not found")
            return
        }

        let localExists = fileManager.fileExists(atPath: localURL.path)
        let iCloudExists = fileManager.fileExists(atPath: iCloudDocsURL.path)

        print("localExists:", localExists, ", iCloudExists:", iCloudExists)
        if localExists {
            let localDate = (try? fileManager.attributesOfItem(atPath: localURL.path)[.modificationDate] as? Date) ?? Date.distantPast
            let iCloudDate = (try? fileManager.attributesOfItem(atPath: iCloudDocsURL.path)[.modificationDate] as? Date) ?? Date.distantPast

            print("localDate:", localDate, ", iCloudDate:", iCloudDate)

            if localDate > iCloudDate {
                do {
                    try fileManager.removeItem(at: iCloudDocsURL) // remove old file if needed
                } catch {
                    // ignore if it doesn't exist
                }
                do {
                    try fileManager.copyItem(at: localURL, to: iCloudDocsURL)
                    print("☁️ Copied local to iCloud (sync)")
                } catch {
                    print("❌ Failed to copy local data to iCloud: \(error)")
                }
            } else if iCloudDate > localDate {
                do {
                    try fileManager.removeItem(at: localURL) // remove old file if needed
                } catch {
                    // ignore if it doesn't exist
                }
                do {
                    try fileManager.copyItem(at: iCloudDocsURL, to: localURL)
                    print("💾 Copied iCloud to local (sync)")
                } catch {
                    print("❌ Failed to copy iCloud data to local: \(error)")
                }
            } else {
                print("No sync needed — same or no changes.")
            }
        } else if iCloudExists {
            // local doesn't exist, but iCloud does
            do {
                try fileManager.removeItem(at: localURL) // ensure no leftover
            } catch {
                // ignore
            }
            do {
                try fileManager.copyItem(at: iCloudDocsURL, to: localURL)
                print("💾 Restored local from iCloud (sync)")
            } catch {
                print("❌ Failed to restore local from iCloud: \(error)")
            }
        } else {
            print("❌ Neither local nor iCloud has a file. No data to sync.")
        }
        load() // Refresh in-memory data after sync
    }
}

struct ContentView: View {
    @AppStorage("currencySymbol") private var currencySymbol: String = "£"
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

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
    @AppStorage("monthlyStartDay") private var monthlyStartDay: Int = 1
    @AppStorage("categories") private var categories: String = "Food,Transport,Other"
    @AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
    @AppStorage("currencySymbol") private var currencySymbol: String = "£"
    @AppStorage("useiCloud") private var useiCloud: Bool = true
    @StateObject var store = ExpenseStore()
    @AppStorage("budgetEnabled") private var budgetEnabled: Bool = true
    @AppStorage("weeklyStartDay") private var weeklyStartDay: Int = 1
    @AppStorage("budgetByCategory") private var budgetByCategory: Bool = false
    @AppStorage("categoryBudgets") private var categoryBudgets: String = ""
    @AppStorage("groupByDay") private var groupByDay: Bool = false
    @AppStorage("showRating") private var showRating: Bool = true
    @AppStorage("simpleMode") private var simpleMode: Bool = false
    @State private var showResetAlert = false
    
    let currencyOptions: [(symbol: String, country: String)] = [
        ("£", "United Kingdom"),
        ("$", "United States"),
        ("€", "Eurozone"),
        ("₩", "South Korea"),
        ("¥", "Japan"),
        ("₹", "India"),
        ("₽", "Russia"),
        ("฿", "Thailand"),
        ("₫", "Vietnam"),
        ("₴", "Ukraine"),
        ("₪", "Israel"),
        ("₦", "Nigeria"),
        ("₲", "Paraguay"),
        ("₵", "Ghana")
    ]
    
    
    var categoryList: [String] {
        categories.split(separator: ",").map { String($0) }
    }
    
    func saveCategories(_ updated: [String]) {
        categories = updated.joined(separator: ",")
    }
    
    var body: some View {
        Form {
        Section(header: Text("Main Screen Settings")) {
            Toggle("Group expenses by day", isOn: $groupByDay)
            Toggle("Simple mode", isOn: $simpleMode)
        }
        Section(header: Text("Budget")) {
            Toggle("Enable Budget Tracking", isOn: $budgetEnabled)
            if budgetEnabled {
                NavigationLink(destination: BudgetFrequencyView()) {
                    Text("Budget Period")
                }
                NavigationLink(destination: MonthlyBudgetView()) {
                    HStack {
                        Text("\(budgetPeriod) Budget")
                        Spacer()
                        Text("\(currencySymbol)\(monthlyBudget, specifier: "%.0f")")
                            .foregroundColor(.gray)
                    }
                }
                if budgetPeriod == "Monthly" {
                    Picker("Start day of month", selection: $monthlyStartDay) {
                        ForEach(1...31, id: \.self) {
                            Text("\($0)")
                        }
                    }
                }
                if budgetPeriod == "Weekly" {
                    Picker("Start day of week", selection: $weeklyStartDay) {
                        ForEach(0..<Calendar.current.weekdaySymbols.count, id: \.self) { index in
                            Text(Calendar.current.weekdaySymbols[index]).tag(index + 1)
                        }
                    }
                }
            }
            // Removed category budgeting from main Budget section.
        }
        Section(header: Text("Categories")) {
            NavigationLink(destination: ManageCategoriesView(store: store)) {
                Text("Manage Categories")
            }
        }
        Section(header: Text("Appearance")) {
            Picker("Currency", selection: $currencySymbol) {
                ForEach(currencyOptions, id: \.symbol) { option in
                    Text("\(option.symbol) - \(option.country)").tag(option.symbol)
                }
            }
            NavigationLink(destination: {
                Form {
                    Picker("Theme", selection: $appearanceMode) {
                        Text("Automatic").tag("Automatic")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    .pickerStyle(.inline)
                }
                .navigationTitle("Theme")
            }) {
                HStack {
                    Text("Theme")
                    Spacer()
                    Text(appearanceMode)
                        .foregroundColor(.gray)
                }
            }
        }
        Section(header: Text("Storage")) {
            Toggle("Use iCloud for Data", isOn: $useiCloud)
        }
        Section(header: Text("Other")) {
            Button("Restore Settings") {
                showResetAlert = true
            }
            .foregroundColor(.red)
        }
    }
    .onChange(of: useiCloud) { _ in
        store.syncStorageIfNeeded()
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
    .alert("Restore Settings", isPresented: $showResetAlert) {
        Button("Restore", role: .destructive) {
            appearanceMode = "Automatic"
            currencySymbol = "£"
            budgetPeriod = "Monthly"
            monthlyStartDay = 1
            weeklyStartDay = 1
            monthlyBudget = 0
            budgetEnabled = true
            budgetByCategory = false
            categoryBudgets = ""
        }
        Button("Cancel", role: .cancel) {}
    } message: {
        Text("Are you sure you want to restore all settings to default?")
    }
        }
    }
    
    struct MonthlyBudgetView: View {
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
    @AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
    @AppStorage("budgetByCategory") private var budgetByCategory: Bool = false
    @AppStorage("currencySymbol") private var currencySymbol: String = "£"
    @AppStorage("categoryBudgets") private var categoryBudgets: String = ""
    
    var totalCategoryBudget: Double {
        categoryBudgets
            .split(separator: ",")
            .compactMap { pair in
                let parts = pair.split(separator: ":")
                return parts.count == 2 ? Double(parts[1]) : nil
            }
            .reduce(0, +)
    }

    var formattedBudget: String {
        String(format: "\(currencySymbol)%.2f", monthlyBudget)
    }
        
    var body: some View {
        Form {
            Section {
                if budgetByCategory {
                    Text("\(currencySymbol)  \(totalCategoryBudget, specifier: "%.0f")")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.gray)
                        .opacity(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack {
                        Text(currencySymbol)
                        TextField("Budget", value: $monthlyBudget, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Section {
                Toggle("Budget by Category", isOn: $budgetByCategory)
                if budgetByCategory {
                    NavigationLink(destination: CategoryBudgetView()) {
                        Text("Category Budgets")
                    }
                }
            }
        }
        .navigationTitle("\(budgetPeriod) Budget")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: budgetByCategory) { newValue in
            if newValue {
                monthlyBudget = totalCategoryBudget
            }
        }
        .onChange(of: categoryBudgets) { _ in
            if budgetByCategory {
                monthlyBudget = totalCategoryBudget
            }
        }
    }
    }
    
    struct CategoryBudgetView: View {
        @AppStorage("categories") private var categories: String = "Food,Transport,Other"
        @AppStorage("categoryBudgets") private var categoryBudgets: String = ""
        
        @State private var budgetDict: [String: String] = [:]
        
        var categoryList: [String] {
            categories.split(separator: ",").map { String($0) }
        }
        
        func loadBudgets() {
            let pairs = categoryBudgets.split(separator: ",").map { $0.split(separator: ":") }
            for pair in pairs {
                if pair.count == 2 {
                    let category = String(pair[0])
                    let amount = String(pair[1])
                    budgetDict[category] = amount
                }
            }
            for category in categoryList where budgetDict[category] == nil {
                budgetDict[category] = "0"
            }
        }
        
        func saveBudgets() {
            let validEntries = budgetDict.map { "\($0.key):\($0.value)" }
            categoryBudgets = validEntries.joined(separator: ",")
        }
        
        var body: some View {
            Form {
                ForEach(categoryList, id: \.self) { category in
                    HStack {
                        Text(category)
                        Spacer()
                        TextField("0", text: Binding(
                            get: { budgetDict[category, default: "0"] },
                            set: {
                                let cleaned = String(Int($0) ?? 0)
                                budgetDict[category] = cleaned
                                saveBudgets()
                            }
                        ))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .frame(width: 100)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textSelection(.disabled)
                    }
                }
            }
            .navigationTitle("Category Budgets")
            .onAppear {
                loadBudgets()
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


struct SpendingTrendCardView: View {
    let expenses: [Expense]
    let startDate: Date
    let endDate: Date
    let monthlyBudget: Double

    var body: some View {
        let calendar = Calendar.current
        let cappedEndDate = min(endDate, Date())
        let spendingData = expenses
            .filter { $0.date >= startDate && $0.date <= cappedEndDate }
            .sorted(by: { $0.date < $1.date })

        let grouped = Dictionary(grouping: spendingData) {
            calendar.startOfDay(for: $0.date)
        }

        let dateRange = calendar.dateComponents([.day], from: startDate, to: cappedEndDate).day ?? 0
        let sortedDates = (0...dateRange).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startDate)
        }

        let dailyTotals: [(date: Date, total: Double)] = {
            var runningTotal: Double = 0
            return sortedDates.map { date in
                let dayTotal = grouped[date]?.reduce(0) { $0 + $1.amount } ?? 0
                runningTotal += dayTotal
                return (date, runningTotal)
            }
        }()

        return VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(Array(dailyTotals.enumerated()), id: \.1.date) { index, item in
                    if item.date <= cappedEndDate {
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Total", item.total)
                        )
                    }
                }
            }
            .chartYScale(domain: 0...max(monthlyBudget, dailyTotals.last?.total ?? 0))
            .chartXAxis {
                let today = Calendar.current.startOfDay(for: Date())
                let axisDates: [Date] = {
                    if startDate <= today && today <= endDate {
                        return [startDate, today, endDate]
                    } else {
                        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
                        return stride(from: 0, through: days, by: 10).compactMap {
                            Calendar.current.date(byAdding: .day, value: $0, to: startDate)
                        }
                    }
                }()
 
                AxisMarks(values: axisDates) { date in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let dateValue = date.as(Date.self) {
                            Text(dateValue.formatted(.dateTime.day().month()))
                        }
                    }
                }
            }
            .frame(height: 180)
        }
    }
}
