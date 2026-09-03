import SwiftUI

enum ChildGender: String, Codable, CaseIterable, Identifiable {
    case boy
    case girl

    var id: String { rawValue }

    var title: String {
        switch self {
        case .boy: String(localized: "gender.boy")
        case .girl: String(localized: "gender.girl")
        }
    }

    var icon: String {
        switch self {
        case .boy: "figure.stand"
        case .girl: "figure.stand.dress"
        }
    }

    var avatarBackground: Color {
        switch self {
        case .boy: Color("BoyBlueSoft")
        case .girl: CareMomTheme.softPeach
        }
    }

    var avatarForeground: Color {
        switch self {
        case .boy: Color("BoyBlue")
        case .girl: CareMomTheme.warmCoral
        }
    }

    var accentColor: Color {
        avatarForeground
    }
}
