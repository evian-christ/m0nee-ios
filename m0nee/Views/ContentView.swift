import SwiftUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject private var store: ExpenseStore
    @EnvironmentObject private var settings: AppSettings

    @State private var showingAddExpense = false
    @State private var showingSettings = false
    @State private var showingInsights = false
    @State private var showingAddBudget = false
    @State private var newBudgetName: String = ""
    @State private var newBudgetGoal: String = ""

    @StateObject private var viewModel: ContentViewModel

    init(viewModel: ContentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var currencyFormatter: NumberFormatter {
        NumberFormatter.currency(for: settings.decimalDisplayMode, currencyCode: settings.currencyCode)
    }

    private var preferredScheme: ColorScheme? {
        switch settings.appearanceMode {
        case "Dark": return .dark
        case "Light": return .light
        default: return nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        summaryCard
                        budgetsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 36)
                    .padding(.bottom, 120)
                }

                floatingAddButton
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gear")
                            .font(.title3)
                    }

                    Button { showingInsights = true } label: {
                        Image(systemName: "chart.bar")
                            .font(.title3)
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Monir")
                            .font(.headline.weight(.semibold))
                        Text("Expense overview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        newBudgetName = ""
                        newBudgetGoal = ""
                        showingAddBudget = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                NavigationStack {
                    AddExpenseView(defaultBudgetID: viewModel.summaries.first?.id) { newExpense in
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
                InsightsView()
                    .environmentObject(store)
                    .environmentObject(settings)
            }
            .sheet(isPresented: $showingAddBudget) {
                NavigationStack {
                    Form {
                        Section("Budget name") {
                            TextField("e.g. September 2025", text: $newBudgetName)
                        }

                        Section("Goal (optional)") {
                            TextField("Amount", text: $newBudgetGoal)
                                .keyboardType(.decimalPad)
                        }
                    }
                    .navigationTitle("New Budget")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddBudget = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                addBudget()
                                showingAddBudget = false
                            }
                            .disabled(newBudgetName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(preferredScheme)
    }

    // MARK: - Sections

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total spent")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            Text(currencyFormatter.string(from: NSNumber(value: viewModel.totalSpent)) ?? "—")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
            Text("Across \(viewModel.summaries.count) budget\(viewModel.summaries.count == 1 ? "" : "s")")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
        )
    }

    private var budgetsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Budgets")
                .font(.title3.bold())

            if viewModel.summaries.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No budgets yet")
                        .font(.headline)
                    Text("Tap + to create your first budget.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
            } else {
                ForEach(viewModel.summaries) { summary in
                    NavigationLink {
                        BudgetDetailView(
                            budget: summary.budget,
                            viewModel: viewModel,
                            currencyFormatter: currencyFormatter
                        )
                        .environmentObject(store)
                        .environmentObject(settings)
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(summary.budget.name)
                                .font(.headline)
                            HStack {
                                Text(currencyFormatter.string(from: NSNumber(value: summary.totalSpent)) ?? "—")
                                    .font(.title3.weight(.semibold))
                                Spacer()
                                Text("\(summary.expenseCount) items")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            if let goal = summary.budget.goalAmount {
                                let remaining = max(goal - summary.totalSpent, 0)
                                Text("Goal: \(currencyFormatter.string(from: NSNumber(value: goal)) ?? "—")  •  Remaining: \(currencyFormatter.string(from: NSNumber(value: remaining)) ?? "—")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
                        )
                    }
                }
            }
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(alignment: .center, spacing: 16) {
            let categoryItem = store.categories.first { $0.name == expense.category }
            Circle()
                .fill((categoryItem?.color.color ?? Color.accentColor).opacity(0.18))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: categoryItem?.symbol ?? "questionmark")
                        .foregroundColor(categoryItem?.color.color ?? .accentColor)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(expense.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(expense.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(currencyFormatter.string(from: NSNumber(value: expense.amount)) ?? "")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .contentShape(Rectangle())
    }

    private var floatingAddButton: some View {
        Button {
            showingAddExpense = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                Text("Log expense")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: Color.accentColor.opacity(0.3), radius: 16, x: 0, y: 10)
            .padding(.trailing, 24)
            .padding(.bottom, 48)
        }
        .disabled(viewModel.summaries.isEmpty)
    }

    private func addBudget() {
        let trimmedName = newBudgetName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let goal = Double(newBudgetGoal)
        viewModel.createBudget(name: trimmedName, goalAmount: goal)
        newBudgetName = ""
        newBudgetGoal = ""
    }
}
