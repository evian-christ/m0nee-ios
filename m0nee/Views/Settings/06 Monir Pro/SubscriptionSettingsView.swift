import SwiftUI
import Foundation
import StoreKit

struct SubscriptionSettingsView: View {
		@AppStorage("isProUser") var isProUser: Bool = false
		@State private var productID: String?

		private var subscriptionLabel: String {
				switch productID {
				case "com.chan.monir.pro.monthly":
						return "Monir Pro Monthly"
				case "com.chan.monir.pro.lifetime":
						return "Monir Pro Lifetime"
				case "free":
						return "Free"
				case nil:
						return "Loading..."
				default:
						return "Free"
				}
		}

		var body: some View {
				NavigationView {
						Form {
								Section {
										HStack {
												Text("Current Plan")
												Spacer()
												Text(subscriptionLabel)
														.foregroundColor(.secondary)
										}
								}
						}
						.navigationTitle("Monir Pro")
						.task {
								do {
										var foundEntitlement = false
										for await result in Transaction.currentEntitlements {
												if case .verified(let transaction) = result {
														if transaction.productID == "com.chan.monir.pro.monthly" ||
															transaction.productID == "com.chan.monir.pro.lifetime" {
																productID = transaction.productID
																foundEntitlement = true
																break
														}
												}
										}
										if !foundEntitlement {
												productID = "free"
										}
								} catch {
										print("❌ Failed to check entitlements: \(error)")
										productID = "free"
								}
						}
				}
		}
}
