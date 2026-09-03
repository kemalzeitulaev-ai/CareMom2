import Foundation

@Observable
final class AppState {
    var selectedChildID: UUID?

    func selectedChild(from children: [Child]) -> Child? {
        if let id = selectedChildID,
           let child = children.first(where: { $0.id == id }) {
            return child
        }
        return children.first
    }

    func ensureSelection(from children: [Child]) {
        if children.isEmpty {
            selectedChildID = nil
            return
        }
        if let id = selectedChildID,
           children.contains(where: { $0.id == id }) {
            return
        }
        selectedChildID = children.first?.id
    }
}
