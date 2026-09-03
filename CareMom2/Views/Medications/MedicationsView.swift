import SwiftUI
import SwiftData

struct MedicationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.firstName) private var children: [Child]
    @Query(sort: \MedicationCourse.createdAt, order: .reverse) private var allCourses: [MedicationCourse]

    @Bindable var appState: AppState
    @State private var addCourseSheet: ChildSheetRoute?

    private var activeCourses: [MedicationCourse] {
        guard let child = appState.selectedChild(from: children) else { return [] }
        return allCourses.filter { $0.child?.id == child.id && $0.isActive }
    }

    var body: some View {
        NavigationStack {
            Group {
                if children.isEmpty {
                    ContentUnavailableView(L10n.t("empty.add_child_title"), systemImage: "person.crop.circle.badge.plus")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            if children.count > 1 {
                                ChildSelectorBar(children: children, selectedChildID: $appState.selectedChildID)
                            }

                            if activeCourses.isEmpty {
                                ContentUnavailableView {
                                    Label(L10n.t("meds.no_active"), systemImage: "pills")
                                } description: {
                                    Text(L10n.t("meds.no_active_hint"))
                                }
                                .padding(.top, 60)
                            } else {
                                ForEach(activeCourses, id: \.id) { course in
                                    MedicationCourseCard(course: course)
                                }
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CareMomTheme.creamBackground)
            .overlay(alignment: .bottomTrailing) {
                if !children.isEmpty {
                    QuickAddFAB {
                        appState.ensureSelection(from: children)
                        guard let child = appState.selectedChild(from: children) else { return }
                        addCourseSheet = ChildSheetRoute(child: child)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(L10n.t("meds.title"))
            .sheet(item: $addCourseSheet) { route in
                AddMedicationCourseView(child: route.child)
            }
            .onChange(of: children.count) { _, _ in
                appState.ensureSelection(from: children)
            }
            .onAppear {
                appState.ensureSelection(from: children)
                refreshCourseStatuses()
            }
        }
    }

    private func refreshCourseStatuses() {
        for course in allCourses {
            course.refreshCompletionStatus()
        }
    }
}

struct MedicationCourseCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var course: MedicationCourse

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name)
                        .font(.headline)
                        .foregroundStyle(CareMomTheme.textPrimary)
                    Text(course.dosage)
                        .font(.subheadline)
                        .foregroundStyle(CareMomTheme.textSecondary)
                }
                Spacer()
                if course.reminderEnabled {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(CareMomTheme.lavender)
                        .accessibilityLabel(L10n.t("meds.reminders_on"))
                } else {
                    Image(systemName: "bell.slash")
                        .foregroundStyle(CareMomTheme.textSecondary.opacity(0.6))
                        .accessibilityLabel(L10n.t("meds.reminders_off"))
                }
                Menu {
                    if course.reminderEnabled {
                        Button {
                            course.setRemindersEnabled(false)
                            HapticService.light()
                        } label: {
                            Label(L10n.t("meds.disable_reminders"), systemImage: "bell.slash")
                        }
                    } else {
                        Button {
                            course.setRemindersEnabled(true)
                            HapticService.success()
                        } label: {
                            Label(L10n.t("meds.enable_reminders"), systemImage: "bell")
                        }
                    }
                    Button(L10n.t("meds.delete_course"), role: .destructive) {
                        showDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(CareMomTheme.warmCoral)
                        .padding(.leading, 4)
                }
            }

            HStack {
                Label(L10n.format("meds.days_short", course.durationDays), systemImage: "calendar")
                Spacer()
                Label(L10n.format("meds.times_per_day", course.timesPerDay), systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(CareMomTheme.textSecondary)

            ProgressView(value: course.progress) {
                Text(L10n.t("meds.course_progress"))
                    .font(.caption)
            }
            .tint(CareMomTheme.warmCoral)

            if let nextIntake = course.intakeLogs.first(where: { !$0.wasTaken && !$0.wasSkipped }) {
                HStack(spacing: 8) {
                    Button {
                        nextIntake.markTaken()
                        HapticService.success()
                    } label: {
                        Label(L10n.t("meds.taken"), systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(CareMomTheme.softPeach.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .foregroundStyle(CareMomTheme.warmCoral)

                    Button {
                        nextIntake.markSkipped()
                        HapticService.light()
                    } label: {
                        Text(L10n.t("meds.skip"))
                            .font(.caption.weight(.semibold))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(CareMomTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .foregroundStyle(CareMomTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .careMomCard()
        .confirmationDialog(
            L10n.t("meds.delete_course_confirm"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.t("meds.delete_course"), role: .destructive) {
                deleteCourse()
            }
        } message: {
            Text(L10n.t("meds.delete_course_message"))
        }
    }

    private func deleteCourse() {
        NotificationService.shared.cancelReminder(for: course.id)
        modelContext.delete(course)
        HapticService.success()
    }
}

struct AddMedicationCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let child: Child

    @State private var name = ""
    @State private var dosage = ""
    @State private var durationDays = 5
    @State private var timesPerDay = 3
    @State private var reminderEnabled = true
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.t("meds.medication")) {
                    TextField(L10n.t("meds.name"), text: $name)
                    TextField(L10n.t("meds.dosage"), text: $dosage)
                }

                Section(L10n.t("meds.course")) {
                    Stepper(L10n.format("meds.days_stepper", durationDays), value: $durationDays, in: 1...30)
                    Stepper(L10n.format("meds.doses_stepper", timesPerDay), value: $timesPerDay, in: 1...6)
                    DatePicker(L10n.t("meds.first_reminder"), selection: $reminderTime, displayedComponents: .hourAndMinute)
                    Toggle(L10n.t("meds.push_reminders"), isOn: $reminderEnabled)
                }
            }
            .navigationTitle(L10n.t("meds.new_course"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("meds.create")) { saveCourse() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveCourse() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let course = MedicationCourse(
            name: name,
            dosage: dosage,
            durationDays: durationDays,
            timesPerDay: timesPerDay,
            reminderHour: components.hour ?? 8,
            reminderMinute: components.minute ?? 0,
            reminderEnabled: reminderEnabled,
            child: child
        )
        course.reminderTimesRaw = MedicationCourse.reminderTimes(
            firstHour: components.hour ?? 8,
            firstMinute: components.minute ?? 0,
            count: timesPerDay
        )
        course.generateIntakeSchedule()
        modelContext.insert(course)

        if reminderEnabled {
            Task {
                _ = await NotificationService.shared.requestAuthorization()
                NotificationService.shared.scheduleMedicationReminder(for: course)
            }
        }
        dismiss()
    }
}
