import Foundation

/// The digital file a document produces: exact pixels and, when the receiving service states them, byte limits.
struct DigitalOutputSpec: Sendable, Hashable {
    let pixels: OutputPixels
    let minBytes: Int?
    let maxBytes: Int?
    /// The receiving service crops the photo itself (UK online), so the file keeps more room around the head.
    let looseFraming: Bool

    /// Zoom divisor for loose framing: head and shoulders with margin, never a tight crop.
    static let looseZoomFactor = 1.25

    /// The trim the digital file is rendered at: the document's width, the height following the pixel aspect.
    func format(base: PhotoFormat) -> PhotoFormat {
        PhotoFormat(id: "\(base.id)-digital", widthMM: base.widthMM,
                    heightMM: base.widthMM * Double(pixels.height) / Double(pixels.width), output: pixels)
    }

    /// The edit used for the digital file; loose framing zooms out within the editor's bounds.
    func adjustment(for edit: CropAdjustment) -> CropAdjustment {
        guard looseFraming else { return edit }
        var result = edit
        result.zoom = edit.zoom / Self.looseZoomFactor
        return result.clamped()
    }
}

/// Everything the pipeline needs to render one document. Pure values: no catalog lookups in the imaging layer.
struct RenderTarget: Sendable, Hashable {
    let format: PhotoFormat
    let spec: CompositionSpec
    let digital: DigitalOutputSpec
    let fileBaseName: String

    /// The pre-catalog behaviour (Spain DNI engineering preset); the default for tests and fallbacks.
    static let spainPrototype = RenderTarget(
        format: .spainPrototype, spec: .icaoEngineeringDefault,
        digital: DigitalOutputSpec(pixels: PhotoFormat.spainPrototype.output, minBytes: nil, maxBytes: nil, looseFraming: false),
        fileBaseName: "Foto-carnet")
}

/// The document the session is making photos for: an official catalog profile, or a custom size with no rules.
enum DocumentChoice: Sendable, Hashable, Identifiable {
    case official(DocumentProfile)
    case custom(widthMM: Double, heightMM: Double)

    static let defaultProfileID = "es.national-id.dni"
    /// Accepted custom sizes, each side, in millimetres. Keeps a photo smaller than every catalog paper.
    static let customSizeRange: ClosedRange<Double> = 10...100

    static var initial: DocumentChoice {
        ProfileCatalog.bundled.profile(defaultProfileID).map { .official($0) } ?? .custom(widthMM: 26, heightMM: 32)
    }

    var id: String {
        switch self {
        case .official(let profile): profile.profileId
        case let .custom(width, height): "custom-\(width)x\(height)"
        }
    }

    var profile: DocumentProfile? {
        if case .official(let profile) = self { return profile }
        return nil
    }

    var isCustom: Bool { profile == nil }

    var format: PhotoFormat {
        switch self {
        case .official(let profile):
            if let frame = profile.referenceFrameMm {
                return PhotoFormat.format(widthMM: frame.width, heightMM: frame.height)
            }
            if let digital = profile.digitalOutput, let width = digital.pixelWidth, let height = digital.pixelHeight {
                // Digital-only profile: a nominal trim at the app's pixels-per-millimetre policy.
                return PhotoFormat(id: profile.profileId,
                                   widthMM: Double(width) / PhotoFormat.pixelsPerMM, heightMM: Double(height) / PhotoFormat.pixelsPerMM,
                                   output: OutputPixels(width: width, height: height))
            }
            return .spainPrototype
        case let .custom(width, height):
            return PhotoFormat.format(widthMM: width, heightMM: height)
        }
    }

    /// Official bands where the catalog states them; the framing target always comes from the catalog.
    /// Custom sizes use the app's engineering defaults (never an official claim).
    var composition: CompositionSpec {
        var spec = CompositionSpec.icaoEngineeringDefault
        guard let profile else { return spec }
        let frameHeight = profile.referenceFrameMm?.height
        spec.headHeightTarget = profile.framingTarget.headHeightPercent / 100
        spec.eyeLineTarget = (100 - profile.framingTarget.eyeLineFromBottomPercent) / 100
        if let head = profile.composition.headHeight, let range = Self.fractions(head, frameHeight: frameHeight) {
            spec.headHeightRange = range
        }
        if let eye = profile.composition.eyeLine, let range = Self.fractions(eye, frameHeight: frameHeight) {
            // The catalog measures the eye line from the bottom edge; the solver measures from the top.
            spec.eyeLineRange = (1 - range.upperBound)...(1 - range.lowerBound)
        }
        return spec
    }

    static func fractions(_ constraint: DocumentProfile.Constraint, frameHeight: Double?) -> ClosedRange<Double>? {
        switch constraint.unit {
        case "percent_output_height":
            return (constraint.minInclusive / 100)...(constraint.maxInclusive / 100)
        case "mm":
            guard let frameHeight, frameHeight > 0 else { return nil }
            return (constraint.minInclusive / frameHeight)...(constraint.maxInclusive / frameHeight)
        default:
            return nil
        }
    }

    var backgroundColor: BackgroundColor {
        profile.flatMap { BackgroundColor(hex: $0.background.replacementColor) } ?? .white
    }

    var digital: DigitalOutputSpec {
        if let output = profile?.digitalOutput, let width = output.pixelWidth, let height = output.pixelHeight {
            return DigitalOutputSpec(pixels: OutputPixels(width: width, height: height),
                                     minBytes: output.fileSizeBytes?.min, maxBytes: output.fileSizeBytes?.max,
                                     looseFraming: output.composition == "loose")
        }
        return DigitalOutputSpec(pixels: format.output, minBytes: nil, maxBytes: nil, looseFraming: false)
    }

    /// Digital-only profiles (Saudi Absher) have no print route.
    var supportsPrint: Bool { profile.map { $0.printOutput != nil } ?? true }
    /// Australia and the UK: home prints are not accepted, so printing goes through a shop.
    var printIsShopOnly: Bool { profile?.printOutput?.route == "shop_only" }
    var printNoteKey: String? { profile?.printOutput?.noteKey }

    var fileBaseName: String {
        switch self {
        case .official(let profile): profile.jurisdiction.countryCode == "ES" ? "Foto-carnet" : "ID-photo"
        case .custom: "Photo"
        }
    }

    var renderTarget: RenderTarget {
        RenderTarget(format: format, spec: composition, digital: digital, fileBaseName: fileBaseName)
    }
}

extension BackgroundColor {
    /// "#RRGGBB" from the catalog.
    init?(hex: String) {
        guard hex.count == 7, hex.hasPrefix("#"), let value = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        self.init(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }
}
