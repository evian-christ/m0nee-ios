import SwiftUI

struct LocalizedText: View {
    @EnvironmentObject private var languageManager: LanguageManager
    private let key: String

    init(_ key: String) {
        self.key = key
    }

    var body: some View {
        // By depending on languageManager.languageCode, this view will re-render
        // whenever the language changes, thus re-computing the localized string.
        Text(localized(key, from: languageManager.languageCode))
    }

    private func localized(_ key: String, from languageCode: String) -> String {
        // Find the path for the language-specific .lproj directory
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to the base localization if the specific one isn't found
            return NSLocalizedString(key, comment: "")
        }

        // Return the localized string from the specific bundle
        return NSLocalizedString(key, tableName: nil, bundle: bundle, comment: "")
    }
}
