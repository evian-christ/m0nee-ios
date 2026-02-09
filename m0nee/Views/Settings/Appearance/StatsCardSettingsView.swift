import SwiftUI

struct StatsCardSettingsView: View {
	@EnvironmentObject var settings: AppSettings
	@EnvironmentObject var store: ExpenseStore
	@State private var showProUpgradeSheet = false

	private var availableCards: [StatsCardType] {
		StatsCardType.allCases.filter { !settings.enabledStatsCards.contains($0) }
	}

	var body: some View {
		List {
			Section {
				if settings.enabledStatsCards.isEmpty {
					Text("No cards enabled")
						.foregroundColor(.secondary)
				} else {
					ForEach(settings.enabledStatsCards) { card in
						HStack(spacing: 12) {
							Image(systemName: card.sfSymbol)
								.foregroundColor(.blue)
								.frame(width: 24)
							Text(card.displayName)
							Spacer()
							if card.isPro {
								Text("Pro")
									.font(.caption2)
									.fontWeight(.semibold)
									.foregroundColor(.orange)
									.padding(.horizontal, 6)
									.padding(.vertical, 2)
									.background(Color.orange.opacity(0.15))
									.clipShape(Capsule())
							}
						}
					}
					.onDelete(perform: removeCards)
					.onMove(perform: moveCards)
				}
			} header: {
				Text("Enabled Cards")
			}

			if !availableCards.isEmpty {
				Section(header: Text("Available Cards")) {
					ForEach(availableCards) { card in
						Button {
							addCard(card)
						} label: {
							HStack(spacing: 12) {
								Image(systemName: "plus.circle.fill")
									.foregroundColor(.green)
								Image(systemName: card.sfSymbol)
									.foregroundColor(.secondary)
									.frame(width: 24)
								Text(card.displayName)
									.foregroundColor(.primary)
								Spacer()
								if card.isPro {
									Text("Pro")
										.font(.caption2)
										.fontWeight(.semibold)
										.foregroundColor(.orange)
										.padding(.horizontal, 6)
										.padding(.vertical, 2)
										.background(Color.orange.opacity(0.15))
										.clipShape(Capsule())
								}
							}
						}
					}
				}
			}
		}
		.navigationTitle("Stats Cards")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			EditButton()
		}
		.sheet(isPresented: $showProUpgradeSheet) {
			ProUpgradeModalView(isPresented: $showProUpgradeSheet)
		}
	}

	private func removeCards(at offsets: IndexSet) {
		settings.enabledStatsCards.remove(atOffsets: offsets)
	}

	private func moveCards(from source: IndexSet, to destination: Int) {
		settings.enabledStatsCards.move(fromOffsets: source, toOffset: destination)
	}

	private func addCard(_ card: StatsCardType) {
		if card.isPro && !store.isProUser {
			showProUpgradeSheet = true
			return
		}
		settings.enabledStatsCards.append(card)
	}
}
