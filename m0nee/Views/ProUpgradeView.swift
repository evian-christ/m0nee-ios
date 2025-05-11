import SwiftUI

struct ProUpgradeModalView: View {
	@Binding var isPresented: Bool

	var body: some View {
		VStack(spacing: 20) {
			Image(systemName: "star.circle.fill")
				.font(.system(size: 50))
				.foregroundColor(.yellow)

			Text("Monir Pro Feature")
				.font(.title2)
				.fontWeight(.bold)

			Text("To access features like recurring expenses and advanced insights, please upgrade to Monir Pro.")
				.font(.body)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal)

			Button(action: {
				// Pro 업그레이드 뷰로 이동
				// 예: NavigationLink 트리거나 isShowingUpgradeView = true 등
				isPresented = false
			}) {
				Text("Upgrade Now")
					.font(.headline)
					.frame(maxWidth: .infinity)
					.padding()
					.background(Color.accentColor)
					.foregroundColor(.white)
					.cornerRadius(12)
			}

			Button("Cancel", role: .cancel) {
				isPresented = false
			}
		}
		.padding()
		.frame(maxWidth: 340)
		.background(.ultraThinMaterial)
		.cornerRadius(20)
		.shadow(radius: 10)
	}
}
