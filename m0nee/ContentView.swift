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

    var body: some View {
        NavigationStack {
            List {
                ForEach($store.expenses) { $expense in
                    NavigationLink(destination: ExpenseDetailView(expenseID: expense.id, store: store)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text(expense.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(expense.category)
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                            Spacer()
                            Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            store.delete(expense)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
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
}

struct ExpenseDetailView: View {
    @AppStorage("currencySymbol") private var currencySymbol: String = "£"
    let expenseID: UUID
    @ObservedObject var store: ExpenseStore
    @State private var isEditing = false

    private var expense: Expense? {
        store.expenses.first(where: { $0.id == expenseID })
    }

    var body: some View {
        if let expense = expense {
            List {
                Section {
                    HStack {
                        Label("Date", systemImage: "calendar")
                        Spacer()
                        Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    HStack {
                        Label("Amount", systemImage: "dollarsign.circle")
                        Spacer()
                        Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
                            .foregroundColor(.green)
                    }
                }

                Section {
                    HStack {
                        Label("Category", systemImage: "tag")
                        Spacer()
                        Text(expense.category)
                            .foregroundColor(.purple)
                    }
                }

                if let details = expense.details {
                    Section {
                        Label("Details", systemImage: "text.alignleft")
                        Text(details)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                }

                if let rating = expense.rating {
                    Section {
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

                if let memo = expense.memo {
                    Section {
                        Label("Note", systemImage: "note.text")
                        Text(memo)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
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
                            store.update(updated)
                            isEditing = false
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
                Spacer().frame(height: 60)
                
                Text(formattedAmount)
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
                    .contentShape(Rectangle())
                    .background(Color.white)
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
                Spacer()
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= rating ? "star.fill" : "star")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.yellow)
                            .onTapGesture {
                                rating = index
                            }
                    }
                }
                Spacer()
            }
            .padding(.bottom, 8)
            
            Form {
                Section(header: Text("Required")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Name", text: $name)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(showFieldValidation && name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.red : Color.clear, lineWidth: 1)
                        )
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
