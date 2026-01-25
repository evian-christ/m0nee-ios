import Foundation

/// ExpenseStore에서 발생할 수 있는 에러 타입
enum ExpenseStoreError: LocalizedError {
    case saveFailed(underlying: Error)
    case loadFailed(underlying: Error)
    case syncFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load data: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Failed to sync data: \(error.localizedDescription)"
        }
    }

    var userFriendlyMessage: String {
        switch self {
        case .saveFailed:
            return "Unable to save your expense. Please try again."
        case .loadFailed:
            return "Unable to load your expenses. Please restart the app."
        case .syncFailed:
            return "Sync failed. Your data is saved locally."
        }
    }
}
