#if canImport(UIKit)
import UIKit
#endif
import PhotosUI
import SwiftUI
import SwiftData

struct ChildrenListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.firstName) private var children: [Child]
    @State private var showAddChild = false

    var body: some View {
        NavigationStack {
            Group {
                if children.isEmpty {
                    ContentUnavailableView {
                        Label(L10n.t("empty.no_profiles_title"), systemImage: "figure.and.child.holdinghands")
                    } description: {
                        Text(L10n.t("empty.add_profile_hint"))
                    } actions: {
                        Button(L10n.t("onboarding.add_child")) { showAddChild = true }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(children, id: \.id) { child in
                            NavigationLink {
                                ChildDetailView(child: child)
                            } label: {
                                ChildRow(child: child)
                            }
                        }
                        .onDelete(perform: deleteChildren)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(CareMomTheme.creamBackground)
            .navigationTitle(L10n.t("children.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddChild = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(CareMomTheme.warmCoral)
                    }
                }
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView()
            }
        }
    }

    private func deleteChildren(at offsets: IndexSet) {
        for index in offsets {
            let child = children[index]
            for course in child.medicationCourses {
                NotificationService.shared.cancelReminder(for: course.id)
            }
            modelContext.delete(child)
        }
    }
}

struct ChildRow: View {
    @Environment(\.locale) private var locale
    let child: Child

    var body: some View {
        HStack(spacing: 14) {
            ChildAvatarView(child: child, size: 50)
            VStack(alignment: .leading, spacing: 4) {
                Text(child.fullName)
                    .font(.headline)
                    .foregroundStyle(CareMomTheme.textPrimary)
                Text("\(child.ageDescription(locale: locale)) · \(child.bloodType.title)")
                    .font(.caption)
                    .foregroundStyle(CareMomTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ChildDetailView: View {
    @Environment(\.locale) private var locale
    @Bindable var child: Child
    @State private var exportURL: URL?
    @State private var showShare = false
    @State private var showEdit = false
    @State private var showAddGrowth = false
    @State private var pdfPeriod: StatsPeriod = .year
    @State private var pdfErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    ChildAvatarView(child: child, size: 100)
                    Text(child.fullName)
                        .font(.title2.weight(.bold))
                    Text(child.ageDescription(locale: locale))
                        .foregroundStyle(CareMomTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .careMomCard()

                infoSection(title: L10n.t("child.medical_info")) {
                    infoRow(L10n.t("child.gender"), child.gender.title)
                    infoRow(L10n.t("child.blood_type"), child.bloodType.title)
                    infoRow(L10n.t("child.allergies"), child.allergies.isEmpty ? L10n.t("child.none") : child.allergies)
                    infoRow(L10n.t("child.chronic"), child.chronicConditions.isEmpty ? L10n.t("child.none") : child.chronicConditions)
                }

                growthSection

                infoSection(title: L10n.t("child.stats")) {
                    infoRow(L10n.t("child.diary_entries"), "\(child.entries.count)")
                    infoRow(L10n.t("child.medication_courses"), "\(child.medicationCourses.count)")
                    infoRow(L10n.t("child.growth_measurements"), "\(child.growthRecords.count)")
                    infoRow(L10n.t("child.vaccinations_count"), "\(child.vaccinations.count)")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("child.pdf_export"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CareMomTheme.textSecondary)
                    Picker(L10n.t("child.period"), selection: $pdfPeriod) {
                        ForEach(StatsPeriod.allCases) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button(L10n.t("child.export_pdf")) {
                    let since = pdfPeriod == .all ? nil : pdfPeriod.startDate
                    if let url = PDFExportService.generateReport(for: child, entries: child.entries, since: since) {
                        exportURL = url
                        pdfErrorMessage = nil
                        showShare = true
                    } else {
                        pdfErrorMessage = L10n.t("pdf.export.failed")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(L10n.t("child.export_doctor_pdf")) {
                    if let url = PDFExportService.generateDoctorVisitReport(for: child, entries: child.entries) {
                        exportURL = url
                        pdfErrorMessage = nil
                        showShare = true
                    } else {
                        pdfErrorMessage = L10n.t("pdf.export.failed")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())

                if let pdfErrorMessage {
                    Text(pdfErrorMessage)
                        .font(.caption)
                        .foregroundStyle(CareMomTheme.warmCoral)
                }
            }
            .padding()
        }
        .background(CareMomTheme.creamBackground)
        .navigationTitle(child.firstName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(L10n.t("child.edit")) {
                    showEdit = true
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditChildView(child: child)
        }
        .sheet(isPresented: $showAddGrowth) {
            AddGrowthRecordView(child: child)
        }
        .sheet(isPresented: $showShare) {
            #if canImport(UIKit)
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
            #endif
        }
    }

    private var growthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("child.growth_section"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CareMomTheme.textSecondary)

            VStack(spacing: 0) {
                if let latest = child.latestGrowthRecord {
                    if let weight = latest.weightKg {
                        infoRow(L10n.t("child.weight"), L10n.format("growth.weight_format", weight))
                    }
                    if let height = latest.heightCm {
                        infoRow(L10n.t("child.height"), L10n.format("growth.height_format", height))
                    }
                    infoRow(L10n.t("child.date"), latest.date.formatted(date: .long, time: .omitted))
                } else {
                    Text(L10n.t("child.no_measurements"))
                        .foregroundStyle(CareMomTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                Button {
                    showAddGrowth = true
                } label: {
                    Label(
                        child.latestGrowthRecord == nil ? L10n.t("child.add_measurement") : L10n.t("child.new_measurement"),
                        systemImage: "plus.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(CareMomTheme.warmCoral)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .careMomCard()
        }
    }

    private func infoSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CareMomTheme.textSecondary)
            VStack(spacing: 0) {
                content()
            }
            .careMomCard()
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(CareMomTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(CareMomTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct AddChildView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var onSaved: ((Child) -> Void)?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var gender: ChildGender = .girl
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -2, to: .now) ?? .now
    @State private var bloodType: BloodType = .unknown
    @State private var allergies = ""
    @State private var chronicConditions = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            PhotoPickerPreview(data: photoData, gender: gender, initial: firstName, size: 90)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section(L10n.t("child.basic")) {
                    genderPicker
                    TextField(L10n.t("child.first_name"), text: $firstName)
                    TextField(L10n.t("child.last_name"), text: $lastName)
                    DatePicker(L10n.t("child.date_of_birth"), selection: $dateOfBirth, displayedComponents: .date)
                    Picker(L10n.t("child.blood_type"), selection: $bloodType) {
                        ForEach(BloodType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                }

                Section(L10n.t("child.health")) {
                    TextField(L10n.t("child.allergies"), text: $allergies, axis: .vertical)
                    TextField(L10n.t("child.chronic_conditions"), text: $chronicConditions, axis: .vertical)
                }
            }
            .navigationTitle(L10n.t("child.new_profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("common.save")) { saveChild() }
                        .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private var genderPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("child.gender"))
                .font(.subheadline)
                .foregroundStyle(CareMomTheme.textSecondary)
            HStack(spacing: 12) {
                ForEach(ChildGender.allCases) { option in
                    Button {
                        gender = option
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: option.icon)
                            Text(option.title)
                                .font(.subheadline.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(gender == option ? option.avatarBackground : CareMomTheme.cardBackground)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(gender == option ? option.accentColor : Color.clear, lineWidth: 2)
                        }
                        .foregroundStyle(gender == option ? option.accentColor : CareMomTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }

    private func saveChild() {
        let child = Child(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            dateOfBirth: dateOfBirth,
            photoData: photoData,
            gender: gender,
            bloodType: bloodType,
            allergies: allergies,
            chronicConditions: chronicConditions
        )
        modelContext.insert(child)
        onSaved?(child)
        dismiss()
    }
}

#if canImport(UIKit)
import UIKit

struct PhotoPickerPreview: View {
    let data: Data?
    var gender: ChildGender = .girl
    var initial: String = ""
    var size: CGFloat = 90

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(gender.avatarBackground)
                    if initial.isEmpty {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundStyle(gender.avatarForeground)
                    } else {
                        Text(String(initial.prefix(1)).uppercased())
                            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                            .foregroundStyle(gender.avatarForeground)
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
