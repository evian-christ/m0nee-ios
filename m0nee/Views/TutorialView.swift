import SwiftUI

struct TutorialView: View {
	@EnvironmentObject var settings: AppSettings
	@State private var page: Int = 0
	@State private var showSwipeHint = true
	@State private var arrowAnimation = false
	@Environment(\.dismiss) private var dismiss

	// Simplified to one image per page
	let images: [String] = ["expense_1", "budget_1", "insight_1"]

	let titles: [LocalizedStringKey] = [
		"tutorial_title_1",
		"tutorial_title_2",
		"tutorial_title_3",
		"tutorial_title_4",
	]

	let subtitles: [LocalizedStringKey] = [
		"tutorial_subtitle_1",
		"tutorial_subtitle_2",
		"tutorial_subtitle_3",
		"tutorial_subtitle_4",
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
									settings.hasSeenTutorial = true
									withAnimation(.easeInOut) {
										dismiss()
									}
								}) {
																		Text(LocalizedStringKey("get_started_button"))
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
				.onChange(of: page) { _ in
					showSwipeHint = false
				}

				// Swipe hint overlay
				if showSwipeHint && page < titles.count - 1 {
					VStack {
						Spacer().frame(height: 120)
						
						HStack {
							Spacer()
							Image(systemName: "arrow.right")
								.font(.title2)
								.foregroundColor(.primary)
								.opacity(0.6)
								.padding(12)
								.background(Circle().fill(.regularMaterial).opacity(0.8))
								.offset(x: arrowAnimation ? 8 : 0)
								.animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: arrowAnimation)
								.onAppear {
									DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
										arrowAnimation = true
									}
								}
							Spacer().frame(width: 40)
						}
						
						Spacer()
					}
				}

				// Content overlay: Button (if needed) can be re-added here if desired
			}
		}
		.preferredColorScheme(
			settings.appearanceMode == "Light" ? .light :
			settings.appearanceMode == "Dark" ? .dark : nil
	)
	}
}
