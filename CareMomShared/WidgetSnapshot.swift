import Foundation

enum CareMomAppGroup {
    static let identifier = "group.kemal.CareMom2"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

struct ChildWidgetData: Codable, Identifiable {
    let id: UUID
    let name: String
    let lastTemperature: Double?
    let lastTemperatureDate: Date?
    let nextMedicationName: String?
    let nextMedicationTime: Date?
    let illnessThisMonth: Int
}

struct CareMomWidgetSnapshot: Codable {
    var updatedAt: Date
    var selectedChildID: UUID?
    var children: [ChildWidgetData]

    static var fileURL: URL? {
        CareMomAppGroup.containerURL?.appending(path: "widget-snapshot.json")
    }

    static func load() -> CareMomWidgetSnapshot? {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CareMomWidgetSnapshot.self, from: data)
    }

    func save() {
        guard let url = Self.fileURL else { return }
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url, options: .atomic)
    }

    var primaryChild: ChildWidgetData? {
        if let id = selectedChildID, let child = children.first(where: { $0.id == id }) {
            return child
        }
        return children.first
    }
}
