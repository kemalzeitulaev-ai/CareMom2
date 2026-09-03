import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case ru
    case en

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: String(localized: "settings.language.system")
        case .ru: String(localized: "settings.language.ru")
        case .en: String(localized: "settings.language.en")
        }
    }

    var locale: Locale? {
        switch self {
        case .system: nil
        case .ru: Locale(identifier: "ru")
        case .en: Locale(identifier: "en")
        }
    }
}

private struct AppLocaleKey: EnvironmentKey {
    static let defaultValue: Locale = .autoupdatingCurrent
}

extension EnvironmentValues {
    var appLocale: Locale {
        get { self[AppLocaleKey.self] }
        set { self[AppLocaleKey.self] = newValue }
    }
}
