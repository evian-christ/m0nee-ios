import SwiftUI
import StoreKit

@main
struct m0neeApp: App {
	@StateObject private var settings: AppSettings
	@StateObject private var store: ExpenseStore

	init() {
		let sharedSettings = AppSettings.shared
		let storeInstance = ExpenseStore()
		_settings = StateObject(wrappedValue: sharedSettings)
		_store = StateObject(wrappedValue: storeInstance)
		observeTransactionUpdates(store: storeInstance)
	}

	private func observeTransactionUpdates(store: ExpenseStore) {
		Task {
			for await result in Transaction.updates {
				switch result {
				case .verified(let transaction):
					if transaction.productID == "com.chan.monir.pro.lifetime" {
						store.productID = transaction.productID
					}
					await transaction.finish()
				case .unverified(_, _):
					break // Handle unverified transactions silently
				}
			}
		}
	}

		var body: some Scene {
				WindowGroup {
						RootView()
							.environmentObject(store)
							.environmentObject(settings)
				}
		}
}

struct RootView: View {
	@State private var showMain = false

	@EnvironmentObject var store: ExpenseStore
	@EnvironmentObject var settings: AppSettings

	var body: some View {
		ZStack {
			if showMain || settings.hasSeenTutorial {
				ContentView()
					.transition(.opacity)
			} else {
				TutorialView()
					.transition(.opacity)
			}
		}
		.animation(.easeInOut, value: showMain || settings.hasSeenTutorial)
		.onAppear {
			if settings.hasSeenTutorial {
				showMain = true
			}
		}
		.environmentObject(store)
	}
}
