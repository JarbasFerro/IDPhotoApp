import Foundation

/// Which document a launch starts on: the person's saved choice, else their region's default, else ask once.
/// Pure functions over strings so the rules are testable; the app owns the UserDefaults read and write.
enum DocumentStore {
    static let key = "selectedDocument"
    static let promptShownKey = "documentPromptShown"

    struct Start: Equatable {
        let choice: DocumentChoice
        /// No saved choice and no profile for the region: ask "What is the photo for?" once.
        let needsPrompt: Bool
    }

    static func encode(_ choice: DocumentChoice) -> String {
        switch choice {
        case .official(let profile): profile.profileId
        case let .custom(width, height): "custom:\(width)x\(height)"
        }
    }

    static func decode(_ stored: String, catalog: ProfileCatalog) -> DocumentChoice? {
        if stored.hasPrefix("custom:") {
            let parts = stored.dropFirst("custom:".count).split(separator: "x")
            guard parts.count == 2, let width = Double(parts[0]), let height = Double(parts[1]),
                  DocumentChoice.customSizeRange.contains(width), DocumentChoice.customSizeRange.contains(height) else { return nil }
            return .custom(widthMM: width, heightMM: height)
        }
        return catalog.profile(stored).map { .official($0) }
    }

    static func start(stored: String?, regionCode: String?, catalog: ProfileCatalog) -> Start {
        if let stored, let choice = decode(stored, catalog: catalog) { return Start(choice: choice, needsPrompt: false) }
        if let regionCode, let id = catalog.regionDefaults[regionCode.uppercased()], let profile = catalog.profile(id) {
            return Start(choice: .official(profile), needsPrompt: false)
        }
        return Start(choice: .initial, needsPrompt: true)
    }
}
