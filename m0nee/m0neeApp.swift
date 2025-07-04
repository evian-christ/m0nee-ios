import SwiftUI
import StoreKit

@main
struct m0neeApp: App {
		let persistenceController = PersistenceController.shared
		let store = ExpenseStore()

		init() {
				observeTransactionUpdates()
		}

		private func observeTransactionUpdates() {
				Task.detached {
						for await result in Transaction.updates {
								switch result {
								case .verified(let transaction):
										print("✅ Transaction update received: \(transaction.productID)")
										if transaction.productID == "com.chan.monir.pro.monthly" ||
											 transaction.productID == "com.chan.monir.pro.lifetime" {
												store.productID = transaction.productID
										}
										await transaction.finish()
								case .unverified(let transaction, let error):
										print("❌ Unverified transaction: \(transaction.productID), error: \(error.localizedDescription)")
								}
						}
				}
		}

		var body: some Scene {
				WindowGroup {
						RootView()
								.environment(\.managedObjectContext, persistenceController.container.viewContext)
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
						if showMain {
								ContentView()
										.transition(.opacity)
						} else if hasSeenTutorial {
								Color.primary
										.ignoresSafeArea()
										.transition(.opacity)
										.onAppear {
												showMain = true
										}
						} else {
								TutorialView()
										.transition(.opacity)
						}
				}
				.environmentObject(store)
		}
}
