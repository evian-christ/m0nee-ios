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
						if isEditing {
							NavigationLink(destination: EditCategoryView(store: store, category: category)) {
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
								}
								.padding(.vertical, 6)
							}
						} else {
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
							}
							.padding(.vertical, 6)
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
		// Default Category Icons
		"tray", // No Category
		"fork.knife", // Food
		"car.fill", // Transport
		"gamecontroller.fill", // Entertainment
		"house.fill", // Rent
		"bag.fill", // Shopping

		// Food & Drink
		"cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill", "mug.fill", "wineglass.fill", "carrot.fill", "apple.wholefill", "birthday.cake.fill", "leaf.fill",

		// Transportation
		"car", "bus.fill", "tram.fill", "bicycle", "scooter", "airplane.departure", "sailboat.fill", "fuelpump.fill",

		// Home & Utilities
		"house", "lightbulb.fill", "drop.fill", "bolt.fill", "thermometer.sun.fill", "wrench.and.screwdriver.fill", "hammer.fill", "paintpalette.fill", "trash.fill", "washer.fill", "dryer.fill",

		// Shopping
		"bag", "cart.fill", "creditcard.fill", "tag.fill", "gift.fill", "tshirt.fill", "shoe.fill", "watch.fill", "diamond.fill",

		// Entertainment & Hobbies
		"gamecontroller", "film.fill", "tv.fill", "music.note", "mic.fill", "book.closed.fill", "paintpalette", "camera.fill", "photo.fill", "ticket.fill", "theatermasks.fill",

		// Health & Fitness
		"heart.fill", "figure.walk", "figure.run", "figure.strengthtraining.traditional", "cross.case.fill", "pills.fill", "bandage.fill", "waveform.path.ecg",

		// Finance
		"dollarsign.circle.fill", "banknote.fill", "chart.pie.fill", "arrow.up.right.and.arrow.down.left.rectangle.fill", "bitcoinsign.circle.fill",

		// Communication & Tech
		"phone.fill", "message.fill", "envelope.fill", "laptopcomputer", "desktopcomputer", "printer.fill", "headphones", "airpodspro", "wifi", "antenna.radiowaves.left.and.right",

		// People & Social
		"person.fill", "person.2.fill", "person.3.fill", "hand.thumbsup.fill", "hand.thumbsdown.fill", "face.smiling.fill", "heart.text.square.fill",

		// Travel
		"globe.americas.fill", "map.fill", "bed.double.fill", "tent.fill", "beach.umbrella.fill",

		// Education
		"book.fill", "graduationcap.fill", "pencil.and.outline", "paperclip",

		// Weather
		"cloud.fill", "sun.max.fill", "moon.fill", "snowflake", "cloud.bolt.rain.fill",

		// Nature
		"leaf.arrow.circlepath", "tree.fill", "pawprint.fill", "ant.fill", "ladybug.fill", "fish.fill", "bird.fill", "tortoise.fill", "hare.fill",

		// Objects & Tools
		"folder.fill", "doc.fill", "paperplane.fill", "bell.fill", "bookmark.fill", "calendar", "pin.fill", "scissors", "ruler", "key.fill", "lock.fill", "gearshape.fill",

		// Arrows & Directions
		"arrow.up.circle.fill", "arrow.down.circle.fill", "arrow.left.circle.fill", "arrow.right.circle.fill", "arrow.uturn.left.circle.fill", "arrow.uturn.right.circle.fill",

		// Miscellaneous
		"star.fill", "circle.fill", "square.fill", "triangle.fill", "diamond.fill", "flag.fill", "exclamationmark.triangle.fill", "questionmark.circle.fill", "info.circle.fill", "plus.circle.fill", "minus.circle.fill", "xmark.circle.fill", "checkmark.circle.fill", "ellipsis.circle.fill"
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
