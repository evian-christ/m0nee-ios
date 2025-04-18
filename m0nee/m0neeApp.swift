//
//  m0neeApp.swift
//  m0nee
//
//  Created by Chan on 02/04/2025.
//

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
												withAnimation(.easeInOut(duration: 0.5)) {
														showMain = true
												}
										}
						} else {
								TutorialView()
										.transition(.opacity)
						}
				}
				.animation(.easeInOut(duration: 0.5), value: showMain)
		}
}
