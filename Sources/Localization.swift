import Foundation

enum AppLanguage: String {
    case pt
    case en
    case es

    static var current: AppLanguage {
        if let override = ProcessInfo.processInfo.environment["SOTAO57_LANG"]?.lowercased(),
           !override.isEmpty {
            if override.hasPrefix("pt") { return .pt }
            if override.hasPrefix("es") { return .es }
            if override.hasPrefix("en") { return .en }
        }
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        if preferred.hasPrefix("pt") { return .pt }
        if preferred.hasPrefix("es") { return .es }
        return .en
    }
}

enum L10n {
    static var language: AppLanguage { AppLanguage.current }

    static func t(_ pt: String, en: String, es: String) -> String {
        switch AppLanguage.current {
        case .pt: return pt
        case .en: return en
        case .es: return es
        }
    }

    static var appName: String { "SOTAO57 macOS Tools" }

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
    }

    static let repoSlug = "fplamorim/sotao57-macos-tools"
    static let repoURL = URL(string: "https://github.com/fplamorim/sotao57-macos-tools")!
    static let releasesURL = URL(string: "https://github.com/fplamorim/sotao57-macos-tools/releases")!
}
