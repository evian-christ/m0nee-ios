import SwiftUI
import StoreKit

struct ProUpgradeModalView: View {
	@Binding var isPresented: Bool
	@Environment(\.dismiss) private var dismiss
	@State private var products: [Product] = []

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

							VStack(spacing: 24) {
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
															.background(Color(.systemGray3))
															.foregroundColor(.primary)
															.cornerRadius(12)
											}

											Text("Plan auto-renews for \(monthly.displayPrice)/month until cancelled.")
													.font(.footnote)
													.foregroundColor(.secondary)
									} else {
											ProgressView("Loading subscription...")
													.frame(maxWidth: .infinity)
													.padding()
									}

									if let lifetime = products.first(where: { $0.id == "com.chan.monir.pro.lifetime" }) {
											Button(action: {
													Task {
															do {
																	let result = try await lifetime.purchase()
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
													Text("Buy Lifetime – \(lifetime.displayPrice)")
															.fontWeight(.semibold)
															.frame(maxWidth: .infinity)
															.padding()
															.background(Color(.systemGray3))
															.foregroundColor(.primary)
															.cornerRadius(12)
											}

											Text("Pay once, use forever")
													.font(.footnote)
													.foregroundColor(.secondary)
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
						products = try await Product.products(for: ["com.chan.monir.pro.monthly", "com.chan.monir.pro.lifetime"])
						print("✅ Products loaded: \(products.map { $0.id })")
					} catch {
						print("❌ Failed to load products: \(error.localizedDescription)")
					}
				}
			}
	}
}
