import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Child.firstName) private var children: [Child]
    @Query(sort: \DiaryEntry.date, order: .reverse) private var allEntries: [DiaryEntry]
    @Query(sort: \MedicationCourse.createdAt, order: .reverse) private var allCourses: [MedicationCourse]
    @State private var appState = AppState()
    @State private var lockManager = AppLockManager()
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if lockManager.isEnabled && !lockManager.isUnlocked {
                AppLockView(lockManager: lockManager)
            } else {
                tabContent
            }
        }
        .onAppear {
            appState.ensureSelection(from: children)
            if children.isEmpty {
                showOnboarding = true
            }
            PendingActionHandler.processPendingActions(context: modelContext, children: children, appState: appState)
            syncWidgets()
            guard lockManager.isEnabled, !lockManager.isUnlocked else { return }
            Task { await lockManager.authenticate() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                syncWidgets()
                lockManager.lock()
            } else if phase == .active {
                syncWidgets()
                if lockManager.isEnabled, !lockManager.isUnlocked {
                    Task { await lockManager.authenticate() }
                }
            }
        }
        .onChange(of: appState.selectedChildID) { _, _ in syncWidgets() }
    }

    private func syncWidgets() {
        WidgetSyncService.sync(
            children: children,
            entries: allEntries,
            courses: allCourses,
            selectedChildID: appState.selectedChildID
        )
    }

    private var tabContent: some View {
        TabView {
            DiaryView(appState: appState)
                .tabItem { Label(String(localized: "tab.diary"), systemImage: "book.fill") }

            MedicationsView(appState: appState)
                .tabItem { Label(String(localized: "tab.medications"), systemImage: "pills.fill") }

            StatisticsView(appState: appState)
                .tabItem { Label(String(localized: "tab.statistics"), systemImage: "chart.bar.fill") }

            GalleryView(appState: appState)
                .tabItem { Label(String(localized: "tab.gallery"), systemImage: "photo.stack.fill") }

            NavigationStack {
                List {
                    NavigationLink { ChildrenListView() } label: {
                        Label(String(localized: "more.children"), systemImage: "figure.and.child.holdinghands")
                    }
                    NavigationLink { GrowthView(appState: appState) } label: {
                        Label(String(localized: "more.growth"), systemImage: "ruler")
                    }
                    NavigationLink { VaccinationView(appState: appState) } label: {
                        Label(String(localized: "more.vaccination"), systemImage: "syringe")
                    }
                    NavigationLink { SettingsView(lockManager: lockManager) } label: {
                        Label(String(localized: "more.settings"), systemImage: "gearshape.fill")
                    }
                }
                .navigationTitle(String(localized: "tab.more"))
            }
            .tabItem { Label(String(localized: "tab.more"), systemImage: "ellipsis.circle.fill") }
        }
        .tint(CareMomTheme.warmCoral)
        .onChange(of: children.count) { _, count in
            appState.ensureSelection(from: children)
            if count == 0 { showOnboarding = true }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(appState: appState)
        }
    }
}

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var appState: AppState
    @State private var showAddChild = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(CareMomTheme.warmCoral)
                VStack(spacing: 12) {
                    Text(L10n.t("onboarding.welcome"))
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(L10n.t("onboarding.subtitle"))
                        .font(.body)
                        .foregroundStyle(CareMomTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                Spacer()
                Button(L10n.t("onboarding.add_child")) { showAddChild = true }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .background(CareMomTheme.creamBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("onboarding.later")) { dismiss() }
                }
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView(onSaved: { child in
                    appState.selectedChildID = child.id
                    dismiss()
                })
            }
        }
        .interactiveDismissDisabled()
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("appLanguage") private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = false
    @Query(sort: \Child.firstName) private var children: [Child]
    @Bindable var lockManager: AppLockManager
    @State private var backupURL: URL?
    @State private var showShareBackup = false
    @State private var showFamilyShare = false
    @State private var showImportPicker = false
    @State private var importMessage: String?
    @State private var exportErrorMessage: String?

    var body: some View {
        Form {
            Section(String(localized: "settings.appearance")) {
                Picker(String(localized: "settings.theme"), selection: $appearance) {
                    Text(String(localized: "settings.theme.system")).tag("system")
                    Text(String(localized: "settings.theme.light")).tag("light")
                    Text(String(localized: "settings.theme.dark")).tag("dark")
                }
                Picker(String(localized: "settings.language"), selection: $appLanguageRaw) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language.rawValue)
                    }
                }
            }

            Section(String(localized: "settings.family")) {
                Toggle(String(localized: "settings.icloud"), isOn: $iCloudSyncEnabled)
                    .disabled(true)
                Text(String(localized: "settings.icloud.paid_hint"))
                    .font(.caption)
                    .foregroundStyle(CareMomTheme.textSecondary)
                Button(String(localized: "settings.family.share")) {
                    backupURL = try? FamilyShareService.exportForFamily(children: children)
                    showFamilyShare = backupURL != nil
                }
                Text(String(localized: "settings.family.hint"))
                    .font(.caption)
                    .foregroundStyle(CareMomTheme.textSecondary)
            }

            Section(String(localized: "settings.security")) {
                Toggle(String(localized: "settings.faceid"), isOn: Binding(
                    get: { lockManager.isEnabled },
                    set: { lockManager.setEnabled($0) }
                ))
            }

            Section(String(localized: "settings.backup")) {
                Text(L10n.t("settings.backup.hint"))
                    .font(.caption)
                    .foregroundStyle(CareMomTheme.textSecondary)
                Button(String(localized: "settings.export")) {
                    do {
                        backupURL = try BackupService.exportData(children: children)
                        exportErrorMessage = nil
                        showShareBackup = backupURL != nil
                    } catch {
                        exportErrorMessage = L10n.format("settings.export.failed", error.localizedDescription)
                    }
                }
                Button(String(localized: "settings.import")) {
                    showImportPicker = true
                }
                if let importMessage {
                    Text(importMessage)
                        .font(.caption)
                        .foregroundStyle(CareMomTheme.warmCoral)
                }
                if let exportErrorMessage {
                    Text(exportErrorMessage)
                        .font(.caption)
                        .foregroundStyle(CareMomTheme.warmCoral)
                }
            }

            Section(String(localized: "settings.about")) {
                LabeledContent(String(localized: "settings.version"), value: AppInfo.versionLabel)
                LabeledContent("CareMom", value: String(localized: "settings.tagline"))
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label(String(localized: "settings.privacy_policy"), systemImage: "hand.raised")
                }
            }

            Section {
                Text(String(localized: "settings.widgets.hint"))
                    .font(.caption)
                    .foregroundStyle(CareMomTheme.textSecondary)
            }
        }
        .navigationTitle(String(localized: "more.settings"))
        .onAppear { iCloudSyncEnabled = ModelContainerFactory.iCloudSyncEnabled }
        .onChange(of: iCloudSyncEnabled) { _, value in
            ModelContainerFactory.iCloudSyncEnabled = value
        }
        .sheet(isPresented: $showShareBackup) {
            #if canImport(UIKit)
            if let backupURL {
                ShareSheet(items: [backupURL])
            }
            #endif
        }
        .sheet(isPresented: $showFamilyShare) {
            #if canImport(UIKit)
            if let backupURL {
                ShareSheet(items: [backupURL])
            }
            #endif
        }
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                do {
                    let count = try BackupService.importData(from: url, context: modelContext)
                    importMessage = L10n.format("settings.import.success", count)
                    HapticService.success()
                } catch {
                    importMessage = L10n.format("settings.import.error", error.localizedDescription)
                }
            case .failure(let error):
                importMessage = error.localizedDescription
            }
        }
    }
}

#if canImport(UIKit)
import UIKit
#endif
