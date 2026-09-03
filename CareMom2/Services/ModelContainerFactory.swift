import Foundation
import SwiftData

enum ModelContainerFactory {
    private static let schemaVersion = 5
    private static let schemaVersionKey = "CareMomSwiftDataSchemaVersion"
    static var iCloudSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnabled") }
    }

    private static var storeURL: URL {
        URL.applicationSupportDirectory.appending(path: "CareMom.store")
    }

    private static var schema: Schema {
        Schema([
            Child.self, DiaryEntry.self, MedicationCourse.self,
            MedicationIntake.self, GalleryItem.self,
            GrowthRecord.self, VaccinationRecord.self
        ])
    }

    static func make() -> ModelContainer {
        ensureApplicationSupportExists()
        resetStoreIfSchemaChanged()

        if let container = openPersistentContainer() { return container }

        deleteAllSwiftDataStores()
        if let container = openPersistentContainer() { return container }

        print("⚠️ CareMom: in-memory fallback")
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("⚠️ CareMom critical SwiftData error: \(error)")
            if let fallback = try? ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            ) {
                return fallback
            }
            preconditionFailure("SwiftData unavailable: \(error)")
        }
    }

    private static func openPersistentContainer() -> ModelContainer? {
        do {
            let config: ModelConfiguration
            if iCloudSyncEnabled {
                config = ModelConfiguration(
                    schema: schema,
                    url: storeURL,
                    cloudKitDatabase: .private("iCloud.kemal.CareMom2")
                )
            } else {
                config = ModelConfiguration(schema: schema, url: storeURL)
            }
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("SwiftData open error: \(error)")
            return nil
        }
    }

    private static func ensureApplicationSupportExists() {
        let directory = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private static func resetStoreIfSchemaChanged() {
        let stored = UserDefaults.standard.integer(forKey: schemaVersionKey)
        guard stored != schemaVersion else { return }
        deleteAllSwiftDataStores()
        UserDefaults.standard.set(schemaVersion, forKey: schemaVersionKey)
    }

    private static func deleteAllSwiftDataStores() {
        let fm = FileManager.default
        let support = URL.applicationSupportDirectory

        deleteStoreFiles(at: storeURL)

        // Старый store по умолчанию (до переименования)
        deleteStoreFiles(at: support.appending(path: "default.store"))

        if let contents = try? fm.contentsOfDirectory(at: support, includingPropertiesForKeys: nil) {
            for url in contents where url.lastPathComponent.hasSuffix(".store")
                || url.lastPathComponent.hasSuffix(".store-shm")
                || url.lastPathComponent.hasSuffix(".store-wal") {
                try? fm.removeItem(at: url)
            }
        }
    }

    private static func deleteStoreFiles(at url: URL) {
        let fm = FileManager.default
        let base = url.path
        for path in [base, base + "-shm", base + "-wal"] {
            if fm.fileExists(atPath: path) {
                try? fm.removeItem(atPath: path)
            }
        }
    }
}
