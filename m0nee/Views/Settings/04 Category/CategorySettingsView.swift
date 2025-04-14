import SwiftUI

struct CategorySettingsView: View {
	@ObservedObject var store: ExpenseStore
	@State private var newCategory = ""
	@State private var showingAddSheet = false
	@State private var categoryToDelete: CategoryItem? = nil
	@State private var isEditing = false
	@State private var selectedSymbol = "folder"
	@State private var selectedColor: Color = .gray
	
	var body: some View {
		NavigationStack {
			List {
				Section {
					ForEach(store.categories) { category in
						HStack(spacing: 12) {
							ZStack {
								Circle()
									.fill(category.color.color)
									.frame(width: 36, height: 36)
								Text(category.symbol)
									.font(.system(size: 18))
							}
							
							Text(category.name)
								.font(.body)
							
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
						.padding(.vertical, 6)
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
							HStack {
								Spacer()
								ZStack {
									Circle()
										.fill(Color(UIColor.systemGray5))
										.frame(width: 60, height: 60)
									Image(systemName: selectedSymbol)
										.font(.system(size: 28))
										.foregroundColor(.primary)
								}
								Spacer()
							}
						}
						
						Section(header: Text("Name")) {
							TextField("Category Name", text: $newCategory)
						}
						
						Section {
							NavigationLink("Change Icon") {
								IconPickerView(selectedSymbol: $selectedSymbol)
							}
							// Updated ColorPickerSection
							ColorPickerView(selectedColor: $selectedColor)
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
								guard !trimmed.isEmpty, !store.categories.contains(where: { $0.name == trimmed }) else { return }
								store.categories.append(CategoryItem(name: trimmed, symbol: selectedSymbol, color: CodableColor(selectedColor)))
								NotificationCenter.default.post(name: Notification.Name("categoriesUpdated"), object: nil)
								newCategory = ""
								showingAddSheet = false
							}
						}
					}
				}
			}
		}
		.alert("Delete \"\(categoryToDelete?.name ?? "")\"?", isPresented: Binding<Bool>(
			get: { categoryToDelete != nil },
			set: { if !$0 { categoryToDelete = nil } }
		)) {
			Button("Delete", role: .destructive) {
				if let category = categoryToDelete {
					let updated = store.categories.filter { $0.id != category.id }
					store.categories = updated
					
					// Remove matching expenses using store.delete() so it's properly saved
					let toDelete = store.expenses.filter { $0.category == category.name }
					toDelete.forEach { store.delete($0) }
				}
				categoryToDelete = nil
			}
			Button("Cancel", role: .cancel) {
				categoryToDelete = nil
			}
		} message: {
			let count = categoryToDelete.map { category in
				store.expenses.filter { $0.category == category.name }.count
			} ?? 0
			if count > 0 {
				Text("This will also delete \(count) expense(s) under this category.")
			} else {
				Text("Are you sure you want to delete this category?")
			}
		}
	}
}

struct ColorPickerView: View {
	@Binding var selectedColor: Color
	@State private var showingColorPicker = false
	
	let presetColors: [(name: String, color: Color)] = [
		("Red", .red), ("Orange", .orange), ("Yellow", .yellow),
		("Green", .green), ("Blue", .blue), ("Indigo", .indigo),
		("Purple", .purple), ("Pink", .pink), ("Gray", .gray)
	]
	
	var body: some View {
		List {
			ForEach(presetColors, id: \.name) { item in
				Button {
					selectedColor = item.color
				} label: {
					HStack {
						Circle()
							.fill(item.color)
							.frame(width: 24, height: 24)
						Text(item.name)
						if selectedColor == item.color {
							Spacer()
							Image(systemName: "checkmark")
								.foregroundColor(.blue)
						}
					}
				}
			}

			NavigationLink {
				Form {
					ColorPicker("Pick a color", selection: $selectedColor, supportsOpacity: false)
						.padding()
				}
				.navigationTitle("Custom Color")
				.navigationBarTitleDisplayMode(.inline)
			} label: {
				HStack {
					Image(systemName: "slider.horizontal.3")
						.foregroundColor(.gray)
					Text("Custom")
					Spacer()
					Circle()
						.fill(selectedColor)
						.frame(width: 20, height: 20)
				}
			}
		}
		.navigationTitle("Choose Colour")
		.navigationBarTitleDisplayMode(.inline)
	}
}

struct IconPickerView: View {
	@Binding var selectedSymbol: String
	@Environment(\.dismiss) var dismiss
	
	let symbols = ["folder", "cart", "house", "car", "gamecontroller", "heart", "airplane", "gift", "bag", "music.note", "doc", "camera", "paintbrush", "wrench", "flame", "globe", "lightbulb", "leaf", "bicycle", "creditcard"]
	
	var body: some View {
		ScrollView {
			LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 24) {
				ForEach(symbols, id: \.self) { symbol in
					Button {
						selectedSymbol = symbol
						dismiss()
					} label: {
						Image(systemName: symbol)
							.font(.system(size: 28))
							.frame(width: 60, height: 60)
							.background(Color(UIColor.systemGray5))
							.clipShape(RoundedRectangle(cornerRadius: 12))
					}
				}
			}
			.padding()
		}
		.navigationTitle("Choose Icon")
		.navigationBarTitleDisplayMode(.inline)
	}
}
