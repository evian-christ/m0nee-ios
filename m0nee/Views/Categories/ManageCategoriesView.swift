import SwiftUI

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
