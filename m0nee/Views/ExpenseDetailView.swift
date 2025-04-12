import SwiftUI

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
