import Foundation
import SwiftData

@Model
final class GalleryItem {
    var id: UUID
    var date: Date
    var title: String
    var imageData: Data
    var notes: String
    var ocrText: String

    var child: Child?

    init(date: Date = .now, title: String = "", imageData: Data, notes: String = "", ocrText: String = "", child: Child? = nil) {
        self.id = UUID()
        self.date = date
        self.title = title
        self.imageData = imageData
        self.notes = notes
        self.ocrText = ocrText
        self.child = child
    }
}
