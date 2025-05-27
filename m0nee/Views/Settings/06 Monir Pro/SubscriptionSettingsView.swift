import SwiftUI
import Foundation
import StoreKit

struct SubscriptionSettingsView: View {
		@AppStorage("isProUser") var isProUser: Bool = false
		@State private var productID: String?
		@State private var showUpgradeModal = false

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
				Form {
						Section {
								HStack {
										Text("Current Plan")
										Spacer()
										Text(subscriptionLabel)
												.foregroundColor(.secondary)
								}
								
								if productID != "com.chan.monir.pro.lifetime" {
										Button("Upgrade Plan") {
												showUpgradeModal = true
										}
								}
						}
						if productID == "com.chan.monir.pro.monthly" {
								Section {
										Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
								}
						}
						Section {
								Button("Restore Purchase") {
										Task {
												do {
														try await AppStore.sync()
														print("🔁 Purchase restored")
												} catch {
														print("❌ Restore failed: \(error)")
												}
										}
								}
						}
				}
				.navigationBarTitleDisplayMode(.inline)
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
				.sheet(isPresented: $showUpgradeModal, onDismiss: {
						Task {
								do {
										var foundEntitlement = false
										for await result in Transaction.currentEntitlements {
												if case .verified(let transaction) = result,
													 ["com.chan.monir.pro.monthly", "com.chan.monir.pro.lifetime"].contains(transaction.productID) {
														productID = transaction.productID
														foundEntitlement = true
														break
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
				}) {
						ProUpgradeModalView(isPresented: $showUpgradeModal)
				}
				.onReceive(NotificationCenter.default.publisher(for: .didUpgradeToPro)) { _ in
						Task {
								do {
										var foundEntitlement = false
										for await result in Transaction.currentEntitlements {
												if case .verified(let transaction) = result,
													 ["com.chan.monir.pro.monthly", "com.chan.monir.pro.lifetime"].contains(transaction.productID) {
														productID = transaction.productID
														foundEntitlement = true
														break
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
