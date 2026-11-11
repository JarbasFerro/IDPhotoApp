import Foundation

/// One official document profile, decoded from the bundled rules catalog (Rules/catalog/v1, schema 1).
/// Only the fields the app uses are decoded; the catalog validator owns the full schema (docs/05 §12).
struct DocumentProfile: Sendable, Hashable, Identifiable, Decodable {
    struct Jurisdiction: Sendable, Hashable, Decodable {
        let countryCode: String?
        let regionCode: String?
    }

    struct Document: Sendable, Hashable, Decodable {
        let type: String
        let variant: String
        let nameKey: String
        let localName: String?
    }

    struct Effective: Sendable, Hashable, Decodable {
        let lastReviewed: String
    }

    struct Frame: Sendable, Hashable, Decodable {
        let width: Double
        let height: Double
    }

    struct FileSize: Sendable, Hashable, Decodable {
        let min: Int?
        let max: Int?
    }

    struct Output: Sendable, Hashable, Decodable {
        let id: String
        let kind: String
        let physicalWidthMm: Double?
        let physicalHeightMm: Double?
        let minPpi: Double?
        let route: String?
        let noteKey: String?
        let pixelWidth: Int?
        let pixelHeight: Int?
        let fileSizeBytes: FileSize?
        let composition: String?
    }

    struct Constraint: Sendable, Hashable, Decodable {
        let landmarks: [String]
        let unit: String
        let minInclusive: Double
        let maxInclusive: Double
        let capability: String
    }

    struct Composition: Sendable, Hashable, Decodable {
        let headHeight: Constraint?
        let eyeLine: Constraint?
        let faceWidth: Constraint?
    }

    struct FramingTarget: Sendable, Hashable, Decodable {
        let headHeightPercent: Double
        let eyeLineFromBottomPercent: Double
        let basis: String
    }

    struct Background: Sendable, Hashable, Decodable {
        let requiredAppearance: String
        let allowedColors: [String]
        let replacementColor: String
        let officialEditingRule: String
    }

    struct Check: Sendable, Hashable, Decodable {
        let id: String
        let capability: String
    }

    struct Source: Sendable, Hashable, Decodable {
        let sourceId: String
        let authorityName: String
        let title: String
        let url: String
        let accessedDate: String
    }

    let profileId: String
    let profileVersion: String
    let jurisdiction: Jurisdiction
    let document: Document
    let effective: Effective
    let referenceFrameMm: Frame?
    let outputs: [Output]
    let composition: Composition
    let framingTarget: FramingTarget
    let background: Background
    let recencyMonths: Int?
    let checks: [Check]
    let profileQuestions: [String]
    let sources: [Source]

    var id: String { profileId }
    var printOutput: Output? { outputs.first { $0.kind == "print" } }
    var digitalOutput: Output? { outputs.first { $0.kind == "digital" } }
}

/// A shortcut size offered for custom photos (ADR-018). Sizes, never document names.
struct CustomSizeShortcut: Sendable, Hashable, Identifiable, Decodable {
    let id: String
    let widthMm: Double
    let heightMm: Double
    let nameKey: String
    /// Locale identifiers such as "es-MX" mapped to a localized name key ("Tamaño infantil").
    let localeNameKeys: [String: String]
}

struct ProfileCatalog: Sendable, Decodable {
    struct CustomSizes: Sendable, Decodable {
        struct Options: Sendable, Decodable { let blackAndWhite: Bool }
        let shortcuts: [CustomSizeShortcut]
        let options: Options
    }

    let schemaVersion: Int
    let catalogVersion: String
    let profiles: [DocumentProfile]
    let customSizes: CustomSizes

    static let resourceName = "CalipicCatalog"

    static func load(from data: Data) throws -> ProfileCatalog {
        let catalog = try JSONDecoder().decode(ProfileCatalog.self, from: data)
        guard catalog.schemaVersion == 1 else { throw CatalogError.unsupportedSchema(catalog.schemaVersion) }
        return catalog
    }

    static func loadBundled(_ bundle: Bundle = .main) throws -> ProfileCatalog {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else { throw CatalogError.missing }
        return try load(from: Data(contentsOf: url))
    }

    /// The bundled catalog, loaded once. An unreadable catalog leaves only custom sizes available.
    static let bundled: ProfileCatalog = (try? loadBundled())
        ?? ProfileCatalog(schemaVersion: 1, catalogVersion: "unavailable", profiles: [],
                          customSizes: CustomSizes(shortcuts: [], options: .init(blackAndWhite: false)))

    func profile(_ id: String) -> DocumentProfile? { profiles.first { $0.profileId == id } }

    enum CatalogError: Error { case missing, unsupportedSchema(Int) }
}
