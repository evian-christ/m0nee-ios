import Foundation

extension DateFormatter {
		static let m0neeDefault: DateFormatter = {
				let formatter = DateFormatter()
				formatter.dateFormat = "MMM d, yyyy" // 원하는 날짜 포맷으로 수정하세요.
				return formatter
		}()
}
