import SwiftUI

@main
struct m0neeApp: App {
		let persistenceController = PersistenceController.shared
		let store = ExpenseStore()

		var body: some Scene {
				WindowGroup {
						RootView(store: store)
								.environment(\.managedObjectContext, persistenceController.container.viewContext)
				}
		}
}

struct RootView: View {
		@AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
		@State private var showMain = false

		let store: ExpenseStore

		var body: some View {
				ZStack {
						if showMain {
								ContentView(store: store)
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
		}
}
