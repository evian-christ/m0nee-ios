import SwiftUI

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

class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []

    private let saveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("expenses.json")

    init() {
        load()
    }

    func add(_ expense: Expense) {
        expenses.append(expense)
        save()
    }

    func update(_ updated: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == updated.id }) {
            expenses[index] = updated
            save()
        }
    }

    func delete(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses.remove(at: index)
            save() // Update the saved data after deletion
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(expenses)
            try data.write(to: saveURL)
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
}

struct ContentView: View {
    @AppStorage("currencySymbol") private var currencySymbol: String = "£"
    @StateObject var store = ExpenseStore()
    @State private var showingAddExpense = false
    @State private var showingSettings = false
    @State private var showingInsights = false
    @State private var selectedMonth: String
    private var monthsWithExpenses: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let uniqueMonths = Set(store.expenses.map { formatter.string(from: $0.date) })
        return uniqueMonths.sorted(by: >)
    }
    private var filteredExpenses: [Binding<Expense>] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if selectedMonth.isEmpty {
            return $store.expenses.map { $0 }
        } else {
            return $store.expenses.filter {
                formatter.string(from: $0.wrappedValue.date) == selectedMonth
            }
        }
    }

    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let recentMonth = formatter.string(from: Date())
        _selectedMonth = State(initialValue: recentMonth)
    }

    var body: some View {
        NavigationStack {
        ScrollView {
        VStack(spacing: 0) {
            TabView {
                ForEach(1...3, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                        Text("Summary Page \(index)")
                            .foregroundColor(.gray)
                    }
                    .frame(height: 240)
                    .padding(.horizontal, 16)
                }
            }
            .frame(height: 240)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .padding(.vertical, 16)

            LazyVStack(spacing: 0) {
                ForEach(filteredExpenses, id: \.id) { $expense in
                    NavigationLink(destination: ExpenseDetailView(expenseID: expense.id, store: store)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(expense.name)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text(expense.category)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
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
                SettingsView()
            }
            .navigationDestination(isPresented: $showingInsights) {
                Text("Insights View") // Placeholder
                    .font(.largeTitle)
                    .padding()
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
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
    @AppStorage("monthlyStartDay") private var monthlyStartDay: Int = 1
    @AppStorage("categories") private var categories: String = "Food,Transport,Other"
    @AppStorage("currencySymbol") private var currencySymbol: String = "£"
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

    @State private var newCategory = ""

    var categoryList: [String] {
        categories.split(separator: ",").map { String($0) }
    }

    func saveCategories(_ updated: [String]) {
        categories = updated.joined(separator: ",")
    }

    var body: some View {
        Form {
            Section(header: Text("Monthly Budget")) {
                TextField("Enter budget", value: $monthlyBudget, format: .number)
                    .keyboardType(.decimalPad)
            }

            Section(header: Text("Month Start Day")) {
                Picker("Start Day", selection: $monthlyStartDay) {
                    ForEach(1...31, id: \.self) {
                        Text("\($0)")
                    }
                }
            }

            Section(header: Text("Currency")) {
                Picker("Select Currency", selection: $currencySymbol) {
                    ForEach(currencyOptions, id: \.symbol) { option in
                        Text("\(option.symbol) - \(option.country)").tag(option.symbol)
                    }
                }
            }

            Section(header: Text("Manage Categories")) {
                List {
                    ForEach(categoryList, id: \.self) { category in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.gray)
                            Text(category)
                            Spacer()
                            Button(role: .destructive) {
                                let updated = categoryList.filter { $0 != category }
                                saveCategories(updated)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                    .onMove { indices, newOffset in
                        var updated = categoryList
                        updated.move(fromOffsets: indices, toOffset: newOffset)
                        saveCategories(updated)
                    }

                    HStack {
                        TextField("New Category", text: $newCategory)
                        Button("Add") {
                            var updated = categoryList
                            if !newCategory.isEmpty && !updated.contains(newCategory) {
                                updated.append(newCategory)
                                saveCategories(updated)
                                newCategory = ""
                            }
                        }
                    }
                }
                .environment(\.editMode, .constant(.active))
            }
        }
        .navigationTitle("Settings")
    }
                    }
                    
