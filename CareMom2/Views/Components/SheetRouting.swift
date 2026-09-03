import Foundation
import SwiftData

struct ChildSheetRoute: Identifiable {
    let id = UUID()
    let child: Child
}

struct EntrySheetRoute: Identifiable {
    let id: UUID
    let entry: DiaryEntry

    init(entry: DiaryEntry) {
        self.id = entry.id
        self.entry = entry
    }
}

struct ActivitySheetRoute: Identifiable {
    let id = UUID()
    let child: Child
    let kind: QuickActivityKind
}
