import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    @Query(sort: \Child.firstName) private var children: [Child]
    @Query(sort: \DiaryEntry.date, order: .reverse) private var allEntries: [DiaryEntry]

    @Bindable var appState: AppState
    @State private var addEntrySheet: ChildSheetRoute?
    @State private var quickTempSheet: ChildSheetRoute?
    @State private var activitySheet: ActivitySheetRoute?
    @State private var showAddChild = false
    @State private var entryDetailSheet: EntrySheetRoute?
    @State private var searchText = ""
    @State private var filterType: EntryType?

    private var filteredEntries: [DiaryEntry] {
        guard let child = appState.selectedChild(from: children) else { return [] }
        return allEntries.filter { entry in
            guard entry.child?.id == child.id else { return false }
            if let filterType, entry.type != filterType { return false }
            if searchText.isEmpty { return true }
            let query = searchText.lowercased()
            return entry.displayTitle.lowercased().contains(query)
                || entry.notes.lowercased().contains(query)
                || entry.medicationName.lowercased().contains(query)
                || entry.symptoms.map(\.title).joined(separator: " ").lowercased().contains(query)
        }
    }

    private var groupedEntries: [(String, [DiaryEntry])] {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "d MMMM yyyy"
        let grouped = Dictionary(grouping: filteredEntries) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.sorted { $0.key > $1.key }.map { (formatter.string(from: $0.key), $0.value) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if children.isEmpty {
                    emptyChildrenState
                } else {
                    VStack(spacing: 0) {
                        if children.count > 1 {
                            ChildSelectorBar(children: children, selectedChildID: $appState.selectedChildID)
                                .padding(.vertical, 8)
                        }

                        diaryFilters

                        if filteredEntries.isEmpty {
                            emptyDiaryState
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                                    ForEach(groupedEntries, id: \.0) { day, entries in
                                        Section {
                                            ForEach(entries, id: \.id) { entry in
                                                Button {
                                                    entryDetailSheet = EntrySheetRoute(entry: entry)
                                                } label: {
                                                    DiaryEntryRow(entry: entry)
                                                }
                                                .buttonStyle(.plain)
                                                .contentShape(Rectangle())
                                            }
                                        } header: {
                                            HStack {
                                                Text(day)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(CareMomTheme.textSecondary)
                                                Spacer()
                                            }
                                            .padding(.horizontal)
                                            .padding(.top, 8)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 120)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CareMomTheme.creamBackground)
            .overlay(alignment: .bottomTrailing) {
                if !children.isEmpty {
                    VStack(spacing: 12) {
                        Button { openActivitySheet(.sleep) } label: {
                            Image(systemName: "moon.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(CareMomTheme.lavender.opacity(0.85)))
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                        .accessibilityLabel(String(localized: "quick.sleep.title"))

                        Button { openActivitySheet(.feeding) } label: {
                            Image(systemName: "fork.knife")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(CareMomTheme.primaryPink.opacity(0.9)))
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())
                        .accessibilityLabel(String(localized: "quick.feeding.title"))

                        Button {
                            openQuickTempSheet()
                        } label: {
                            Image(systemName: "thermometer.medium")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(CareMomTheme.lavender))
                                .shadow(color: CareMomTheme.lavender.opacity(0.4), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Circle())

                        QuickAddFAB {
                            openAddEntrySheet()
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(String(localized: "diary.title"))
            .searchable(text: $searchText, prompt: Text(String(localized: "diary.search")))
            .toolbar {
                if !children.isEmpty, let child = appState.selectedChild(from: children) {
                    ToolbarItem(placement: .topBarTrailing) {
                        ChildAvatarView(child: child, size: 32)
                    }
                }
            }
            .sheet(item: $addEntrySheet) { route in
                AddEntryView(child: route.child)
            }
            .sheet(item: $quickTempSheet) { route in
                QuickTemperatureView(child: route.child)
            }
            .sheet(item: $activitySheet) { route in
                QuickSleepFeedView(child: route.child, kind: route.kind)
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView(onSaved: { appState.selectedChildID = $0.id })
            }
            .sheet(item: $entryDetailSheet) { route in
                EntryDetailView(entry: route.entry)
            }
            .onChange(of: children.count) { _, _ in appState.ensureSelection(from: children) }
            .onAppear { appState.ensureSelection(from: children) }
        }
    }

    private func openAddEntrySheet() {
        appState.ensureSelection(from: children)
        guard let child = appState.selectedChild(from: children) else { return }
        addEntrySheet = ChildSheetRoute(child: child)
    }

    private func openQuickTempSheet() {
        appState.ensureSelection(from: children)
        guard let child = appState.selectedChild(from: children) else { return }
        quickTempSheet = ChildSheetRoute(child: child)
    }

    private func openActivitySheet(_ kind: QuickActivityKind) {
        appState.ensureSelection(from: children)
        guard let child = appState.selectedChild(from: children) else { return }
        activitySheet = ActivitySheetRoute(child: child, kind: kind)
    }

    private var diaryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(String(localized: "filter.all"), type: nil)
                ForEach(EntryType.allCases) { type in
                    filterChip(type.title.components(separatedBy: " / ").first ?? type.title, type: type)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func filterChip(_ title: String, type: EntryType?) -> some View {
        Button {
            filterType = type
        } label: {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(filterType == type ? CareMomTheme.warmCoral : CareMomTheme.cardBackground))
                .foregroundStyle(filterType == type ? .white : CareMomTheme.textPrimary)
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
    }

    private var emptyChildrenState: some View {
        ContentUnavailableView {
            Label(L10n.t("empty.add_child_title"), systemImage: "person.crop.circle.badge.plus")
        } description: {
            Text(L10n.t("empty.add_child_hint"))
        } actions: {
            Button(L10n.t("onboarding.add_child")) { showAddChild = true }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
        }
    }

    private var emptyDiaryState: some View {
        ContentUnavailableView {
            Label(L10n.t("empty.no_entries_title"), systemImage: "heart.text.square")
        } description: {
            Text(L10n.t("empty.no_entries_hint"))
        }
    }
}

struct DiaryEntryRow: View {
    let entry: DiaryEntry

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.type.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(CareMomTheme.entryColor(for: entry.type))
                .frame(width: 44, height: 44)
                .background(CareMomTheme.entryColor(for: entry.type).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CareMomTheme.textPrimary)
                HStack(spacing: 8) {
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                    if let temp = entry.temperature {
                        Text("\(String(format: "%.1f", temp))°").foregroundStyle(CareMomTheme.warmCoral)
                    }
                    if entry.photoData != nil {
                        Image(systemName: "photo").font(.caption2)
                    }
                    if entry.voiceNoteFilename != nil {
                        Image(systemName: "mic.fill").font(.caption2)
                    }
                }
                .font(.caption)
                .foregroundStyle(CareMomTheme.textSecondary)
                if !entry.notes.isEmpty {
                    Text(entry.notes).font(.caption).foregroundStyle(CareMomTheme.textSecondary).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(CareMomTheme.textSecondary.opacity(0.5))
        }
        .padding(14)
        .careMomCard()
    }
}
