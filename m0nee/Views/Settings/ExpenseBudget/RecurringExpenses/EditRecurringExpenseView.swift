
import SwiftUI

struct EditRecurringExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ExpenseStore

    @State private var recurringExpense: RecurringExpense // The recurring expense being edited

    @State private var name: String
    @State private var rawAmount: String // For TextField input
    @State private var category: String
    @State private var memo: String
    @State private var details: String

    @State private var showingCategorySelection = false
    @State private var showFieldValidation = false

    private let decimalDisplayMode: DecimalDisplayMode
    private let currencyCode: String

    init(recurringExpense: RecurringExpense, decimalDisplayMode: DecimalDisplayMode, currencyCode: String) {
        _recurringExpense = State(initialValue: recurringExpense)
        _name = State(initialValue: recurringExpense.name)
        _rawAmount = State(initialValue: NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: recurringExpense.amount)) ?? "")
        _category = State(initialValue: recurringExpense.category)
        _memo = State(initialValue: recurringExpense.memo ?? "")
        _details = State(initialValue: recurringExpense.details ?? "")
        self.decimalDisplayMode = decimalDisplayMode
        self.currencyCode = currencyCode
    }

    private var currencySymbol: String {
        CurrencyManager.symbol(for: currencyCode)
    }

    private var formattedAmount: String {
        NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: Double(rawAmount) ?? 0)) ?? ""
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Amount").font(.caption)) {
                    HStack {
                        Text(currencySymbol)
                            .font(.system(size: 20, weight: .bold))
                        TextField("0.00", text: $rawAmount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .bold))
                    }
                }

                Section(header: Text("Required").font(.caption)) {
                    ZStack(alignment: .trailing) {
                        TextField("Name", text: $name)
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
                    .navigationTitle("Select Category"), isActive: $showingCategorySelection) {
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

                Section(header: Text("Optional").font(.caption)) {
                    TextField("Details", text: $details)
                    .onChange(of: details) { newValue in
                        if newValue.count > 500 {
                            details = String(newValue.prefix(500))
                        }
                    }
                    TextField("Note", text: $memo)
                    .onChange(of: memo) { newValue in
                        if newValue.count > 500 {
                            memo = String(newValue.prefix(500))
                        }
                    }
                }

                Section(header: Text("Recurrence Details (Not Editable)").font(.caption)) {
                    HStack {
                        Text("Starts on")
                        Spacer()
                        Text(recurringExpense.startDate.formatted(date: .long, time: .omitted))
                    }
                    HStack {
                        Text("Frequency")
                        Spacer()
                        Text(RecurringSettingsView.ruleDescription(recurrenceRule: recurringExpense.recurrenceRule))
                    }
                    Text("To change the start date or recurrence rule, please delete this recurring expense and create a new one.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Recurring Expense")
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
                              !rawAmount.trimmingCharacters(in: .whitespaces).isEmpty,
                              !category.isEmpty else {
                            return
                        }

                        let parsedAmount = (Double(rawAmount) ?? 0)

                        // Update the recurring expense object
                        var updatedRecurringExpense = recurringExpense
                        updatedRecurringExpense.name = name
                        updatedRecurringExpense.amount = parsedAmount
                        updatedRecurringExpense.category = category
                        updatedRecurringExpense.memo = memo.isEmpty ? nil : memo
                        updatedRecurringExpense.details = details.isEmpty ? nil : details

                        store.updateRecurringExpenseMetadata(updatedRecurringExpense)
                        dismiss()
                    }
                }
            }
        }
    }
}
