import SwiftUI
import WidgetKit

struct CareMomSummaryWidget: Widget {
    let kind = "CareMomSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CareMomWidgetProvider()) { entry in
            CareMomSummaryWidget.EntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringResource("widget.health_diary"))
        .description(LocalizedStringResource("widget.health_diary.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

extension CareMomSummaryWidget {
    struct EntryView: View {
        @Environment(\.widgetFamily) private var family
        let entry: CareMomWidgetEntry

        var body: some View {
            switch family {
            case .systemMedium:
                MediumSummaryView(snapshot: entry.snapshot)
            default:
                SmallSummaryView(child: entry.snapshot?.primaryChild)
            }
        }
    }
}

struct CareMomMedicationWidget: Widget {
    let kind = "CareMomMedicationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CareMomWidgetProvider()) { entry in
            MedicationWidgetView(child: entry.snapshot?.primaryChild)
        }
        .configurationDisplayName(LocalizedStringResource("widget.next_medication"))
        .description(LocalizedStringResource("widget.next_medication.description"))
        .supportedFamilies([.systemSmall])
    }
}
