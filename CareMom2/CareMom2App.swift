import SwiftUI
import SwiftData

@main
struct CareMom2App: App {
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("appLanguage") private var appLanguageRaw = AppLanguage.system.rawValue

    private let modelContainer: ModelContainer = ModelContainerFactory.make()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(colorScheme)
                .environment(\.locale, resolvedLocale)
                .id(appLanguageRaw)
        }
        .modelContainer(modelContainer)
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    private var resolvedLocale: Locale {
        AppLanguage(rawValue: appLanguageRaw)?.locale ?? .autoupdatingCurrent
    }
}
