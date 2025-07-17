import SwiftUI
import Foundation
import StoreKit

struct SubscriptionSettingsView: View {
		@EnvironmentObject var expenseStore: ExpenseStore
		@State private var showUpgradeModal = false
		@State private var showPromoCodeAlert = false
		@State private var promoCodeInput: String = ""

		private var subscriptionLabel: String {
				if expenseStore.isPromoProUser {
						return "Monir Pro (Promo)"
				}
				switch expenseStore.productID {
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
								
								if expenseStore.productID != "com.chan.monir.pro.lifetime" && !expenseStore.isPromoProUser {
										Button("Upgrade Plan") {
												showUpgradeModal = true
										}
								}
						}
						if expenseStore.productID == "com.chan.monir.pro.monthly" {
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
						
						Section(header: Text("Access Code")) {
								Button("Enter Access Code") {
										promoCodeInput = ""
										showPromoCodeAlert = true
								}
								.disabled(expenseStore.productID == "com.chan.monir.pro.lifetime")
						}
				}
				.navigationBarTitleDisplayMode(.inline)
				.navigationTitle("Monir Pro")
				.task {
						await checkSubscriptionStatus()
				}
				.sheet(isPresented: $showUpgradeModal, onDismiss: {
						Task {
								await checkSubscriptionStatus()
						}
				}) {
						ProUpgradeModalView(isPresented: $showUpgradeModal)
				}
				.onReceive(NotificationCenter.default.publisher(for: .didUpgradeToPro)) { _ in
						Task {
								await checkSubscriptionStatus()
						}
				}
				.alert("Enter Access Code", isPresented: $showPromoCodeAlert) {
						TextField("Code", text: $promoCodeInput)
								.autocapitalization(.none)
								.disableAutocorrection(true)
						Button("Apply") {
								if promoCodeInput == "m0nee" {
										expenseStore.isPromoProUser = true
								} else if promoCodeInput == "fika" {
										expenseStore.isPromoProUser = false
								}
								// The view will update automatically, no need for a message.
						}
						Button("Cancel", role: .cancel) { }
				} message: {
						Text("Enter a valid access code.")
				}
		}
		
		private func checkSubscriptionStatus() async {
				do {
						var foundEntitlement = false
						for await result in Transaction.currentEntitlements {
								if case .verified(let transaction) = result {
										if transaction.productID == "com.chan.monir.pro.monthly" ||
											transaction.productID == "com.chan.monir.pro.lifetime" {
												expenseStore.productID = transaction.productID
												foundEntitlement = true
												break
										}
								}
						}
						if !foundEntitlement {
								expenseStore.productID = "free"
						}
				} catch {
						print("❌ Failed to check entitlements: \(error)")
						expenseStore.productID = "free"
				}
		}
}
