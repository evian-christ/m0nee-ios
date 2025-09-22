import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    enum Store {
        case standard
        case shared
    }

    private struct Keys {
        static let hasSeenTutorial = "hasSeenTutorial"
        static let displayedCategories = "categories"
        static let displayMode = "displayMode"
        static let appearanceMode = "appearanceMode"
        static let useFixedInsightCards = "useFixedInsightCards"
        static let groupByDay = "groupByDay"
        static let showRating = "showRating"
        static let decimalDisplayMode = "decimalDisplayMode"
        static let currencyCode = "currencyCode"
        static let budgetPeriod = "budgetPeriod"
        static let budgetByCategory = "budgetByCategory"
        static let categoryBudgets = "categoryBudgets"
        static let monthlyBudget = "monthlyBudget"
        static let weeklyStartDay = "weeklyStartDay"
        static let monthlyStartDay = "monthlyStartDay"
        static let budgetTrackingEnabled = "enableBudgetTracking"
        static let useICloud = "useiCloud"
        static let favouriteInsightCards = "favouriteInsightCards"
        static let notificationsEnabled = "notificationsEnabled"
        static let notificationHour = "notificationHour"
        static let notificationMinute = "notificationMinute"
        static let selectedLanguage = "selectedLanguage"
    }

    private let defaults: UserDefaults
    private let sharedDefaults: UserDefaults?

    // MARK: Published settings
    @Published var hasSeenTutorial: Bool {
        didSet { set(hasSeenTutorial, for: Keys.hasSeenTutorial, store: .standard) }
    }

    @Published var currencyCode: String {
        didSet { set(currencyCode, for: Keys.currencyCode, store: .shared) }
    }

    @Published var categoriesList: String {
        didSet { set(categoriesList, for: Keys.displayedCategories, store: .standard) }
    }

    @Published var showRating: Bool {
        didSet {
            set(showRating, for: Keys.showRating, store: .standard)
            set(showRating, for: Keys.showRating, store: .shared)
        }
    }

    @Published var decimalDisplayMode: DecimalDisplayMode {
        didSet { set(decimalDisplayMode.rawValue, for: Keys.decimalDisplayMode, store: .standard) }
    }

    @Published var displayMode: String {
        didSet { set(displayMode, for: Keys.displayMode, store: .standard) }
    }

    @Published var budgetPeriod: String {
        didSet { set(budgetPeriod, for: Keys.budgetPeriod, store: .shared) }
    }

    @Published var appearanceMode: String {
        didSet { set(appearanceMode, for: Keys.appearanceMode, store: .standard) }
    }

    @Published var useFixedInsightCards: Bool {
        didSet { set(useFixedInsightCards, for: Keys.useFixedInsightCards, store: .standard) }
    }

    @Published var groupByDay: Bool {
        didSet { set(groupByDay, for: Keys.groupByDay, store: .standard) }
    }

    @Published var budgetByCategory: Bool {
        didSet { set(budgetByCategory, for: Keys.budgetByCategory, store: .shared) }
    }

    @Published var categoryBudgets: [String: String] {
        didSet { persistCategoryBudgets() }
    }

    @Published var monthlyBudget: Double {
        didSet { set(monthlyBudget, for: Keys.monthlyBudget, store: .shared) }
    }

    @Published var weeklyStartDay: Int {
        didSet { set(weeklyStartDay, for: Keys.weeklyStartDay, store: .standard) }
    }

    @Published var monthlyStartDay: Int {
        didSet { set(monthlyStartDay, for: Keys.monthlyStartDay, store: .standard) }
    }

    @Published var budgetTrackingEnabled: Bool {
        didSet { set(budgetTrackingEnabled, for: Keys.budgetTrackingEnabled, store: .shared) }
    }

    @Published var useICloud: Bool {
        didSet { set(useICloud, for: Keys.useICloud, store: .standard) }
    }

    @Published var favouriteInsightCardsData: Data {
        didSet { set(favouriteInsightCardsData, for: Keys.favouriteInsightCards, store: .standard) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { set(notificationsEnabled, for: Keys.notificationsEnabled, store: .standard) }
    }

    @Published var notificationHour: Int {
        didSet { set(notificationHour, for: Keys.notificationHour, store: .standard) }
    }

    @Published var notificationMinute: Int {
        didSet { set(notificationMinute, for: Keys.notificationMinute, store: .standard) }
    }

    @Published var selectedLanguage: String {
        didSet { set(selectedLanguage, for: Keys.selectedLanguage, store: .standard) }
    }

    // MARK: Init
    init(
        defaults: UserDefaults = .standard,
        sharedDefaults: UserDefaults? = UserDefaults(suiteName: "group.com.chankim.Monir")
    ) {
        self.defaults = defaults
        self.sharedDefaults = sharedDefaults

        self.hasSeenTutorial = Self.boolValue(for: Keys.hasSeenTutorial, store: .standard, default: false, defaults: defaults, sharedDefaults: sharedDefaults)
        self.currencyCode = Self.stringValue(for: Keys.currencyCode, store: .shared, default: Locale.current.currency?.identifier ?? "USD", defaults: defaults, sharedDefaults: sharedDefaults)
        self.categoriesList = Self.stringValue(for: Keys.displayedCategories, store: .standard, default: "Food,Transport,Other", defaults: defaults, sharedDefaults: sharedDefaults)
        self.showRating = Self.boolValue(for: Keys.showRating, store: .shared, default: true, defaults: defaults, sharedDefaults: sharedDefaults)
        self.decimalDisplayMode = DecimalDisplayMode(rawValue: Self.stringValue(for: Keys.decimalDisplayMode, store: .standard, default: DecimalDisplayMode.automatic.rawValue, defaults: defaults, sharedDefaults: sharedDefaults)) ?? .automatic
        self.displayMode = Self.stringValue(for: Keys.displayMode, store: .standard, default: "Standard", defaults: defaults, sharedDefaults: sharedDefaults)
        self.budgetPeriod = Self.stringValue(for: Keys.budgetPeriod, store: .shared, default: "Monthly", defaults: defaults, sharedDefaults: sharedDefaults)
        self.appearanceMode = Self.stringValue(for: Keys.appearanceMode, store: .standard, default: "Automatic", defaults: defaults, sharedDefaults: sharedDefaults)
        self.useFixedInsightCards = Self.boolValue(for: Keys.useFixedInsightCards, store: .standard, default: true, defaults: defaults, sharedDefaults: sharedDefaults)
        self.groupByDay = Self.boolValue(for: Keys.groupByDay, store: .standard, default: true, defaults: defaults, sharedDefaults: sharedDefaults)
        self.budgetByCategory = Self.boolValue(for: Keys.budgetByCategory, store: .shared, default: false, defaults: defaults, sharedDefaults: sharedDefaults)
        self.categoryBudgets = Self.decodeBudgets(for: Keys.categoryBudgets, defaults: defaults, sharedDefaults: sharedDefaults)
        self.monthlyBudget = Self.doubleValue(for: Keys.monthlyBudget, store: .shared, default: 0, defaults: defaults, sharedDefaults: sharedDefaults)
        self.weeklyStartDay = Self.intValue(for: Keys.weeklyStartDay, store: .standard, default: 1, defaults: defaults, sharedDefaults: sharedDefaults)
        self.monthlyStartDay = Self.intValue(for: Keys.monthlyStartDay, store: .standard, default: 1, defaults: defaults, sharedDefaults: sharedDefaults)
        self.budgetTrackingEnabled = Self.boolValue(for: Keys.budgetTrackingEnabled, store: .shared, default: true, defaults: defaults, sharedDefaults: sharedDefaults)
        self.useICloud = Self.boolValue(for: Keys.useICloud, store: .standard, default: true, defaults: defaults, sharedDefaults: sharedDefaults)
        self.favouriteInsightCardsData = Self.dataValue(for: Keys.favouriteInsightCards, store: .standard, default: Data(), defaults: defaults, sharedDefaults: sharedDefaults)
        self.notificationsEnabled = Self.boolValue(for: Keys.notificationsEnabled, store: .standard, default: false, defaults: defaults, sharedDefaults: sharedDefaults)
        self.notificationHour = Self.intValue(for: Keys.notificationHour, store: .standard, default: 20, defaults: defaults, sharedDefaults: sharedDefaults)
        self.notificationMinute = Self.intValue(for: Keys.notificationMinute, store: .standard, default: 0, defaults: defaults, sharedDefaults: sharedDefaults)
        self.selectedLanguage = Self.stringValue(for: Keys.selectedLanguage, store: .standard, default: Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en", defaults: defaults, sharedDefaults: sharedDefaults)
    }

    // MARK: Budget helpers
    func loadCategoryBudgets() -> [String: String] {
        categoryBudgets
    }

    func saveCategoryBudgets(_ budgets: [String: String]) {
        categoryBudgets = budgets
    }

    func resetSettings() {
        hasSeenTutorial = false
        displayMode = "Standard"
        appearanceMode = "Automatic"
        useFixedInsightCards = true
        groupByDay = true
        showRating = true
        decimalDisplayMode = .automatic
        currencyCode = Locale.current.currency?.identifier ?? "USD"
        budgetPeriod = "Monthly"
        weeklyStartDay = 1
        monthlyStartDay = 1
        budgetByCategory = false
        monthlyBudget = 0
        categoryBudgets = [:]
        budgetTrackingEnabled = true
        useICloud = true
        notificationsEnabled = false
        notificationHour = 20
        notificationMinute = 0
        categoriesList = "Food,Transport,Other"
        favouriteInsightCardsData = Data()
    }

    // MARK: Private helpers
    private func persistCategoryBudgets() {
        guard let encoded = try? JSONEncoder().encode(categoryBudgets) else { return }
        set(encoded, for: Keys.categoryBudgets, store: .shared)
        set(encoded, for: Keys.categoryBudgets, store: .standard)

        let total = categoryBudgets.values.compactMap { Double($0) }.reduce(0, +)
        if monthlyBudget != total {
            monthlyBudget = total
        }
    }

    private func set(_ value: Bool, for key: String, store: Store) {
        guard store != .shared || sharedDefaults != nil else { return }
        switch store {
        case .standard:
            defaults.set(value, forKey: key)
        case .shared:
            sharedDefaults?.set(value, forKey: key)
        }
    }

    private func set(_ value: Int, for key: String, store: Store) {
        guard store != .shared || sharedDefaults != nil else { return }
        switch store {
        case .standard:
            defaults.set(value, forKey: key)
        case .shared:
            sharedDefaults?.set(value, forKey: key)
        }
    }

    private func set(_ value: Double, for key: String, store: Store) {
        guard store != .shared || sharedDefaults != nil else { return }
        switch store {
        case .standard:
            defaults.set(value, forKey: key)
        case .shared:
            sharedDefaults?.set(value, forKey: key)
        }
    }

    private func set(_ value: String, for key: String, store: Store) {
        guard store != .shared || sharedDefaults != nil else { return }
        switch store {
        case .standard:
            defaults.set(value, forKey: key)
        case .shared:
            sharedDefaults?.set(value, forKey: key)
        }
    }

    private func set(_ value: Data, for key: String, store: Store) {
        guard store != .shared || sharedDefaults != nil else { return }
        switch store {
        case .standard:
            defaults.set(value, forKey: key)
        case .shared:
            sharedDefaults?.set(value, forKey: key)
        }
    }

    private static func boolValue(for key: String, store: Store, default defaultValue: Bool, defaults: UserDefaults, sharedDefaults: UserDefaults?) -> Bool {
        switch store {
        case .standard:
            return defaults.object(forKey: key) as? Bool ?? defaultValue
        case .shared:
            return sharedDefaults?.object(forKey: key) as? Bool ?? defaultValue
        }
    }

    private static func stringValue(for key: String, store: Store, default defaultValue: String, defaults: UserDefaults, sharedDefaults: UserDefaults?) -> String {
        switch store {
        case .standard:
            return defaults.string(forKey: key) ?? defaultValue
        case .shared:
            return sharedDefaults?.string(forKey: key) ?? defaultValue
        }
    }

    private static func intValue(for key: String, store: Store, default defaultValue: Int, defaults: UserDefaults, sharedDefaults: UserDefaults?) -> Int {
        switch store {
        case .standard:
            if defaults.object(forKey: key) == nil { return defaultValue }
            return defaults.integer(forKey: key)
        case .shared:
            guard let sharedDefaults else { return defaultValue }
            if sharedDefaults.object(forKey: key) == nil { return defaultValue }
            return sharedDefaults.integer(forKey: key)
        }
    }

    private static func doubleValue(for key: String, store: Store, default defaultValue: Double, defaults: UserDefaults, sharedDefaults: UserDefaults?) -> Double {
        switch store {
        case .standard:
            if defaults.object(forKey: key) == nil { return defaultValue }
            return defaults.double(forKey: key)
        case .shared:
            guard let sharedDefaults else { return defaultValue }
            if sharedDefaults.object(forKey: key) == nil { return defaultValue }
            return sharedDefaults.double(forKey: key)
        }
    }

    private static func dataValue(for key: String, store: Store, default defaultValue: Data, defaults: UserDefaults, sharedDefaults: UserDefaults?) -> Data {
        switch store {
        case .standard:
            return defaults.data(forKey: key) ?? defaultValue
        case .shared:
            return sharedDefaults?.data(forKey: key) ?? defaultValue
        }
    }

    private static func decodeBudgets(for key: String, defaults: UserDefaults, sharedDefaults: UserDefaults?) -> [String: String] {
        if let data = sharedDefaults?.data(forKey: key), let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            return decoded
        }
        if let data = defaults.data(forKey: key), let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            return decoded
        }
        return [:]
    }
}

extension AppSettings {
    static let shared = AppSettings()

    static func testingInstance() -> AppSettings {
        let suiteName = "com.m0nee.testing.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        let shared = UserDefaults(suiteName: "group.com.chankim.Monir.testing.\(UUID().uuidString)")
        return AppSettings(defaults: defaults, sharedDefaults: shared)
    }
}

extension AppSettings {
    @MainActor
    func binding<T>(_ keyPath: ReferenceWritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { self[keyPath: keyPath] = $0 }
        )
    }
}
