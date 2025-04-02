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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(expense.name)
                                    .font(.headline)
                                Text(expense.category)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("£\(expense.amount, specifier: "%.2f")")
                                .font(.headline)
                        }
                        .padding(.vertical, 4)
                    }
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
                AddExpenseView { newExpense in
                    store.add(newExpense)
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
    let expenseID: UUID
    @ObservedObject var store: ExpenseStore
    @State private var isEditing = false

    private var expense: Expense? {
        store.expenses.first(where: { $0.id == expenseID })
    }

    var body: some View {
        if let expense = expense {
            Form {
                Section(header: Text("Date")) {
                    Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                }
                Section(header: Text("Amount")) {
                    Text("£\(expense.amount, specifier: "%.2f")")
                }
                Section(header: Text("Category")) {
                    Text(expense.category)
                }
                Section(header: Text("Details")) {
                    Text(expense.details ?? "—")
                }
                Section(header: Text("Rating")) {
                    Text(expense.rating.map { "\($0)/5" } ?? "—")
                }
                Section(header: Text("Note")) {
                    Text(expense.memo ?? "—")
                }
            }
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

    var onSave: (Expense) -> Void
    let categories = ["Food", "Transport", "Other"]

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
        _category = State(initialValue: category)
        _details = State(initialValue: details)
        _rating = State(initialValue: rating)
        _memo = State(initialValue: memo)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section(header: Text("Required")) {
                DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                TextField("Name", text: $name)
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
            }

            Section(header: Text("Optional")) {
                TextField("Details", text: $details)
                Stepper(value: $rating, in: 1...5) {
                    HStack {
                        Text("Rating")
                        Spacer()
                        Text("\(rating)")
                    }
                }
                TextField("Note", text: $memo)
            }

            Button("Save") {
                guard let parsedAmount = Double(amount) else { return }
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
        .navigationTitle(name.isEmpty ? "Add Expense" : "Edit \(name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
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

            Section(header: Text("Manage Categories")) {
                ForEach(categoryList, id: \.self) { category in
                    HStack {
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
        }
        .navigationTitle("Settings")
    }
}
