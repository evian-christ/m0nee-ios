import Foundation
import SwiftUI
import Combine

// MARK: - Language Model
struct Language: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
}

// MARK: - Language Manager
@MainActor
class LanguageManager: ObservableObject {
    @Published var languageCode: String {
        didSet {
            if settings.selectedLanguage != languageCode {
                settings.selectedLanguage = languageCode
            }
        }
    }

    private let settings: AppSettings
    private var cancellable: AnyCancellable?

    var currentLocale: Locale {
        Locale(identifier: languageCode)
    }

    static let availableLanguages: [Language] = [
        Language(code: "en", name: "English"),
        Language(code: "ko", name: "한국어 (Korean)")
    ]

    init(settings: AppSettings = .shared) {
        self.settings = settings
        let preferred = settings.selectedLanguage
        if LanguageManager.availableLanguages.contains(where: { $0.code == preferred }) {
            self.languageCode = preferred
        } else {
            let fallback = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
            let resolved = LanguageManager.availableLanguages.contains(where: { $0.code == fallback }) ? fallback : "en"
            self.languageCode = resolved
            self.settings.selectedLanguage = resolved
        }

        cancellable = settings.$selectedLanguage
            .removeDuplicates()
            .sink { [weak self] newValue in
                guard let self else { return }
                if self.languageCode != newValue {
                    self.languageCode = newValue
                }
            }
    }
}
