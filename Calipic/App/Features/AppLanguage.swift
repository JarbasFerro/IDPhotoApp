import Foundation

/// The app's own language choice (founder, 2026-11-14), stored the way iOS stores a per-app language: the app's
/// `AppleLanguages` default, which is also what Settings > Calipic > Language writes. iOS reads it when the app
/// starts, so a change applies the next time Calipic opens.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case english = "en"
    case spanish = "es"
    case portugueseBrazil = "pt-BR"

    var id: String { rawValue }

    static let choices: [AppLanguage] = [.english, .spanish, .portugueseBrazil]

    /// Each language in its own words, so it can be found whatever the current language is.
    var nativeName: String {
        switch self {
        case .automatic: ""
        case .english: "English"
        case .spanish: "Español"
        case .portugueseBrazil: "Português (Brasil)"
        }
    }

    private static let key = "AppleLanguages"

    /// The choice stored for this app only (not the iPhone's language list, which `UserDefaults.standard` falls
    /// back to when the app has none).
    static func stored(in defaults: UserDefaults = .standard) -> AppLanguage {
        guard let domain = Bundle.main.bundleIdentifier,
              let codes = defaults.persistentDomain(forName: domain)?[key] as? [String],
              let first = codes.first else { return .automatic }
        return choices.first { first == $0.rawValue || first.hasPrefix($0.rawValue + "-") } ?? .automatic
    }

    static func store(_ language: AppLanguage, in defaults: UserDefaults = .standard) {
        if language == .automatic {
            defaults.removeObject(forKey: key)
        } else {
            defaults.set([language.rawValue], forKey: key)
        }
    }

    /// The language the app is showing now, worked out by iOS at launch.
    static var running: String { Bundle.main.preferredLocalizations.first ?? "en" }
}
