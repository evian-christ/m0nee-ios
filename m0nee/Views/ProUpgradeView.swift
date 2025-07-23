extension Notification.Name {
		static let didUpgradeToPro = Notification.Name("didUpgradeToPro")
}

import SwiftUI
import StoreKit

struct ProUpgradeModalView: View {
	@Binding var isPresented: Bool
	@Environment(\.dismiss) private var dismiss
	@State private var products: [Product] = []
	@State private var currentProductID: String?
	
	@EnvironmentObject var expenseStore: ExpenseStore

	var body: some View {
		VStack {
			VStack(spacing: 16) {
				Spacer().frame(height: 32)
				ScrollView {
					VStack(spacing: 32) {
						Text("Upgrade to Monir Pro")
							.font(.title.bold())
							.padding(.top, 16)

						Text("Unlock powerful features to manage your money better.")
							.font(.title3)
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)
							.padding(.horizontal)
						Spacer().frame(height: 0)

						VStack(alignment: .leading, spacing: 16) {
							HStack(spacing: 8) {
								Image(systemName: "arrow.triangle.2.circlepath")
									.foregroundColor(.accentColor)
								Text("Recurring expense feature")
							}
							HStack(spacing: 8) {
								Image(systemName: "chart.xyaxis.line")
									.foregroundColor(.accentColor)
								Text("Advanced insight cards")
							}
							HStack(spacing: 8) {
								Image(systemName: "square.and.arrow.up")
									.foregroundColor(.accentColor)
								Text("Export & import feature")
							}
							HStack(spacing: 8) {
								Image(systemName: "person.2")
									.foregroundColor(.accentColor)
								Text("Family Sharing")
							}
						}
						.font(.body)
						.padding(.horizontal, 32)
						.frame(maxWidth: .infinity, alignment: .leading)

						Divider()
						
						VStack(spacing: 24) {
							

							if let lifetime = products.first(where: { $0.id == "com.chan.monir.pro.lifetime" }) {
								VStack(spacing: 4) {
									Button(action: {
										Task {
											do {
												let result = try await lifetime.purchase()
												switch result {
												case .success(let verification):
													switch verification {
													case .verified(_):
														expenseStore.productID = lifetime.id
														UserDefaults.standard.set(true, forKey: "isProUser")
														NotificationCenter.default.post(name: .didUpgradeToPro, object: nil)
														isPresented = false
														dismiss()
													case .unverified(_, _):
														print("🔒 Unverified purchase.")
													}
												default:
													break
												}
											} catch {
												print("❌ Purchase error: \(error)")
											}
										}
									}) {
										Text("Buy Lifetime – \(lifetime.displayPrice)")
											.fontWeight(.semibold)
											.font(.body)
											.frame(maxWidth: .infinity)
											.padding()
											.background(
												RoundedRectangle(cornerRadius: 12)
													.fill(Color.accentColor.opacity(0.15))
											)
											.foregroundColor(.accentColor)
											.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
									}
									.disabled(currentProductID == "com.chan.monir.pro.lifetime")

									Text("Pay once, use forever")
										.font(.callout)
										.foregroundColor(.secondary)
								}
							} else {
								ProgressView("Loading lifetime option...")
									.frame(maxWidth: .infinity)
									.padding()
							}
						}
						.padding(.horizontal)
					}
					.padding()
					.background(Color(.systemGroupedBackground))
					.cornerRadius(20)
				}
				.padding(.horizontal)
				.padding(.top, 48)
				.padding(.vertical, 32)
			}
		}
		.frame(maxHeight: .infinity)
		.background(Color(.systemGroupedBackground).ignoresSafeArea())
		
		.onAppear {
			Task {
				do {
					print("🌐 Fetching products from App Store...")
					products = try await Product.products(for: ["com.chan.monir.pro.lifetime"])
					print("✅ Products loaded: \(products.map { $0.id })")

					for await result in Transaction.currentEntitlements {
						if case .verified(let transaction) = result {
							if transaction.productID == "com.chan.monir.pro.lifetime" {
								currentProductID = transaction.productID
								break
							}
						}
					}
				} catch {
					print("❌ Failed to load products or entitlements: \(error.localizedDescription)")
				}
			}
		}
	}
}
