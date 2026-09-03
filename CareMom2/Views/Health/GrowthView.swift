import Charts
import SwiftUI
import SwiftData

private struct GrowthSheetItem: Identifiable {
    let id: UUID
    let child: Child

    init(child: Child) {
        self.id = child.id
        self.child = child
    }
}

struct GrowthView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.firstName) private var children: [Child]
    @Query(sort: \GrowthRecord.date) private var allRecords: [GrowthRecord]

    @Bindable var appState: AppState
    @State private var addTarget: GrowthSheetItem?

    private var child: Child? { appState.selectedChild(from: children) }

    private var records: [GrowthRecord] {
        guard let child else { return [] }
        return allRecords.filter { $0.child?.id == child.id }
    }

    var body: some View {
        Group {
            if children.isEmpty {
                ContentUnavailableView {
                    Label(L10n.t("empty.no_profiles_title"), systemImage: "figure.and.child.holdinghands")
                } description: {
                    Text(L10n.t("growth.add_profile_first"))
                }
            } else if records.isEmpty {
                ContentUnavailableView {
                    Label(L10n.t("growth.no_measurements"), systemImage: "ruler")
                } description: {
                    Text(L10n.t("growth.track_hint"))
                } actions: {
                    Button(L10n.t("child.add_measurement")) { openAddSheet() }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 40)
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if let summary = child?.latestGrowthRecord {
                            latestSummaryCard(summary)
                        }

                        if records.contains(where: { $0.weightKg != nil }) {
                            chart(title: L10n.t("growth.weight_kg"), data: records.compactMap { r in
                                r.weightKg.map { (r.date, $0) }
                            })
                        }
                        if records.contains(where: { $0.heightCm != nil }) {
                            chart(title: L10n.t("growth.height_cm"), data: records.compactMap { r in
                                r.heightCm.map { (r.date, $0) }
                            })
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.t("growth.history"))
                                .font(.headline)
                                .padding(.horizontal, 4)

                            ForEach(records.reversed(), id: \.id) { record in
                                growthRecordRow(record)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CareMomTheme.creamBackground)
        .navigationTitle(L10n.t("growth.title"))
        .onAppear { appState.ensureSelection(from: children) }
        .toolbar {
            if !children.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { openAddSheet() } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(CareMomTheme.warmCoral)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if children.count > 1 {
                ChildSelectorBar(children: children, selectedChildID: $appState.selectedChildID)
                    .padding(.vertical, 12)
                    .background(CareMomTheme.creamBackground)
            }
        }
        .sheet(item: $addTarget) { item in
            AddGrowthRecordView(child: item.child)
        }
    }

    private func openAddSheet() {
        appState.ensureSelection(from: children)
        addTarget = appState.selectedChild(from: children).map(GrowthSheetItem.init)
    }

    private func latestSummaryCard(_ record: GrowthRecord) -> some View {
        HStack(spacing: 16) {
            if let weight = record.weightKg {
                summaryMetric(title: L10n.t("child.weight"), value: String(format: "%.2f", weight), unit: L10n.t("growth.unit.kg"))
            }
            if record.weightKg != nil && record.heightCm != nil {
                Divider().frame(height: 40)
            }
            if let height = record.heightCm {
                summaryMetric(title: L10n.t("child.height"), value: String(format: "%.0f", height), unit: L10n.t("growth.unit.cm"))
            }
            Spacer(minLength: 0)
        }
        .padding()
        .careMomCard()
    }

    private func summaryMetric(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(CareMomTheme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CareMomTheme.textPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(CareMomTheme.textSecondary)
            }
        }
    }

    private func growthRecordRow(_ record: GrowthRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 12) {
                    if let weight = record.weightKg {
                        Label(L10n.format("growth.weight_format", weight), systemImage: "scalemass")
                    }
                    if let height = record.heightCm {
                        Label(L10n.format("growth.height_format", height), systemImage: "ruler")
                    }
                }
                .font(.caption)
                .foregroundStyle(CareMomTheme.textSecondary)
                if !record.notes.isEmpty {
                    Text(record.notes)
                        .font(.caption)
                        .foregroundStyle(CareMomTheme.textSecondary)
                }
            }
            Spacer()
        }
        .padding()
        .careMomCard()
        .contextMenu {
            Button(L10n.t("common.delete"), role: .destructive) {
                modelContext.delete(record)
                HapticService.success()
            }
        }
    }

    private func chart(title: String, data: [(Date, Double)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Chart(data, id: \.0) { item in
                LineMark(x: .value(L10n.t("chart.date"), item.0), y: .value(L10n.t("chart.value"), item.1))
                    .foregroundStyle(CareMomTheme.lavender)
                PointMark(x: .value(L10n.t("chart.date"), item.0), y: .value(L10n.t("chart.value"), item.1))
            }
            .frame(height: 160)
        }
        .padding()
        .careMomCard()
    }
}

struct AddGrowthRecordView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    let child: Child

    @State private var date = Date.now
    @State private var weight = ""
    @State private var height = ""
    @State private var notes = ""

    private var parsedWeight: Double? {
        GrowthInputParser.parse(weight)
    }

    private var parsedHeight: Double? {
        GrowthInputParser.parse(height)
    }

    private var canSave: Bool {
        parsedWeight != nil || parsedHeight != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        ChildAvatarView(child: child, size: 64)
                        VStack(spacing: 4) {
                            Text(child.fullName)
                                .font(.headline)
                            Text(child.ageDescription(locale: locale))
                                .font(.caption)
                                .foregroundStyle(CareMomTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section(L10n.t("growth.measurement")) {
                    DatePicker(L10n.t("child.date"), selection: $date, displayedComponents: .date)
                    TextField(L10n.t("growth.weight_kg"), text: $weight)
                        .keyboardType(.decimalPad)
                    TextField(L10n.t("growth.height_cm"), text: $height)
                        .keyboardType(.decimalPad)
                }

                Section(L10n.t("entry.notes")) {
                    TextField(L10n.t("growth.comment"), text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let latest = child.latestGrowthRecord {
                    Section(L10n.t("growth.previous")) {
                        if let w = latest.weightKg {
                            LabeledContent(L10n.t("child.weight"), value: L10n.format("growth.weight_format", w))
                        }
                        if let h = latest.heightCm {
                            LabeledContent(L10n.t("child.height"), value: L10n.format("growth.height_format", h))
                        }
                        LabeledContent(L10n.t("child.date"), value: latest.date.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            }
            .navigationTitle(L10n.t("child.new_measurement"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("common.save")) { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let record = GrowthRecord(
            date: date,
            weightKg: parsedWeight,
            heightCm: parsedHeight,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            child: child
        )
        modelContext.insert(record)
        try? modelContext.save()
        HapticService.success()
        dismiss()
    }
}

private enum GrowthInputParser {
    static func parse(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}
