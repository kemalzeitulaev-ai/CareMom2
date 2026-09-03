import Foundation

enum L10n {
    static func t(_ key: String.LocalizationValue) -> String {
        String(localized: key)
    }

    static func t(_ key: String.LocalizationValue, locale: Locale) -> String {
        String(localized: key, locale: locale)
    }

    static func format(_ key: String.LocalizationValue, _ args: CVarArg...) -> String {
        String(format: String(localized: key), locale: Locale.current, arguments: args)
    }

    static func format(_ key: String.LocalizationValue, locale: Locale, _ args: CVarArg...) -> String {
        String(format: String(localized: key), locale: locale, arguments: args)
    }

    static var exportLocale: Locale {
        let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
        return AppLanguage(rawValue: raw)?.locale ?? .autoupdatingCurrent
    }
}
