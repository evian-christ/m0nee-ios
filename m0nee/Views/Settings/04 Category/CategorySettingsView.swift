import SwiftUI

struct CategorySettingsView: View {
	@ObservedObject var store: ExpenseStore
	@State private var newCategory = ""
	@State private var showingAddSheet = false
	@State private var categoryToDelete: CategoryItem? = nil
	@State private var isEditing = false
	@State private var selectedSymbol = "folder"
	@State private var selectedColor: Color = .gray
	@State private var showCategoryAddError = false
	@State private var categoryAddErrorMessage = ""
	
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
								Image(systemName: category.symbol)
									.font(.system(size: 18))
									.foregroundColor(.white)
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
			.fullScreenCover(isPresented: $showingAddSheet) {
				NavigationStack {
					Form {
						Section {
							HStack {
								Spacer()
								ZStack {
									Circle()
										.fill(selectedColor)
										.frame(width: 60, height: 60)
									Image(systemName: selectedSymbol)
										.font(.system(size: 28))
										.foregroundColor(.white)
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
							NavigationLink("Change Color") {
								ColorPickerView(selectedColor: $selectedColor)
							}
						}
					}
					.navigationTitle("New Category")
					.navigationBarTitleDisplayMode(.inline)
					.navigationBarBackButtonHidden(true)
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
								let maxLength = 30
								let cleaned = String(trimmed.prefix(maxLength))

								if cleaned.isEmpty {
									categoryAddErrorMessage = "Category name cannot be empty."
									showCategoryAddError = true
									return
								}

								if store.categories.contains(where: { $0.name.lowercased() == cleaned.lowercased() }) {
									categoryAddErrorMessage = "Category name already exists."
									showCategoryAddError = true
									return
								}

								store.addCategory(CategoryItem(name: cleaned, symbol: selectedSymbol, color: CodableColor(selectedColor)))
								newCategory = ""
								showingAddSheet = false
							}
						}
					}
					.alert("Error", isPresented: $showCategoryAddError) {
						Button("OK", role: .cancel) { }
					} message: {
						Text(categoryAddErrorMessage)
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
					store.removeCategory(category)
					
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
	@Environment(\.dismiss) var dismiss
	
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
					dismiss()
				} label: {
					HStack(spacing: 16) {
						Circle()
							.fill(item.color)
							.frame(width: 24, height: 24)
						Text(item.name)
							.foregroundColor(.primary)
						if selectedColor == item.color {
							Spacer()
							Image(systemName: "checkmark")
								.foregroundColor(.blue)
						}
					}
				}
			}
			
			Section {
				ColorPicker("Custom", selection: $selectedColor, supportsOpacity: false)
			}
		}
		.navigationTitle("Choose Color")
		.navigationBarTitleDisplayMode(.inline)
	}
}

struct IconPickerView: View {
	@Binding var selectedSymbol: String
	@State private var searchText = ""
	@Environment(\.dismiss) var dismiss
	
	let symbols = [
		// Most used first: food, rent, transport
		"fork.knife", "takeoutbag.and.cup.and.straw", "cup.and.saucer", "cart", "bag", "gift",
		"house", "house.fill", "building.2", "bed.double", "lamp.desk",
		"car", "car.fill", "fuelpump", "bicycle", "bus", "airplane",
		
		// Finance / payments
		"creditcard", "dollarsign.circle", "bitcoinsign.circle", "wallet.pass", "banknote",
		
		// Entertainment & leisure
		"gamecontroller", "gamecontroller.fill", "puzzlepiece", "music.note", "paintpalette", "film", "video",
		
		// Communication
		"phone", "message", "envelope", "bell", "megaphone",
		
		// People & tools
		"person", "person.crop.circle", "person.badge.plus", "wrench", "hammer", "gear",
		
		// Essentials (health & personal items)
		"pills", "bandage", "cross.case", "cross",
		
		// Other
		"heart", "globe", "leaf", "camera", "photo", "book", "calendar", "doc",
		"pawprint", "tortoise", "hare", "ant", "ladybug", "bird", "fish", "dog", "cat"
	]
	
	var body: some View {
		ScrollView {
			LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 24) {
				ForEach(symbols.filter { searchText.isEmpty || $0.localizedCaseInsensitiveContains(searchText) }, id: \.self) { symbol in
					Button {
						selectedSymbol = symbol
						dismiss()
					} label: {
						Image(systemName: symbol)
							.font(.system(size: 28))
							.foregroundColor(.white)
							.frame(width: 60, height: 60)
							.background(Color(uiColor: UIColor { traitCollection in
								traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray5 : UIColor.gray
							}))
							.clipShape(RoundedRectangle(cornerRadius: 12))
					}
				}
			}
			.padding()
		}
		.navigationTitle("Choose Icon")
		.navigationBarTitleDisplayMode(.inline)
		.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search icons")
		.navigationBarBackButtonHidden(false)
		.toolbar {
			ToolbarItem(placement: .navigationBarLeading) {
				Text("")
			}
		}
	}
}
