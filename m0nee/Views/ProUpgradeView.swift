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