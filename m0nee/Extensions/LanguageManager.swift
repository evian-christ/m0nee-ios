import Foundation
import SwiftUI

// MARK: - Language Model
struct Language: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
}

// MARK: - Language Manager
class LanguageManager: ObservableObject {
    @AppStorage("selectedLanguage") var languageCode: String = "en" {
        didSet {
            // Ensure the UI updates when the language code changes.
            objectWillChange.send()
        }
    }

    var currentLocale: Locale {
        Locale(identifier: languageCode)
    }

    static let availableLanguages: [Language] = [
        Language(code: "en", name: "English"),
        Language(code: "ko", name: "한국어 (Korean)")
    ]

    init() {
        // If there's no saved language, try to use the device's preferred language if it's supported.
        if UserDefaults.standard.string(forKey: "selectedLanguage") == nil {
            let preferredLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
            languageCode = LanguageManager.availableLanguages.contains(where: { $0.code == preferredLanguage }) ? preferredLanguage : "en"
        }
    }
}
