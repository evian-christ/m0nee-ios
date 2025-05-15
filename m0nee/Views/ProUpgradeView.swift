import SwiftUI
import StoreKit

struct ProUpgradeModalView: View {
	@Binding var isPresented: Bool
	@Environment(\.dismiss) private var dismiss
	@State private var products: [Product] = []

	var body: some View {
			ScrollView {
					VStack(spacing: 24) {
							Spacer().frame(height: 32)

							Image(systemName: "star.circle.fill")
									.font(.system(size: 48))
									.foregroundColor(.yellow)

							Text("Upgrade to Monir Pro")
									.font(.title.bold())

							Text("Unlock powerful features to manage your money better.")
									.font(.body)
									.foregroundColor(.secondary)
									.multilineTextAlignment(.center)
									.lineSpacing(2)
									.padding(.horizontal)

							VStack(alignment: .leading, spacing: 12) {
									HStack(spacing: 8) {
											Image(systemName: "checkmark.circle.fill")
													.foregroundColor(.green)
											Text("Recurring expense feature")
									}
									HStack(spacing: 8) {
											Image(systemName: "checkmark.circle.fill")
													.foregroundColor(.green)
											Text("Advanced insight cards")
									}
									HStack(spacing: 8) {
											Image(systemName: "checkmark.circle.fill")
													.foregroundColor(.green)
											Text("Export & import feature")
									}
							}
							.padding(.top, 12)
							.padding(.bottom, 20)
							.font(.subheadline)
							.foregroundColor(.secondary)
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.horizontal, 32)

							VStack(spacing: 16) {
									if let monthly = products.first(where: { $0.id == "com.chan.monir.pro.monthly" }) {
											Button(action: {
													Task {
															do {
																	let result = try await monthly.purchase()
																	switch result {
																	case .success(let verification):
																			switch verification {
																			case .verified(_):
																					UserDefaults.standard.set(true, forKey: "isProUser")
																					isPresented = false
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
													Text("Subscribe – \(monthly.displayPrice) / month")
															.fontWeight(.semibold)
															.frame(maxWidth: .infinity)
															.padding()
															.background(Color.accentColor)
															.foregroundColor(.white)
															.cornerRadius(12)
											}
									} else {
											ProgressView("Loading subscription...")
													.frame(maxWidth: .infinity)
													.padding()
									}

									Button(action: {}) {
											Text("Buy Lifetime – £19.99")
													.fontWeight(.semibold)
													.frame(maxWidth: .infinity)
													.padding()
													.background(Color.gray.opacity(0.2))
													.foregroundColor(.primary)
													.cornerRadius(12)
									}
									.disabled(true)
							}
							.padding(.horizontal)

							
					}
					.padding(.horizontal)
			}
			.onAppear {
				Task {
					do {
						products = try await Product.products(for: ["com.chan.monir.pro.monthly"])
					} catch {
						print("❌ Failed to load products: \(error)")
					}
				}
			}
	}
}
