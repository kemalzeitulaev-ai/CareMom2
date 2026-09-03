import PhotosUI
import SwiftUI
import SwiftData

struct EditChildView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var child: Child

    @State private var firstName: String
    @State private var lastName: String
    @State private var dateOfBirth: Date
    @State private var gender: ChildGender
    @State private var bloodType: BloodType
    @State private var allergies: String
    @State private var chronicConditions: String
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    init(child: Child) {
        self.child = child
        _firstName = State(initialValue: child.firstName)
        _lastName = State(initialValue: child.lastName)
        _dateOfBirth = State(initialValue: child.dateOfBirth)
        _gender = State(initialValue: child.gender)
        _bloodType = State(initialValue: child.bloodType)
        _allergies = State(initialValue: child.allergies)
        _chronicConditions = State(initialValue: child.chronicConditions)
        _photoData = State(initialValue: child.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            PhotoPickerPreview(data: photoData ?? child.photoData, gender: gender, initial: firstName, size: 90)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                Section(L10n.t("child.basic")) {
                    genderPickerInline
                    TextField(L10n.t("child.first_name"), text: $firstName)
                    TextField(L10n.t("child.last_name"), text: $lastName)
                    DatePicker(L10n.t("child.date_of_birth"), selection: $dateOfBirth, displayedComponents: .date)
                    Picker(L10n.t("child.blood_type"), selection: $bloodType) {
                        ForEach(BloodType.allCases) { type in Text(type.title).tag(type) }
                    }
                }
                Section(L10n.t("child.health")) {
                    TextField(L10n.t("child.allergies"), text: $allergies, axis: .vertical)
                    TextField(L10n.t("child.chronic_conditions"), text: $chronicConditions, axis: .vertical)
                }
            }
            .navigationTitle(L10n.t("child.edit_profile"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.t("common.cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("common.save")) { save() }
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

    private var genderPickerInline: some View {
        Picker(L10n.t("child.gender"), selection: $gender) {
            ForEach(ChildGender.allCases) { g in
                Text(g.title).tag(g)
            }
        }
    }

    private func save() {
        child.firstName = firstName.trimmingCharacters(in: .whitespaces)
        child.lastName = lastName.trimmingCharacters(in: .whitespaces)
        child.dateOfBirth = dateOfBirth
        child.genderRaw = gender.rawValue
        child.bloodTypeRaw = bloodType.rawValue
        child.allergies = allergies
        child.chronicConditions = chronicConditions
        if let photoData { child.photoData = photoData }
        HapticService.success()
        dismiss()
    }
}
