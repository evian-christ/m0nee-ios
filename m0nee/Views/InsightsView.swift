import SwiftUI

struct InsightsView: View {
		@EnvironmentObject var store: ExpenseStore
		@AppStorage("favouriteInsightCards") private var favouriteInsightCardsRaw: Data = Data()
		@State private var favourites: [InsightCardType] = []
		@State private var deleteTrigger = UUID()
		@State private var showHelpTooltip = false
		@State private var showProUpgradeModal = false
		@AppStorage("showRating", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var showRating: Bool = true
	
	private var currentBudgetDates: (startDate: Date, endDate: Date) {
		let calendar = Calendar.current
		let today = Date()
		let period = UserDefaults.standard.string(forKey: "budgetPeriod") ?? "Monthly"
		let startDay = UserDefaults.standard.integer(forKey: period == "Weekly" ? "weeklyStartDay" : "monthlyStartDay")
		
		if period == "Weekly" {
			let weekdayToday = calendar.component(.weekday, from: today)
			let delta = (weekdayToday - startDay + 7) % 7
			let weekStart = calendar.date(byAdding: .day, value: -delta, to: today)!
			let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
			return (calendar.startOfDay(for: weekStart), calendar.startOfDay(for: weekEnd))
		} else {
			let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
			let monthStart = calendar.date(byAdding: .day, value: startDay - 1, to: currentMonth)!
			let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart)!
			let endDate = calendar.date(byAdding: .day, value: -1, to: nextMonth)!
			return (calendar.startOfDay(for: monthStart), calendar.startOfDay(for: endDate))
		}
	}
	
	private var currentExpenses: [Expense] {
		store.expenses.filter {
			let date = Calendar.current.startOfDay(for: $0.date)
			return date >= currentBudgetDates.startDate && date <= currentBudgetDates.endDate
		}
	}
	var body: some View {
		ZStack {
			ScrollView {
				LazyVStack(spacing: 16) {
					ForEach(InsightCardType.allCases, id: \.rawValue) { type in
						insightCardRow(for: type)
					}
				}
				.padding(.vertical)
				.onAppear {
					favourites = loadFavourites()
				}
				.onChange(of: favourites) { _ in
					saveFavourites()
				}
			}
			.navigationTitle("Insights")
			.navigationBarTitleDisplayMode(.inline)
			.overlay(alignment: .topTrailing) {
					if showHelpTooltip {
							VStack(alignment: .trailing, spacing: 8) {
									Text("Long-press a card\nand select \"Add to Favourite\"\nto add it to the main screen.")
											.font(.caption)
											.padding(10)
											.background(Color(.systemGray6))
											.cornerRadius(8)
											.shadow(radius: 3)

									Button(action: {
											showHelpTooltip = false
									}) {
											Text("Got it")
													.font(.caption2)
													.foregroundColor(.blue)
									}
							}
							.padding(.top, 10)
							.padding(.trailing, 16)
							.transition(.opacity)
							.animation(.easeInOut, value: showHelpTooltip)
					}
			}
		}
				.toolbar {
						ToolbarItem(placement: .navigationBarTrailing) {
								Button(action: { showHelpTooltip.toggle() }) {
										Image(systemName: "questionmark.circle")
								}
						}
				}
				.sheet(isPresented: $showProUpgradeModal) {
						ProUpgradeModalView(isPresented: $showProUpgradeModal)
				}
		}
	
	func currentMonth() -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM"
		return formatter.string(from: Date())
	}
	
	
	
	private func loadFavourites() -> [InsightCardType] {
		guard let decoded = try? JSONDecoder().decode([InsightCardType].self, from: favouriteInsightCardsRaw) else {
			return []
		}
		return decoded
	}
	
	private func saveFavourites() {
		if let encoded = try? JSONEncoder().encode(favourites) {
			favouriteInsightCardsRaw = encoded
		}
	}
	
	private func toggleFavourite(_ type: InsightCardType) {
		if let index = favourites.firstIndex(of: type) {
			favourites.remove(at: index)
		} else {
			favourites.append(type)
		}
		saveFavourites()
		favourites = loadFavourites()
		NotificationCenter.default.post(name: Notification.Name("favouritesUpdated"), object: nil)
	}
	
	private func isFavourited(_ type: InsightCardType) -> Bool {
		favourites.contains(type)
	}

	@ViewBuilder
	private func insightCardRow(for type: InsightCardType) -> some View {
			ZStack {
					InsightCardView(
							type: type,
							expenses: currentExpenses,
							startDate: currentBudgetDates.startDate,
							endDate: currentBudgetDates.endDate,
							categories: store.categories,
							isProUser: store.isProUser
					)
					.frame(height: 260)
					
					.id(type)
					.transition(.asymmetric(insertion: .identity, removal: .move(edge: .top)))
					.animation(.interpolatingSpring(stiffness: 300, damping: 20), value: deleteTrigger)
					.contextMenu {
							if isFavourited(type) {
									Button {
											toggleFavourite(type)
									} label: {
											Label("Remove from Favourite", systemImage: "star.slash")
									}
							} else {
									Button {
											toggleFavourite(type)
									} label: {
											Label("Add to Favourite", systemImage: "star")
									}
									.disabled(type.isProOnly && !store.isProUser)
							}
							Button(role: .cancel) { } label: {
									Label("Cancel", systemImage: "xmark")
							}
					}
					.padding(.horizontal, 20)
					.padding(.vertical, 2)

					if type.isProOnly && !store.isProUser {
							VStack {
									Spacer()
									Button(action: {
										showProUpgradeModal = true
									}) {
										Text("Upgrade to Monir Pro")
											.font(.subheadline).bold()
											.foregroundColor(.white)
											.padding(.vertical, 10)
											.padding(.horizontal, 20)
											.background(Color.blue.opacity(0.8))
											.cornerRadius(10)
									}
									.padding(.bottom, 20)
							}
					}
			}
	}
}
