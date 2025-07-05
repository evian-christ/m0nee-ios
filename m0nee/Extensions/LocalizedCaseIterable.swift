import SwiftUI

protocol LocalizedCaseIterable: CaseIterable, Identifiable, RawRepresentable where RawValue == String {
    var localizedStringKey: LocalizedStringKey { get }
}

extension LocalizedCaseIterable {
    var id: String { rawValue }
}
