import SwiftUI
import UIKit

struct CodableColor: Codable, Equatable {
	let red: Double
	let green: Double
	let blue: Double
	let opacity: Double

	/// Initialize from SwiftUI Color
	init(_ color: Color) {
		let uiColor = UIColor(color)
		var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
		uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
		self.red = Double(r)
		self.green = Double(g)
		self.blue = Double(b)
		self.opacity = Double(a)
	}

	/// Convert back to SwiftUI Color
	var color: Color {
		Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
	}
}
