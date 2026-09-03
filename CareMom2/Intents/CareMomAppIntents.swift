import AppIntents
import Foundation

struct CareMomShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordTemperatureIntent(),
            phrases: [
                "Record temperature in \(.applicationName)",
                "Record child temperature in \(.applicationName)",
                "Запиши температуру в \(.applicationName)",
                "Температура ребёнка в \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("intent.temperature.short"),
            systemImageName: "thermometer.medium"
        )
        AppShortcut(
            intent: OpenQuickDiaryIntent(),
            phrases: [
                "Open diary in \(.applicationName)",
                "Открой дневник \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("intent.diary.short"),
            systemImageName: "book.fill"
        )
    }
}

struct RecordTemperatureIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.record_temperature"
    static var description = IntentDescription(LocalizedStringResource("intent.record_temperature.description"))

    @Parameter(title: LocalizedStringResource("entry.temperature"))
    var temperature: Double

    @Parameter(title: LocalizedStringResource("child.first_name"))
    var childName: String?

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        var action = PendingAppAction.recordTemperature(temperature: temperature, childName: childName ?? "")
        action.save()
        let dialog = String(format: String(localized: "intent.record_temperature.dialog"), String(format: "%.1f", temperature))
        return .result(dialog: IntentDialog(stringLiteral: dialog))
    }
}

struct OpenQuickDiaryIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.open_diary"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        PendingAppAction.openDiary.save()
        return .result()
    }
}

enum PendingAppAction: Codable {
    case recordTemperature(temperature: Double, childName: String)
    case openDiary

    private static var url: URL? {
        CareMomAppGroup.containerURL?.appending(path: "pending-action.json")
    }

    func save() {
        guard let url = Self.url, let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func consume() -> PendingAppAction? {
        guard let url = Self.url,
              let data = try? Data(contentsOf: url),
              let action = try? JSONDecoder().decode(PendingAppAction.self, from: data) else { return nil }
        try? FileManager.default.removeItem(at: url)
        return action
    }
}
