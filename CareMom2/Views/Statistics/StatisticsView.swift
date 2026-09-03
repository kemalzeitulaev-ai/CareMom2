import Charts
import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(sort: \Child.firstName) private var children: [Child]
    @Query private var allEntries: [DiaryEntry]

    @Bindable var appState: AppState
    @State private var period: StatsPeriod = .month

    private var child: Child? { appState.selectedChild(from: children) }

    private var entries: [DiaryEntry] {
        guard let child else { return [] }
        return allEntries.filter { $0.child?.id == child.id && $0.date >= period.startDate }
    }

    private var illnessEntriesThisYear: Int {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: .now)) ?? .now
        return entries.filter { $0.type == .illness && $0.date >= start }.count
    }

    private var illnessEntriesThisMonth: Int {
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
        return entries.filter { $0.type == .illness && $0.date >= start }.count
    }

    private var temperatureData: [(Date, Double)] {
        entries
            .compactMap { entry -> (Date, Double)? in
                guard let temp = entry.temperature else { return nil }
                return (entry.date, temp)
            }
            .sorted { $0.0 < $1.0 }
    }

    private var symptomCounts: [(Symptom, Int)] {
        var counts: [Symptom: Int] = [:]
        for entry in entries where entry.type == .illness {
            for symptom in entry.symptoms {
                counts[symptom, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }
    }

    private var medicationCount: Int {
        entries.filter { $0.type == .medication }.count
    }

    private var topMedications: [(String, Int)] {
        var counts: [String: Int] = [:]
        for entry in entries where entry.type == .medication && !entry.medicationName.isEmpty {
            counts[entry.medicationName, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if children.count > 1 {
                        ChildSelectorBar(children: children, selectedChildID: $appState.selectedChildID)
                    }

                    if child == nil {
                        ContentUnavailableView(L10n.t("empty.add_child_title"), systemImage: "chart.bar")
                    } else {
                        Picker(L10n.t("stats.period"), selection: $period) {
                            ForEach(StatsPeriod.allCases) { p in
                                Text(p.title).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)

                        statsGrid

                        if !temperatureData.isEmpty {
                            temperatureChart
                        }

                        if !symptomCounts.isEmpty {
                            symptomsChart
                        }

                        if !topMedications.isEmpty {
                            medicationsInsight
                        }

                        illnessCalendar
                    }
                }
                .padding()
            }
            .background(CareMomTheme.creamBackground)
            .navigationTitle(L10n.t("stats.title"))
            .onChange(of: children.count) { _, _ in
                appState.ensureSelection(from: children)
            }
            .onAppear {
                appState.ensureSelection(from: children)
            }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: L10n.t("stats.illness_this_month"), value: "\(illnessEntriesThisMonth)", icon: "heart.text.square", color: CareMomTheme.warmCoral)
            StatCard(title: L10n.t("stats.illness_this_year"), value: "\(illnessEntriesThisYear)", icon: "calendar", color: CareMomTheme.lavender)
            StatCard(title: L10n.t("stats.medications_taken"), value: "\(medicationCount)", icon: "pills.fill", color: CareMomTheme.primaryPink)
            StatCard(title: L10n.t("stats.total_entries"), value: "\(entries.count)", icon: "doc.text", color: CareMomTheme.softPeach)
        }
    }

    private var temperatureChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("stats.temperature_chart"))
                .font(.headline)
                .foregroundStyle(CareMomTheme.textPrimary)

            Chart(temperatureData, id: \.0) { item in
                LineMark(
                    x: .value(L10n.t("chart.date"), item.0),
                    y: .value("°C", item.1)
                )
                .foregroundStyle(CareMomTheme.warmCoral)
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value(L10n.t("chart.date"), item.0),
                    y: .value("°C", item.1)
                )
                .foregroundStyle(CareMomTheme.primaryPink)
                .symbolSize(40)
            }
            .frame(height: 200)
            .chartYScale(domain: 35...41)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine().foregroundStyle(CareMomTheme.textSecondary.opacity(0.2))
                    AxisValueLabel().foregroundStyle(CareMomTheme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(CareMomTheme.textSecondary.opacity(0.2))
                    AxisValueLabel().foregroundStyle(CareMomTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .careMomCard()
    }

    private var symptomsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("stats.symptoms_chart"))
                .font(.headline)
                .foregroundStyle(CareMomTheme.textPrimary)

            Chart(symptomCounts, id: \.0) { item in
                BarMark(
                    x: .value(L10n.t("chart.count"), item.1),
                    y: .value(L10n.t("chart.symptom"), item.0.title)
                )
                .foregroundStyle(CareMomTheme.lavender.gradient)
            }
            .frame(height: CGFloat(symptomCounts.count) * 36 + 20)
        }
        .padding(16)
        .careMomCard()
    }

    private var medicationsInsight: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("stats.top_medications"))
                .font(.headline)
                .foregroundStyle(CareMomTheme.textPrimary)

            ForEach(topMedications, id: \.0) { name, count in
                HStack {
                    Text(name)
                    Spacer()
                    Text("\(count)×")
                        .foregroundStyle(CareMomTheme.textSecondary)
                }
                .font(.subheadline)
            }
        }
        .padding(16)
        .careMomCard()
    }

    private var illnessCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("stats.illness_calendar"))
                .font(.headline)
                .foregroundStyle(CareMomTheme.textPrimary)

            let illnessDays = Set(entries.filter { $0.type == .illness }.map {
                Calendar.current.startOfDay(for: $0.date)
            })

            let days = (0..<30).compactMap { offset in
                Calendar.current.date(byAdding: .day, value: -offset, to: Calendar.current.startOfDay(for: .now))
            }.reversed()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(days), id: \.self) { day in
                    let isSick = illnessDays.contains(day)
                    VStack(spacing: 4) {
                        Text(day.formatted(.dateTime.day()))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(isSick ? .white : CareMomTheme.textSecondary)
                        Circle()
                            .fill(isSick ? CareMomTheme.warmCoral : CareMomTheme.softPeach.opacity(0.3))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if isSick {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                }
            }
        }
        .padding(16)
        .careMomCard()
    }
}

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week, month, year, all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: L10n.t("stats.period.week")
        case .month: L10n.t("stats.period.month")
        case .year: L10n.t("stats.period.year")
        case .all: L10n.t("stats.period.all")
        }
    }

    var startDate: Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        case .year:
            return calendar.date(from: calendar.dateComponents([.year], from: .now)) ?? .now
        case .all:
            return .distantPast
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title.weight(.bold))
                .foregroundStyle(CareMomTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(CareMomTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .careMomCard()
    }
}
