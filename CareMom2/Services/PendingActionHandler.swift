import Foundation
import SwiftData

@MainActor
enum PendingActionHandler {
    static func processPendingActions(
        context: ModelContext,
        children: [Child],
        appState: AppState
    ) {
        guard let action = PendingAppAction.consume() else { return }

        switch action {
        case .openDiary:
            break
        case .recordTemperature(let temperature, let childName):
            let child = children.first {
                $0.firstName.lowercased() == childName.lowercased()
            } ?? children.first
            guard let child else { return }
            let entry = DiaryEntry(
                date: .now, type: .illness, notes: L10n.t("siri.recorded_note"),
                temperature: temperature, symptoms: [.fever], child: child
            )
            context.insert(entry)
            appState.selectedChildID = child.id
            try? context.save()
        }
    }
}
