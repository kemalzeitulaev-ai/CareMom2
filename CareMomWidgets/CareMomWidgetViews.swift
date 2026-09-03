import SwiftUI
import WidgetKit

enum WidgetL10n {
    static func t(_ key: String.LocalizationValue) -> String {
        String(localized: key)
    }
}

enum WidgetColors {
    static let coral = Color(red: 0.96, green: 0.48, blue: 0.52)
    static let pink = Color(red: 0.98, green: 0.75, blue: 0.78)
    static let lavender = Color(red: 0.72, green: 0.68, blue: 0.90)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.95)
}

struct CareMomWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CareMomWidgetSnapshot?
}

struct CareMomWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CareMomWidgetEntry {
        CareMomWidgetEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (CareMomWidgetEntry) -> Void) {
        completion(CareMomWidgetEntry(date: .now, snapshot: CareMomWidgetSnapshot.load() ?? .preview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CareMomWidgetEntry>) -> Void) {
        let entry = CareMomWidgetEntry(date: .now, snapshot: CareMomWidgetSnapshot.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct SmallSummaryView: View {
    let child: ChildWidgetData?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(WidgetColors.coral)
                Text("CareMom")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if let child {
                Text(child.name)
                    .font(.headline)
                    .lineLimit(1)

                if let temp = child.lastTemperature {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: "thermometer.medium")
                            .font(.caption)
                            .foregroundStyle(temp >= 38 ? WidgetColors.coral : WidgetColors.lavender)
                        Text(String(format: "%.1f°", temp))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(temp >= 38 ? WidgetColors.coral : .primary)
                    }
                } else {
                    Text(WidgetL10n.t("widget.no_temperature"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(WidgetL10n.t("widget.add_child"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            WidgetColors.cream
        }
    }
}

struct MediumSummaryView: View {
    let snapshot: CareMomWidgetSnapshot?

    var body: some View {
        let child = snapshot?.primaryChild

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("CareMom", systemImage: "heart.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WidgetColors.coral)
                Spacer()
                if let date = snapshot?.updatedAt {
                    Text(date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let child {
                Text(child.name)
                    .font(.title3.weight(.bold))

                HStack(spacing: 16) {
                    statBlock(
                        icon: "thermometer.medium",
                        title: WidgetL10n.t("widget.temperature"),
                        value: child.lastTemperature.map { String(format: "%.1f°", $0) } ?? "—",
                        tint: (child.lastTemperature ?? 0) >= 38 ? WidgetColors.coral : WidgetColors.lavender
                    )

                    statBlock(
                        icon: "heart.text.square",
                        title: WidgetL10n.t("widget.sick"),
                        value: "\(child.illnessThisMonth)",
                        tint: WidgetColors.coral
                    )
                }

                if let med = child.nextMedicationName, let time = child.nextMedicationTime {
                    HStack(spacing: 6) {
                        Image(systemName: "pills.fill")
                            .foregroundStyle(WidgetColors.lavender)
                        Text("\(med) · \(time.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(WidgetColors.pink.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                Text(WidgetL10n.t("widget.open_add_profile"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            WidgetColors.cream
        }
    }

    private func statBlock(icon: String, title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MedicationWidgetView: View {
    let child: ChildWidgetData?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(WidgetL10n.t("widget.medication"), systemImage: "pills.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WidgetColors.lavender)

            if let child, let med = child.nextMedicationName, let time = child.nextMedicationTime {
                Text(med)
                    .font(.headline)
                    .lineLimit(2)
                Text(time, style: .time)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(WidgetColors.coral)
                Text(child.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(WidgetL10n.t("widget.no_reminders"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            WidgetColors.cream
        }
    }
}

extension CareMomWidgetSnapshot {
    static var preview: CareMomWidgetSnapshot {
        CareMomWidgetSnapshot(
            updatedAt: .now,
            selectedChildID: UUID(),
            children: [
                ChildWidgetData(
                    id: UUID(),
                    name: "Emma",
                    lastTemperature: 37.4,
                    lastTemperatureDate: .now,
                    nextMedicationName: "Nurofen",
                    nextMedicationTime: Calendar.current.date(byAdding: .hour, value: 2, to: .now),
                    illnessThisMonth: 1
                )
            ]
        )
    }
}
