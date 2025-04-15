import SwiftUI

struct RepeatExpenseView: View {
	enum Period: String, CaseIterable, Identifiable {
		case never = "Never"
		case daily = "Daily"
		case weekly = "Weekly"
		case monthly = "Monthly"
		case quarterly = "Quarterly"
		case yearly = "Yearly"
		
		var id: String { self.rawValue }
	}
	
	@State private var selectedPeriod: Period = .daily
	
	var body: some View {
		Form {
			Section() {
				ForEach(Period.allCases) { period in
					Button(action: {
						selectedPeriod = period
					}) {
						HStack {
							Text(period.rawValue)
							Spacer()
							if period == selectedPeriod {
								Image(systemName: "checkmark")
									.foregroundColor(.accentColor)
							}
						}
						.frame(maxWidth: .infinity) // <== 전체 너비를 채워 버튼 영역 확장
						.contentShape(Rectangle())
					}
					.buttonStyle(.plain)
				}
			}
			
			Section(header: Text("Frequency")) {
				Text("Options based on '\(selectedPeriod.rawValue)' will appear here.")
					.foregroundColor(.secondary)
			}
		}
		.navigationTitle("Repeat")
		.navigationBarTitleDisplayMode(.inline)
	}
}
