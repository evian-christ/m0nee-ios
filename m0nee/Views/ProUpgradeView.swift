import SwiftUI
import StoreKit

struct ProUpgradeModalView: View {
	@Binding var isPresented: Bool
	@Environment(\.dismiss) private var dismiss
	@Environment(\.colorScheme) private var colorScheme
	@State private var products: [Product] = []
	@State private var currentProductID: String?

	@EnvironmentObject var expenseStore: ExpenseStore

	var body: some View {
		NavigationView {
			GeometryReader { geometry in
				ZStack {
					Color(.systemGroupedBackground)
						.ignoresSafeArea()

					VStack(spacing: 0) {
						Spacer(minLength: 20)

						// Header with App Icon
						VStack(spacing: 12) {
							ZStack(alignment: .topTrailing) {
								// App Icon
								Image("AppIconImage")
									.resizable()
									.frame(width: 90, height: 90)
									.cornerRadius(20)
									.shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)

								// Pro Badge
								ZStack {
									Circle()
										.fill(
											LinearGradient(
												colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
												startPoint: .topLeading,
												endPoint: .bottomTrailing
											)
										)
										.frame(width: 30, height: 30)
										.shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)

									Text("PRO")
										.font(.system(size: 9, weight: .bold))
										.foregroundColor(.white)
								}
								.offset(x: 6, y: -6)
							}

							Text("Monir Pro")
								.font(.system(size: 26, weight: .bold))

							Text("Unlock the full potential of your expense tracking")
								.font(.system(size: 15))
								.foregroundColor(.secondary)
								.multilineTextAlignment(.center)
								.fixedSize(horizontal: false, vertical: true)
						}
						.padding(.horizontal, 40)

						Spacer(minLength: 20)

						// Features Card
						VStack(spacing: 0) {
							featureItem(
								icon: "arrow.triangle.2.circlepath",
								title: "Recurring Expenses",
								description: "Automate recurring bills",
								gradient: [Color.blue, Color.cyan]
							)

							Divider()
								.padding(.leading, 60)

							featureItem(
								icon: "square.and.arrow.up",
								title: "Export & Import",
								description: "Backup and transfer data",
								gradient: [Color.green, Color.mint]
							)

							Divider()
								.padding(.leading, 60)

							featureItem(
								icon: "person.2",
								title: "Family Sharing",
								description: "Share with up to 5 members",
								gradient: [Color.purple, Color.pink]
							)
						}
						.background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
						.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
						.padding(.horizontal, 24)

						Spacer(minLength: 20)

						// Purchase Section
						VStack(spacing: 12) {
							if let lifetime = products.first(where: { $0.id == "com.chan.monir.pro.lifetime" }) {
								// Price
								VStack(spacing: 4) {
									Text("Lifetime Access")
										.font(.system(size: 13, weight: .semibold))
										.foregroundColor(.secondary)

									Text(lifetime.displayPrice)
										.font(.system(size: 44, weight: .bold))
										.foregroundColor(.primary)

									Text("One-time payment")
										.font(.system(size: 12))
										.foregroundColor(.secondary)
								}
								.padding(.bottom, 4)

								// Purchase Button
								Button(action: {
									Task {
										do {
											let result = try await lifetime.purchase()
											switch result {
											case .success(let verification):
												switch verification {
												case .verified(_):
													expenseStore.productID = lifetime.id
													isPresented = false
													dismiss()
												case .unverified(_, _):
													break
												}
											default:
												break
											}
										} catch {
											// Purchase error
										}
									}
								}) {
									Text("Continue")
										.font(.system(size: 17, weight: .semibold))
										.foregroundColor(.white)
										.frame(maxWidth: .infinity)
										.padding(.vertical, 16)
										.background(
											RoundedRectangle(cornerRadius: 14, style: .continuous)
												.fill(Color.accentColor)
										)
								}
								.disabled(currentProductID == "com.chan.monir.pro.lifetime")

								Text("Pay once, own forever across all your devices")
									.font(.system(size: 12))
									.foregroundColor(.secondary)
									.multilineTextAlignment(.center)
							} else {
								VStack(spacing: 12) {
									ProgressView()
									Text("Loading...")
										.font(.system(size: 15))
										.foregroundColor(.secondary)
								}
								.frame(maxWidth: .infinity)
								.padding(.vertical, 30)
							}
						}
						.padding(.horizontal, 32)

						Spacer(minLength: 24)
					}
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button {
						dismiss()
					} label: {
						ZStack {
							Circle()
								.fill(Color.secondary.opacity(0.15))
								.frame(width: 30, height: 30)
							Image(systemName: "xmark")
								.font(.system(size: 12, weight: .semibold))
								.foregroundColor(.secondary)
						}
					}
				}
			}
			.onAppear {
				Task {
					do {
						products = try await Product.products(for: ["com.chan.monir.pro.lifetime"])

						for await result in Transaction.currentEntitlements {
							if case .verified(let transaction) = result {
								if transaction.productID == "com.chan.monir.pro.lifetime" {
									currentProductID = transaction.productID
									break
								}
							}
						}
					} catch {
						// Failed to load products or entitlements
					}
				}
			}
		}
	}

	private func featureItem(icon: String, title: String, description: String, gradient: [Color]) -> some View {
		HStack(spacing: 14) {
			// Icon with gradient background
			ZStack {
				RoundedRectangle(cornerRadius: 10, style: .continuous)
					.fill(
						LinearGradient(
							colors: gradient,
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: 48, height: 48)
					.shadow(color: gradient[0].opacity(0.25), radius: 6, x: 0, y: 3)

				Image(systemName: icon)
					.font(.system(size: 20, weight: .medium))
					.foregroundColor(.white)
			}

			VStack(alignment: .leading, spacing: 3) {
				Text(title)
					.font(.system(size: 16, weight: .semibold))
					.foregroundColor(.primary)
				Text(description)
					.font(.system(size: 13))
					.foregroundColor(.secondary)
					.fixedSize(horizontal: false, vertical: true)
			}

			Spacer(minLength: 0)
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 14)
	}
}
