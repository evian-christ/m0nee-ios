import Foundation

extension DateFormatter {
		/// 13-04-2025
		static let m0neeCSV: DateFormatter = {
				let formatter = DateFormatter()
				formatter.dateFormat = "dd-MM-yyyy"
				return formatter
		}()

		/// 13 Apr
		static let m0neeListSection: DateFormatter = {
				let formatter = DateFormatter()
				formatter.dateFormat = "dd MMM"
				return formatter
		}()
}
