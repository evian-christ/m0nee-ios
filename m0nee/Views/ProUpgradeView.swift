import SwiftUI

struct ProUpgradeModalView: View {
	@Binding var isPresented: Bool

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
									Button(action: {
											isPresented = false
									}) {
											Text("Subscribe – £1.99 / month")
													.fontWeight(.semibold)
													.frame(maxWidth: .infinity)
													.padding()
													.background(Color.accentColor)
													.foregroundColor(.white)
													.cornerRadius(12)
									}

									Button(action: {
											isPresented = false
									}) {
											Text("Buy Lifetime – £19.99")
													.fontWeight(.semibold)
													.frame(maxWidth: .infinity)
													.padding()
													.background(Color.gray.opacity(0.2))
													.foregroundColor(.primary)
													.cornerRadius(12)
									}
							}
							.padding(.horizontal)

							
					}
					.padding(.horizontal)
			}
	}
}
