import Foundation

struct StoreData: Codable {
    var expenses: [Expense]
    var categories: [CategoryItem]
    var recurringExpenses: [RecurringExpense]
}

protocol ExpenseRepository: Sendable {
    func load() async throws -> StoreData?
    func save(_ data: StoreData) async throws
    func syncStorageIfNeeded() async
}

actor FileExpenseRepository: ExpenseRepository {
    private let fileManager = FileManager.default
    private let defaults = UserDefaults.standard
    private let documentsURL: URL
    private let localStoreURL: URL
    private let iCloudStoreURL: URL?
    private var saveURL: URL
    private let forTesting: Bool

    init(forTesting: Bool = false) {
        self.forTesting = forTesting
        self.documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.localStoreURL = documentsURL.appendingPathComponent("expenses.json")

        if forTesting {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("expenses-test.json")
            try? fileManager.removeItem(at: tempURL)
            self.saveURL = tempURL
            self.iCloudStoreURL = nil
            return
        }

        let hasUseiCloudKey = defaults.object(forKey: "useiCloud") != nil
        let useICloud: Bool
        if hasUseiCloudKey {
            useICloud = defaults.bool(forKey: "useiCloud")
        } else {
            useICloud = true
            defaults.set(useICloud, forKey: "useiCloud")
        }

        if useICloud,
           let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            try? fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
            let iCloudURL = containerURL.appendingPathComponent("expenses.json")
            self.iCloudStoreURL = iCloudURL

            let localExists = fileManager.fileExists(atPath: localStoreURL.path)
            let iCloudExists = fileManager.fileExists(atPath: iCloudURL.path)

            if iCloudExists {
                self.saveURL = iCloudURL
            } else if localExists {
                do {
                    try fileManager.copyItem(at: localStoreURL, to: iCloudURL)
                } catch {
                    // ignore copy failure
                }
                self.saveURL = iCloudURL
            } else {
                self.saveURL = iCloudURL
            }
        } else {
            self.iCloudStoreURL = nil
            self.saveURL = localStoreURL
        }
    }

    func load() async throws -> StoreData? {
        try await Task.detached(priority: .utility) { [saveURL] in
            guard FileManager.default.fileExists(atPath: saveURL.path) else { return nil }
            let data = try Data(contentsOf: saveURL)
            return try JSONDecoder().decode(StoreData.self, from: data)
        }.value
    }

    func save(_ data: StoreData) async throws {
        try await Task.detached(priority: .utility) { [saveURL, iCloudStoreURL, localStoreURL] in
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: saveURL, options: .atomic)

            if let iCloudURL = iCloudStoreURL, saveURL.pathContainsMobileDocuments {
                let backupURL = localStoreURL.deletingLastPathComponent().appendingPathComponent("expenses_backup_for_recovery.json")
                do {
                    try encoded.write(to: backupURL, options: .atomic)
                } catch {
                    // ignore backup error
                }
            }
        }.value
    }

    func syncStorageIfNeeded() async {
        guard !forTesting,
              let iCloudURL = iCloudStoreURL else { return }

        await Task.detached(priority: .utility) { [localStoreURL, iCloudURL] in
            let fileManager = FileManager.default
            let iCloudDocsURL = iCloudURL
            let localURL = localStoreURL

            let localExists = fileManager.fileExists(atPath: localURL.path)
            let iCloudExists = fileManager.fileExists(atPath: iCloudDocsURL.path)

            if localExists, iCloudExists {
                do {
                    let localAttributes = try fileManager.attributesOfItem(atPath: localURL.path)
                    let iCloudAttributes = try fileManager.attributesOfItem(atPath: iCloudDocsURL.path)

                    if let localDate = localAttributes[.modificationDate] as? Date,
                       let iCloudDate = iCloudAttributes[.modificationDate] as? Date {
                        if localDate > iCloudDate {
                            do {
                                if fileManager.fileExists(atPath: iCloudDocsURL.path) {
                                    try fileManager.removeItem(at: iCloudDocsURL)
                                }
                                try fileManager.copyItem(at: localURL, to: iCloudDocsURL)
                            } catch {
                                // ignore copy failure
                            }
                        } else if iCloudDate > localDate {
                            do {
                                if fileManager.fileExists(atPath: localURL.path) {
                                    try fileManager.removeItem(at: localURL)
                                }
                                try fileManager.copyItem(at: iCloudDocsURL, to: localURL)
                            } catch {
                                // ignore copy failure
                            }
                        }
                    }
                } catch {
                    // ignore attribute errors
                }
            } else if localExists {
                do {
                    if fileManager.fileExists(atPath: iCloudDocsURL.path) {
                        try fileManager.removeItem(at: iCloudDocsURL)
                    }
                    try fileManager.copyItem(at: localURL, to: iCloudDocsURL)
                } catch {
                    // ignore
                }
            } else if iCloudExists {
                do {
                    if fileManager.fileExists(atPath: localURL.path) {
                        try fileManager.removeItem(at: localURL)
                    }
                    try fileManager.copyItem(at: iCloudDocsURL, to: localURL)
                } catch {
                    // ignore
                }
            } else {
                // nothing to sync
            }
        }.value
    }
}

private extension URL {
    var pathContainsMobileDocuments: Bool {
        path.contains("Mobile Documents")
    }
}

actor InMemoryExpenseRepository: ExpenseRepository {
    private var storage: StoreData?

    func load() async throws -> StoreData? {
        storage
    }

    func save(_ data: StoreData) async throws {
        storage = data
    }

    func syncStorageIfNeeded() async { }
}
