import SwiftUI

struct BudgetSetupView: View {
	@AppStorage("useBudgetFeature") private var useBudgetFeature: Bool = true
	@Environment(\.dismiss) var dismiss
	var onComplete: ((Bool) -> Void)? = nil

	var body: some View {
		Form {
			Section {
				VStack(alignment: .leading, spacing: 12) {
					Text("📊 Budget Tracking")
						.font(.title3.bold())

					Text("Set a spending limit to stay in control.\nYou can pick how often later.")
						.font(.subheadline)
						.foregroundColor(.gray)
				}
				.padding(.vertical, 8)
			}

			Section {
				Button {
					useBudgetFeature = true
					onComplete?(true)
					dismiss()
				} label: {
					HStack {
						Text("Use Budget Tracking")
						if useBudgetFeature {
							Spacer()
							Image(systemName: "checkmark")
								.foregroundColor(.accentColor)
						}
					}
				}

				Button {
					useBudgetFeature = false
					onComplete?(false)
					dismiss()
				} label: {
					HStack {
						Text("Don't Use Budget Tracking")
						if !useBudgetFeature {
							Spacer()
							Image(systemName: "checkmark")
								.foregroundColor(.accentColor)
						}
					}
				}
			}
		}
		.navigationTitle("Initial settings")
		.onDisappear {
			onComplete?(useBudgetFeature)
		}
	}
}

struct BudgetAmountSetupView: View {
	@AppStorage("monthlyBudget", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var budgetAmount: Int = 0
	@Environment(\.dismiss) var dismiss
	@Environment(\.colorScheme) var scheme
	var onComplete: (() -> Void)? = nil

	@State private var amountText: String = ""

	var body: some View {
		Form {
			Section {
				VStack(alignment: .leading, spacing: 12) {
					Text("💰 Budget Amount")
						.font(.title3.bold())

					Text("Set how much you can spend during the selected period.")
						.font(.subheadline)
						.foregroundColor(.gray)
				}
				.padding(.vertical, 8)
			}

			Section {
				TextField("Enter amount", text: $amountText)
					.keyboardType(.numberPad)
					.font(.system(size: 28, weight: .bold))
					.padding(.horizontal, 4)
					.padding(.vertical, 10)
					.background(scheme == .light ? Color.white : Color(.secondarySystemBackground))
					.cornerRadius(10)

				Button("Save") {
					if let amount = Int(amountText.filter { $0.isNumber }) {
						budgetAmount = amount
						onComplete?()
						dismiss()
					}
				}
			}
		}
		.onAppear {
			amountText = String(budgetAmount)
		}
		.navigationTitle("Initial settings")
	}
	
}

struct BudgetPeriodSetupView: View {
	@AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
	@Environment(\.dismiss) var dismiss
	var onComplete: (() -> Void)? = nil

	var body: some View {
		Form {
			Section {
				VStack(alignment: .leading, spacing: 12) {
					Text("🗓️ Budget Period")
						.font(.title3.bold())

					Text("Choose how often your budget resets.")
						.font(.subheadline)
						.foregroundColor(.gray)
				}
				.padding(.vertical, 8)
			}

			Section {
				Button {
					budgetPeriod = "Monthly"
					onComplete?()
					dismiss()
				} label: {
					HStack {
						Text("Monthly")
						if budgetPeriod == "Monthly" {
							Spacer()
							Image(systemName: "checkmark")
								.foregroundColor(.accentColor)
						}
					}
				}

				Button {
					budgetPeriod = "Weekly"
					onComplete?()
					dismiss()
				} label: {
					HStack {
						Text("Weekly")
						if budgetPeriod == "Weekly" {
							Spacer()
							Image(systemName: "checkmark")
								.foregroundColor(.accentColor)
						}
					}
				}
			}
		}
		.navigationTitle("Initial settings")
		.onDisappear {
			onComplete?()
		}
	}
}

struct RatingToggleSetupView: View {
	@AppStorage("showRating") private var showRating: Bool = true
	@Environment(\.presentationMode) var presentationMode
	var onComplete: (() -> Void)? = nil

	var body: some View {
		Form {
			Section {
				VStack(alignment: .leading, spacing: 12) {
					Text("⭐️ Enable Rating")
						.font(.title3.bold())

					Text("Choose whether to rate your expenses (1–5 stars) for later insights.")
						.font(.subheadline)
						.foregroundColor(.gray)
				}
				.padding(.vertical, 8)
			}

			Section {
				Button {
					showRating = true
					presentationMode.wrappedValue.dismiss()
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
						onComplete?()
					}
				} label: {
					HStack {
						Text("Use Ratings")
						if showRating {
							Spacer()
							Image(systemName: "checkmark")
								.foregroundColor(.accentColor)
						}
					}
				}

				Button {
					showRating = false
					presentationMode.wrappedValue.dismiss()
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
						onComplete?()
					}
				} label: {
					HStack {
						Text("Don't Use Ratings")
						if !showRating {
							Spacer()
							Image(systemName: "checkmark")
								.foregroundColor(.accentColor)
						}
					}
				}
			}
		}
		.navigationTitle("Initial settings")
		.onDisappear {
			onComplete?()
		}
	}
}

