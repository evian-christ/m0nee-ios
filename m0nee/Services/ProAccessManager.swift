import Foundation

@MainActor
protocol ProAccessHandling: AnyObject {
    var isPromoProUser: Bool { get }
    func setPromoStatus(_ isPromo: Bool)
    func isPro(productID: String?) -> Bool
}

@MainActor
final class UserDefaultsProAccessManager: ProAccessHandling {
    private let defaults: UserDefaults
    private let lifetimeProductID = "com.chan.monir.pro.lifetime"
    private(set) var isPromoProUser: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isPromoProUser = defaults.bool(forKey: "isPromoProUser")
    }

    func setPromoStatus(_ isPromo: Bool) {
        guard isPromo != isPromoProUser else { return }
        isPromoProUser = isPromo
        defaults.set(isPromo, forKey: "isPromoProUser")
    }

    func isPro(productID: String?) -> Bool {
        productID == lifetimeProductID || isPromoProUser
    }
}
