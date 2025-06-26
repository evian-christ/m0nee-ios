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
	@State private var showCancelSubscriptionAlert = false

	var body: some View {
			ScrollView {
					VStack(spacing: 24) {
							Text("Upgrade to Monir Pro")
									.font(.title.bold())

							Text("Unlock powerful features to manage your money better.")
									.font(.body)
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
							.padding(.horizontal, 32)
							.frame(maxWidth: .infinity, alignment: .leading)

							Spacer().frame(height: 16)

							VStack(spacing: 24) {
									if let monthly = products.first(where: { $0.id == "com.chan.monir.pro.monthly" }) {
											VStack(spacing: 4) {
													Button(action: {
															Task {
																	do {
																			let result = try await monthly.purchase()
																			switch result {
																			case .success(let verification):
																					switch verification {
																					case .verified(_):
																							UserDefaults.standard.set(true, forKey: "isProUser")
																										NotificationCenter.default.post(name: .didUpgradeToPro, object: nil)
																							if currentProductID == "com.chan.monir.pro.monthly" {
																								showCancelSubscriptionAlert = true
																							} else {
																								isPresented = false
																								dismiss()
																							}
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
														Text(currentProductID == "com.chan.monir.pro.monthly" ? "Already Subscribed" : "Subscribe – \(monthly.displayPrice) / month")
																.fontWeight(.semibold)
																.frame(maxWidth: .infinity)
																.padding()
																.background(currentProductID == "com.chan.monir.pro.monthly" ? Color(.systemGray4) : Color(.systemGray5))
																.foregroundColor(.primary)
																.cornerRadius(12)
													}
													.disabled(currentProductID == "com.chan.monir.pro.monthly")

													Text("This is a 1-month auto-renewed subscription for \(monthly.displayPrice)/month until cancelled.")
															.font(.footnote)
															.foregroundColor(.secondary)
											}
									} else {
											ProgressView("Loading subscription...")
													.frame(maxWidth: .infinity)
													.padding()
									}

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
																							UserDefaults.standard.set(true, forKey: "isProUser")
																										NotificationCenter.default.post(name: .didUpgradeToPro, object: nil)

																							// Re-check entitlements for a monthly subscription
																							var hasMonthly = false
																							for await result in Transaction.currentEntitlements {
																									if case .verified(let transaction) = result,
																										 transaction.productID == "com.chan.monir.pro.monthly" {
																											hasMonthly = true
																											break
																									}
																							}

																							if hasMonthly {
																									showCancelSubscriptionAlert = true
																							} else {
																									isPresented = false
																									dismiss()
																							}
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
																	.frame(maxWidth: .infinity)
																	.padding()
																	.background(Color(.systemGray5))
																	.foregroundColor(.primary)
																	.cornerRadius(12)
													}
													.disabled(currentProductID == "com.chan.monir.pro.lifetime")

													Text("Pay once, use forever")
															.font(.footnote)
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
					.padding(.horizontal)
					.padding(.top, 48)
					.padding(.vertical, 32)
			}
			.alert("Cancel your monthly subscription", isPresented: $showCancelSubscriptionAlert) {
				Button("Open App Store") {
					if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
						UIApplication.shared.open(url)
					}
				}
				Button("Close", role: .cancel) {
					isPresented = false
					dismiss()
				}
			} message: {
				Text("You’ve purchased a lifetime plan. Please cancel your monthly subscription in the App Store to avoid being charged again.")
			}
			.onAppear {
				Task {
					do {
						print("🌐 Fetching products from App Store...")
						products = try await Product.products(for: ["com.chan.monir.pro.monthly", "com.chan.monir.pro.lifetime"])
						print("✅ Products loaded: \(products.map { $0.id })")

						for await result in Transaction.currentEntitlements {
							if case .verified(let transaction) = result {
								if ["com.chan.monir.pro.monthly", "com.chan.monir.pro.lifetime"].contains(transaction.productID) {
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
 
