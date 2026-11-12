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
    /// Resolution of the page JPEGs for labs and kiosks: 300 ppi, or more when the document asks (Netherlands: 400).
    var pagePixelsPerInch: Double = SheetRenderer.jpegPixelsPerInch

    /// The pre-catalog behaviour (Spain DNI engineering preset); the default for tests and fallbacks.
    static let spainPrototype = RenderTarget(
        format: .spainPrototype, spec: .icaoEngineeringDefault,
        digital: DigitalOutputSpec(pixels: PhotoFormat.spainPrototype.output, minBytes: nil, maxBytes: nil, looseFraming: false),
        fileBaseName: "Foto-carnet")

    /// The same target framed closer or wider (custom sizes). Bands widen so the person's choice is never a warning.
    func framed(_ preset: FramingPreset) -> RenderTarget {
        guard preset != .standard else { return self }
        var spec = spec
        spec.headHeightTarget = preset.headHeightTarget
        spec.eyeLineTarget = preset.eyeLineTarget
        spec.headHeightRange = min(spec.headHeightRange.lowerBound, preset.headHeightTarget - 0.08)
            ... max(spec.headHeightRange.upperBound, preset.headHeightTarget + 0.05)
        return RenderTarget(format: format, spec: spec, digital: digital, fileBaseName: fileBaseName,
                            pagePixelsPerInch: pagePixelsPerInch)
    }
}

/// How much of the person a custom-size photo shows. Standard is the app default (head 74 %).
enum FramingPreset: String, Sendable, Hashable, CaseIterable, Identifiable {
    case wider, standard, closer
    var id: String { rawValue }

    /// Crown to chin as a fraction of the photo height.
    var headHeightTarget: Double {
        switch self { case .wider: 0.62; case .standard: 0.74; case .closer: 0.82 }
    }

    /// Eye line from the top. With crown-to-eye at 0.444 of the head (FaceGeometry), all three keep ≥ 7 % headroom.
    var eyeLineTarget: Double {
        switch self { case .wider: 0.40; case .standard: 0.42; case .closer: 0.44 }
    }
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

    /// The document's official wording asks for unedited photos. Recorded so the app can say so (ADR-051, docs/26 D4).
    var officialRulesForbidEditing: Bool { profile?.background.officialEditingRule == "disallowed" }

    /// What only a person can judge, from the profile's own checks. Print instructions are not photo checks.
    var byEyeChecks: [String] { profile?.checks.filter { $0.capability != "informational" }.map(\.id) ?? [] }

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
        RenderTarget(format: format, spec: composition, digital: digital, fileBaseName: fileBaseName,
                     pagePixelsPerInch: max(SheetRenderer.jpegPixelsPerInch, profile?.printOutput?.minPpi ?? 0))
    }

    /// Background colours offered in Adjust besides the original: the profile's colour, or two for custom sizes.
    var replacementColors: [BackgroundColor] {
        isCustom ? [.white, .lightGrey] : [backgroundColor]
    }
}

extension BackgroundColor {
    /// "#RRGGBB" from the catalog.
    init?(hex: String) {
        guard hex.count == 7, hex.hasPrefix("#"), let value = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        self.init(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }
}
