import SwiftUI
import StoreKit

@main
struct m0neeApp: App {
		let store = ExpenseStore()

		init() {
				observeTransactionUpdates()
		}

		private func observeTransactionUpdates() {
				Task.detached {
						for await result in Transaction.updates {
								switch result {
								case .verified(let transaction):
										if transaction.productID == "com.chan.monir.pro.lifetime" {
												store.productID = transaction.productID
										}
										await transaction.finish()
								case .unverified(_, _):
										// Handle unverified transactions silently
								}
						}
				}
		}

		var body: some Scene {
				WindowGroup {
						RootView()
								.environmentObject(store)
				}
		}
}

struct RootView: View {
		@AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
		@State private var showMain = false

		@EnvironmentObject var store: ExpenseStore

		var body: some View {
				ZStack {
						if showMain || hasSeenTutorial {
								ContentView()
										.transition(.opacity)
						} else {
								TutorialView()
										.transition(.opacity)
						}
				}
				.animation(.easeInOut, value: showMain || hasSeenTutorial)
				.onAppear {
						if hasSeenTutorial {
								showMain = true
						}
				}
				.environmentObject(store)
		}
}