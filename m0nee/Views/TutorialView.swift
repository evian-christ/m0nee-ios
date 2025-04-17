import SwiftUI

struct BudgetSetupView: View {
		var body: some View {
				Text("Budget Setup")
		}
}

struct TutorialView: View {
	@AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
	@State private var page: Int = 0
	@State private var imageOffset: CGFloat = 0
	@State private var didBounce = false

	let imageGroups: [[String]] = [
		["expense_1", "expense_2"],       // Pages 0: Expenses
		["budget_1", "budget_2", "budget_3"], // Pages 1: Budgets
		["insight_1", "insight_2", "insight_3"] // Pages 2: Insights
		, [] // final page with no image
	]

	func titleForPage(_ page: Int) -> String {
		switch page {
		case 0:
			return "💸 Quickly record your expenses"
		case 1:
			return "📊 Set your budgets"
		case 2:
			return "📈 Explore insights"
		default:
			return "Ready to get started?"
		}
	}

	var body: some View {
		NavigationView {
			ZStack(alignment: .bottom) {
				VStack(spacing: 20) {
					ZStack {
						if page == 0 {
							VStack(spacing: 8) {
								Text("💸 Record your expenses")
								Text("A few taps are all it takes to log your spending.")
									.font(.footnote)
									.foregroundColor(.gray)
							}
							.transition(.opacity.combined(with: .move(edge: .top)))
						} else if page == 1 {
							VStack(spacing: 8) {
								Text("📊 Set your budgets")
								Text("Manage your money with monthly or category-specific budgets.")
									.font(.footnote)
									.foregroundColor(.gray)
							}
							.transition(.opacity.combined(with: .move(edge: .top)))
						} else if page == 2 {
							VStack(spacing: 8) {
								Text("📈 Explore insights")
								Text("Long-press a card to add it to your main screen.")
									.font(.footnote)
									.foregroundColor(.gray)
							}
							.transition(.opacity.combined(with: .move(edge: .top)))
						} else {
							VStack(spacing: 8) {
								Text("⚙️ Let’s set you up")
								Text("Configure your currency, categories, and budget to get started.")
									.font(.footnote)
									.foregroundColor(.gray)
							}
							.transition(.opacity.combined(with: .move(edge: .top)))
						}
					}
					.font(.title2.weight(.semibold))
					.bold()
					.multilineTextAlignment(.center)
					.animation(.easeInOut(duration: 0.3), value: page)

					if page == imageGroups.count - 1 {
						VStack(spacing: 0) {
							Spacer().frame(height: 12)
							Divider()
							NavigationLink(destination: BudgetSetupView()) {
								HStack {
									Text("1. Budget Tracking")
										.foregroundColor(.primary)
									Spacer()
									Image(systemName: "chevron.right")
										.foregroundColor(.gray)
								}
								.padding(.horizontal)
								.frame(height: 44)
								.background(Color(UIColor.secondarySystemGroupedBackground))
							}
							Divider()
						}
						.cornerRadius(10)
						.padding(.horizontal)
					}

					Spacer()
				}
				.padding(.top, 84)
				.padding(.horizontal)

				TabView(selection: $page) {
					ForEach(imageGroups.indices, id: \.self) { groupIndex in
						VStack {
							Spacer()
							TabView {
								ForEach(imageGroups[groupIndex], id: \.self) { imageName in
									if UIImage(named: imageName) != nil {
										VStack {
											Spacer()
											Image(imageName)
												.resizable()
												.scaledToFit()
												.frame(height: 1000)
												.padding(.top, 200)
										}
									}
								}
							}
							.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
							.offset(x: imageOffset)
						}
						.tag(groupIndex)
					}
				}
				.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
				.frame(height: 600)
				.padding(.bottom, -50)
			}
			.ignoresSafeArea(edges: .bottom)
			.onAppear {
				guard !didBounce else { return }
				didBounce = true
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
					withAnimation(.easeInOut(duration: 0.2)) {
						imageOffset = -40
					}
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
						withAnimation(.easeInOut(duration: 0.2)) {
							imageOffset = 0
						}
					}
				}
			}
			.onChange(of: page) { _ in }
		}
		.navigationViewStyle(.stack)
	}
}
