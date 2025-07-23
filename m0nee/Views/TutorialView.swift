import SwiftUI

struct TutorialView: View {
	@AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
	@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
	@State private var page: Int = 0
	@Environment(\.dismiss) private var dismiss

	// Simplified to one image per page
	let images: [String] = ["expense_1", "budget_1", "insight_1"]

	let titles: [String] = [
		"Record your expenses",
		"Set your budgets",
		"Explore insights",
		"You're all set",
	]

	let subtitles: [String] = [
		"A few taps are all it takes to log your spending.",
		"Manage your money with custom budgets.",
		"Long-press a card to add it to your main screen.",
		"Start using Monir now.",
	]

	var body: some View {
		ZStack(alignment: .topTrailing) {
			ZStack(alignment: .bottom) {
				Color(.systemBackground)
					.ignoresSafeArea()

				// Main TabView for the three pages
				TabView(selection: $page) {
					ForEach(0..<titles.count, id: \.self) { index in
						VStack(spacing: 0) {
							Spacer().frame(height: 300)

						VStack(spacing: 8) {
							Text(titles[index])
								.font(.title2.weight(.semibold))
								.multilineTextAlignment(.center)
								.animation(.easeInOut(duration: 0.3), value: page)

							Text(subtitles[index])
								.font(.footnote)
								.foregroundColor(.gray)
								.multilineTextAlignment(.center)
								.padding(.horizontal)

							if index == titles.count - 1 {
								Button(action: {
									hasSeenTutorial = true
									withAnimation(.easeInOut) {
										dismiss()
									}
								}) {
									Text("Get Started")
										.font(.headline)
										.fontWeight(.semibold)
										.padding(.horizontal, 28)
										.padding(.vertical, 12)
										.background(Capsule().fill(Color.accentColor))
										.foregroundColor(.white)
										.shadow(radius: 4)
										.padding(.top, 50)
								}
							}
						}

							Spacer()

							if index < images.count {
								Image(images[index])
									.resizable()
									.scaledToFill()
									.offset(y: 100)
							}

						}
						.frame(maxWidth: .infinity, maxHeight: .infinity)
						.tag(index)
					}
				}
				.tabViewStyle(PageTabViewStyle())
				.ignoresSafeArea(.all, edges: .bottom)

				// Content overlay: Button (if needed) can be re-added here if desired
			}
		}
		.preferredColorScheme(
			appearanceMode == "Light" ? .light :
			appearanceMode == "Dark" ? .dark : nil
		)
	}
}
