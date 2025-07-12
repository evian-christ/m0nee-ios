
import SwiftUI

struct EditCategoryView: View {
		@Environment(\.dismiss) private var dismiss
		@ObservedObject var store: ExpenseStore
		
		let category: CategoryItem
		
		@State private var name: String = ""
		@State private var symbol: String = ""
		@State private var color: Color = .gray
		@State private var initialized = false
		
		@State private var showCategoryAddError = false
		@State private var categoryAddErrorMessage = ""
		@State private var showingDeleteAlert = false
		
		var body: some View {
				Form {
						Section {
								HStack {
										Spacer()
										ZStack {
												Circle()
														.fill(color)
														.frame(width: 60, height: 60)
												Image(systemName: symbol)
														.font(.system(size: 28))
														.foregroundColor(.white)
										}
										Spacer()
								}
						}
						
						Section(header: Text("Name")) {
								TextField("Category Name", text: $name)
						}
						
						Section {
								NavigationLink("Change Icon") {
										IconPickerView(selectedSymbol: $symbol)
								}
								NavigationLink("Change Color") {
										ColorPickerView(selectedColor: $color)
								}
						}
						
						Section {
								Button(role: .destructive) {
										showingDeleteAlert = true
								} label: {
										Text("Delete Category")
												.frame(maxWidth: .infinity, alignment: .center)
								}
						}
				}
				.onAppear {
						guard !initialized else { return }
						name = category.name
						symbol = category.symbol
						color = category.color.color
						initialized = true
				}
				.onChange(of: symbol) { newValue in
						print("🛠 symbol changed to: \(newValue)")
				}
						.navigationTitle("Edit Category")
						.navigationBarTitleDisplayMode(.inline)
						.navigationBarBackButtonHidden(true)
						.toolbar {
								ToolbarItem(placement: .cancellationAction) {
										Button("Cancel") {
												dismiss()
										}
								}
								ToolbarItem(placement: .navigationBarTrailing) {
										Button("Save") {
												let trimmed = name.trimmingCharacters(in: .whitespaces)
												let maxLength = 30
												let cleaned = String(trimmed.prefix(maxLength))

												if cleaned.isEmpty {
														categoryAddErrorMessage = "Category name cannot be empty."
														showCategoryAddError = true
														return
												}

												if store.categories.contains(where: { $0.name.lowercased() == cleaned.lowercased() && $0.id != category.id }) {
														categoryAddErrorMessage = "Category name already exists."
														showCategoryAddError = true
														return
												}
												
												var updatedCategory = category
												updatedCategory.name = cleaned
												updatedCategory.symbol = symbol
												updatedCategory.color = CodableColor(color)
												
												store.updateCategory(updatedCategory)
												dismiss()
										}
								}
						}
						.alert("Error", isPresented: $showCategoryAddError) {
								Button("OK", role: .cancel) { }
						} message: {
								Text(categoryAddErrorMessage)
						}
						.alert("Delete \"\(category.name)\"", isPresented: $showingDeleteAlert) {
								Button("Delete", role: .destructive) {
										store.removeCategory(category)
										
										let toDelete = store.expenses.filter { $0.category == category.name }
										toDelete.forEach { store.delete($0) }
										dismiss()
								}
								Button("Cancel", role: .cancel) { }
						} message: {
								let count = store.expenses.filter { $0.category == category.name }.count
								if count > 0 {
										Text("This will also delete \(count) expense(s) under this category.")
								} else {
										Text("Are you sure you want to delete this category?")
								}
						}
		}
}
