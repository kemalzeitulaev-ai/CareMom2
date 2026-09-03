import SwiftUI
import SwiftData

struct VaccinationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.firstName) private var children: [Child]
    @Query(sort: \VaccinationRecord.scheduledDate) private var allVaccines: [VaccinationRecord]

    @Bindable var appState: AppState
    @State private var addVaccineSheet: ChildSheetRoute?

    private var child: Child? { appState.selectedChild(from: children) }

    private var vaccines: [VaccinationRecord] {
        guard let child else { return [] }
        return allVaccines.filter { $0.child?.id == child.id }
    }

    private var recommended: [ScheduledVaccine] {
        guard let child else { return [] }
        return VaccinationScheduleService.recommendedSchedule(for: child.dateOfBirth, existing: vaccines)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if children.count > 1 {
                    ChildSelectorBar(children: children, selectedChildID: $appState.selectedChildID)
                }

                if !recommended.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.t("vac.recommended"))
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(recommended.prefix(6)) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name).font(.subheadline.weight(.medium))
                                    Text("\(item.ageLabel) · \(item.recommendedDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(CareMomTheme.textSecondary)
                                }
                                Spacer()
                                Button(L10n.t("vac.add")) {
                                    addRecommended(item)
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CareMomTheme.warmCoral)
                            }
                            .padding()
                            .careMomCard()
                            .padding(.horizontal)
                        }
                    }
                }

                if vaccines.isEmpty {
                    ContentUnavailableView(L10n.t("vac.empty"), systemImage: "syringe")
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 10) {
                        Text(L10n.t("vac.my_vaccinations"))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        ForEach(vaccines, id: \.id) { vaccine in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vaccine.name).font(.headline)
                                    Text(vaccine.scheduledDate.formatted(date: .long, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(CareMomTheme.textSecondary)
                                }
                                Spacer()
                                if vaccine.isCompleted {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                } else {
                                    Button(L10n.t("vac.done")) {
                                        vaccine.markCompleted()
                                        HapticService.success()
                                    }
                                    .buttonStyle(.plain)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(CareMomTheme.warmCoral)
                                }
                            }
                            .padding()
                            .careMomCard()
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(CareMomTheme.creamBackground)
        .navigationTitle(L10n.t("vac.title"))
        .onAppear { appState.ensureSelection(from: children) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.ensureSelection(from: children)
                    guard let child = appState.selectedChild(from: children) else { return }
                    addVaccineSheet = ChildSheetRoute(child: child)
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(CareMomTheme.warmCoral)
                }
            }
        }
        .sheet(item: $addVaccineSheet) { route in
            AddVaccinationView(child: route.child)
        }
    }

    private func addRecommended(_ item: ScheduledVaccine) {
        guard let child else { return }
        let record = VaccinationRecord(name: item.name, scheduledDate: item.recommendedDate, child: child)
        modelContext.insert(record)
        Task {
            _ = await NotificationService.shared.requestAuthorization()
            NotificationService.shared.scheduleVaccinationReminder(for: record, childName: child.firstName)
        }
        HapticService.success()
    }
}

struct AddVaccinationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let child: Child

    @State private var name = ""
    @State private var scheduledDate = Date.now
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker(L10n.t("vac.vaccine"), selection: $name) {
                    Text(L10n.t("vac.choose")).tag("")
                    ForEach(DefaultVaccine.allCases) { v in
                        Text(v.title).tag(v.title)
                    }
                }
                TextField(L10n.t("vac.custom_name"), text: $name)
                DatePicker(L10n.t("child.date"), selection: $scheduledDate, displayedComponents: .date)
                TextField(L10n.t("vac.notes"), text: $notes)
            }
            .navigationTitle(L10n.t("vac.new"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.t("common.cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("common.save")) {
                        let record = VaccinationRecord(name: name, scheduledDate: scheduledDate, notes: notes, child: child)
                        modelContext.insert(record)
                        Task {
                            _ = await NotificationService.shared.requestAuthorization()
                            NotificationService.shared.scheduleVaccinationReminder(for: record, childName: child.firstName)
                        }
                        HapticService.success()
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
        }
    }
}