struct TutorialView: View {
	@AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
	@AppStorage("enableBudgetTracking", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var budgetEnabled: Bool = true
	@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
	@State private var page: Int = 0
	@State private var imageOffset: CGFloat = 0
	@State private var didBounce = false
	@State private var showBudgetPeriodLink: Bool = false
	@State private var enableBudgetPeriod = false
	@State private var enableBudgetAmount = false
	@State private var enableRating = false
	@State private var budgetTrackingDisabled = false
	@State private var showFinalSetupForm = false
	@State private var showStartButton = false
	@State private var isExitingTutorial = false

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
			ZStack(alignment: .topTrailing) {
				ZStack(alignment: .bottom) {
					Color(.systemBackground)
						.ignoresSafeArea()
					if !isExitingTutorial {
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
														.padding(.top, 240)
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
						.frame(height: 640)
						.padding(.bottom, -50)
						.zIndex(0)

						VStack(spacing: 20) {
							ZStack {
								if page == 0 {
									VStack(spacing: 8) {
										Text("Record your expenses")
										Text("A few taps are all it takes to log your spending.")
											.font(.footnote)
											.foregroundColor(.gray)
									}
									.transition(.opacity.combined(with: .move(edge: .top)))
								} else if page == 1 {
									VStack(spacing: 8) {
										Text("Set your budgets")
										Text("Manage your money with monthly or category-specific budgets.")
											.font(.footnote)
											.foregroundColor(.gray)
									}
									.transition(.opacity.combined(with: .move(edge: .top)))
								} else if page == 2 {
									VStack(spacing: 8) {
										Text("Explore insights")
										Text("Long-press a card to add it to your main screen.")
											.font(.footnote)
											.foregroundColor(.gray)
									}
									.transition(.opacity.combined(with: .move(edge: .top)))
								} else {
									VStack(spacing: 8) {
										Text("Let’s set you up")
										Text("Configure your budget to get started.")
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

							Spacer().frame(height: 24)

							if showFinalSetupForm {
								ZStack {
									Color(.systemBackground)
										.ignoresSafeArea()

									List {
										Section {
											NavigationLink(destination: BudgetSetupView(onComplete: { isEnabled in
												budgetEnabled = isEnabled
												enableBudgetPeriod = isEnabled
												enableBudgetAmount = false
												enableRating = !isEnabled
												budgetTrackingDisabled = !isEnabled
											})) {
												Text("📊  Budget Tracking")
													.frame(height: 52)
											}

											if enableBudgetPeriod {
												NavigationLink(destination: BudgetPeriodSetupView(onComplete: {
													enableBudgetAmount = true
												})) {
													Text("🗓️  Budget Period")
														.frame(height: 52)
												}
											} else {
												HStack {
													Text("🗓️  Budget Period")
														.strikethrough(budgetTrackingDisabled)
														.foregroundColor(.gray)
														.frame(height: 52)
												}
											}

											if enableBudgetAmount {
												NavigationLink(destination: BudgetAmountSetupView(onComplete: {
													enableRating = true
												})) {
													Text("💰  Budget Amount")
														.frame(height: 52)
												}
											} else {
												HStack {
													Text("💰  Budget Amount")
														.strikethrough(budgetTrackingDisabled)
														.foregroundColor(.gray)
														.frame(height: 52)
												}
											}

											if enableRating {
												NavigationLink(destination: RatingToggleSetupView(onComplete: {
													withAnimation {
														showStartButton = true
													}
												})) {
													Text("⭐️  Enable Rating")
														.frame(height: 52)
												}
											} else {
												HStack {
													Text("⭐️  Enable Rating")
														.foregroundColor(.gray)
														.frame(height: 52)
												}
											}
										}
									}
									.scrollDisabled(true)
									.listStyle(.plain)
									.background(Color(.systemBackground))
								}
							}

							if showStartButton {
								Button(action: {
									withAnimation(.easeInOut(duration: 0.5)) {
										isExitingTutorial = true
									}
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
										hasSeenTutorial = true
									}
								}) {
									Text("Start using Monir")
										.font(.headline)
										.frame(maxWidth: .infinity)
										.padding()
										.background(Color.accentColor)
										.foregroundColor(.white)
										.cornerRadius(12)
										.padding(.horizontal)
								}
								.transition(.move(edge: .bottom).combined(with: .opacity))
								.padding(.bottom, 40)
							}

							Spacer()
						}
						.padding(.top, 84)
						.padding(.horizontal)
						.zIndex(1)
					}
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
				.onChange(of: page) { newPage in
					if newPage == imageGroups.count - 1 {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
							withAnimation {
								showFinalSetupForm = true
							}
						}
					} else {
						showFinalSetupForm = false
					}
				}
				Button("Skip") {
					hasSeenTutorial = true
				}
				.padding()
				.font(.callout.weight(.semibold))
			}
			.navigationViewStyle(.stack)
			.preferredColorScheme(
					appearanceMode == "Light" ? .light :
					appearanceMode == "Dark" ? .dark : nil
			)
		}
	}
}
 	
