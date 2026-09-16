import Foundation

/// Plain-language summary of everything the app measured about one photo, for the Photo Check screen.
/// Pure mapping from domain results to three headline states and at most five rows; no UI types.
struct PhotoCheckSummary: Hashable, Sendable {
    enum Headline: Hashable, Sendable { case checking, good, review, retake }

    struct Row: Identifiable, Hashable, Sendable {
        enum Topic: String, Hashable, Sendable { case face, framing, background, light, detail }
        let topic: Topic
        let state: CheckState
        /// Short title, e.g. "Head size".
        let title: LocalizedStringResource
        /// One sentence: what was found and, when needed, what to do.
        let detail: LocalizedStringResource
        var id: Topic { topic }

        static func == (lhs: Row, rhs: Row) -> Bool { lhs.topic == rhs.topic && lhs.state == rhs.state }
        func hash(into hasher: inout Hasher) { hasher.combine(topic); hasher.combine(state) }
    }

    let headline: Headline
    let rows: [Row]

    static let checking = PhotoCheckSummary(headline: .checking, rows: [])
}

enum CheckPresentation {
    /// - Parameters:
    ///   - entry: the photo's analysis, segmentation and tone state.
    ///   - whiteApplied: the crop uses the replaced white background.
    ///   - sourceIsSmall: the crop has fewer pixels than the output needs.
    static func summary(for entry: PhotoEntry, whiteApplied: Bool, sourceIsSmall: Bool) -> PhotoCheckSummary {
        if entry.isAnalyzing { return .checking }
        var rows: [PhotoCheckSummary.Row] = []

        // Face and framing.
        if entry.analysisUnavailable {
            rows.append(.init(topic: .face, state: .manualCheck, title: "Face",
                              detail: "Automatic checks are not available on this device. Frame the photo by hand and check it by eye."))
        } else if let analysis = entry.analysis {
            if analysis.faceCount == 0 {
                rows.append(.init(topic: .face, state: .fail, title: "Face", detail: "No face was found. Use a front-facing photo with good light."))
            } else if analysis.faceCount > 1 {
                rows.append(.init(topic: .face, state: .fail, title: "Face", detail: "More than one person was found. Use a photo with only you."))
            } else if let solution = analysis.solution {
                rows.append(faceRow(solution))
                rows.append(framingRow(solution))
            }
            if let smudge = analysis.lensSmudgeConfidence, smudge >= FaceAnalysis.smudgeThreshold {
                rows.append(.init(topic: .detail, state: .warn, title: "Sharpness",
                                  detail: "The lens may be smudged. Clean it and retake for a sharper photo."))
            }
        }

        // Background.
        if let segmentation = entry.segmentation {
            if whiteApplied {
                let state: CheckState = segmentation.quality.state == .pass ? .pass : .warn
                rows.append(.init(topic: .background, state: state, title: "Background",
                                  detail: state == .pass ? "Replaced with plain white." : "Replaced with white. Check the edges of the hair and shoulders."))
            } else {
                switch segmentation.background.state {
                case .pass: rows.append(.init(topic: .background, state: .pass, title: "Background", detail: "Plain and light."))
                case .warn: rows.append(.init(topic: .background, state: .warn, title: "Background", detail: "Not quite white. Turn on the white background in Adjust."))
                case .fail: rows.append(.init(topic: .background, state: segmentation.quality.state == .fail ? .fail : .warn, title: "Background",
                                              detail: segmentation.quality.state == .fail ? "Uneven or dark, and it could not be replaced. Retake against a plain wall." : "Uneven or dark. Turn on the white background in Adjust."))
                case .manualCheck: rows.append(.init(topic: .background, state: .manualCheck, title: "Background", detail: "Too little background is visible to judge. Check it by eye."))
                }
            }
        } else if !entry.isSegmenting, entry.analysis != nil || entry.analysisUnavailable {
            rows.append(.init(topic: .background, state: .manualCheck, title: "Background", detail: "Could not be checked. Make sure it is plain and light."))
        }

        // Light.
        if let tone = entry.toneAssessment {
            if tone.issues.isEmpty {
                rows.append(.init(topic: .light, state: .pass, title: "Light", detail: "Exposure and colour look right."))
            } else if tone.issues.contains(.clipped) {
                rows.append(.init(topic: .light, state: .warn, title: "Light", detail: "Parts of the face are too bright or too dark. Softer, even light works best."))
            } else if tone.issues.contains(.underexposed) {
                rows.append(.init(topic: .light, state: .warn, title: "Light", detail: "The face is dark. Face a window or a lamp and retake."))
            } else if tone.issues.contains(.overexposed) {
                rows.append(.init(topic: .light, state: .warn, title: "Light", detail: "The face is very bright. Step away from the light and retake."))
            } else {
                rows.append(.init(topic: .light, state: .pass, title: "Light", detail: "A colour tint was corrected automatically."))
            }
        }

        // Detail.
        if sourceIsSmall, !rows.contains(where: { $0.topic == .detail }) {
            rows.append(.init(topic: .detail, state: .warn, title: "Sharpness", detail: "The photo is small and may print soft. A closer or higher-quality photo is better."))
        }

        let headline: PhotoCheckSummary.Headline
        if rows.contains(where: { $0.state == .fail }) { headline = .retake }
        else if rows.contains(where: { $0.state == .warn || $0.state == .manualCheck }) { headline = .review }
        else { headline = .good }
        return PhotoCheckSummary(headline: headline, rows: rows)
    }

    private static func faceRow(_ solution: CropSolution) -> PhotoCheckSummary.Row {
        let pose = solution.checks.filter { [.roll, .yaw, .pitch].contains($0.kind) }
        if let bad = pose.first(where: { $0.state == .fail }) ?? pose.first(where: { $0.state == .warn }) {
            switch bad.kind {
            case .roll: return .init(topic: .face, state: bad.state, title: "Head", detail: "Your head is tilted. Keep it straight and retake.")
            case .yaw: return .init(topic: .face, state: bad.state, title: "Head", detail: "Your head is turned. Look straight at the camera and retake.")
            default: return .init(topic: .face, state: bad.state, title: "Head", detail: "The camera was above or below your eyes. Hold it at eye level and retake.")
            }
        }
        let levelled = solution.checks.first { $0.kind == .roll }?.measured.map { abs($0) > 0.5 } ?? false
        return .init(topic: .face, state: .pass, title: "Head", detail: levelled ? "Facing the camera. A small tilt was levelled." : "Facing the camera, straight and level.")
    }

    private static func framingRow(_ solution: CropSolution) -> PhotoCheckSummary.Row {
        let framing = solution.checks.filter { [.headHeight, .eyeLine, .headroom, .zoomRange, .resolution, .crown].contains($0.kind) }
        if let bad = framing.first(where: { $0.state == .fail }) {
            switch bad.kind {
            case .headroom: return .init(topic: .framing, state: .fail, title: "Framing", detail: "The top of the head is cut off. Retake with space above your head.")
            case .resolution: return .init(topic: .framing, state: .fail, title: "Framing", detail: "The face is too small in the photo. Move closer and retake.")
            default: return .init(topic: .framing, state: .fail, title: "Framing", detail: "The head cannot be framed to the official size. Retake a little farther away.")
            }
        }
        if let bad = framing.first(where: { $0.state == .warn }) {
            switch bad.kind {
            case .resolution: return .init(topic: .framing, state: .warn, title: "Framing", detail: "Framed to size. Face detail is limited; a closer photo prints sharper.")
            case .headroom: return .init(topic: .framing, state: .warn, title: "Framing", detail: "Framed to size, with little space above the head.")
            default: return .init(topic: .framing, state: .warn, title: "Framing", detail: "Framed to size, close to the limit. Check that the whole head fits.")
            }
        }
        if framing.contains(where: { $0.state == .manualCheck }) {
            return .init(topic: .framing, state: .manualCheck, title: "Framing", detail: "Hair or headwear rises above the head. Check that it fits by eye.")
        }
        let head = Int(((solution.headHeightFraction) * 100).rounded())
        return .init(topic: .framing, state: .pass, title: "Framing", detail: "Framed to the official size; the head fills \(head)% of the photo.")
    }

    static func title(for headline: PhotoCheckSummary.Headline) -> LocalizedStringResource {
        switch headline {
        case .checking: "Checking your photo…"
        case .good: "Looks good"
        case .review: "A few things to check"
        case .retake: "Better to retake"
        }
    }

    static func subtitle(for headline: PhotoCheckSummary.Headline) -> LocalizedStringResource {
        switch headline {
        case .checking: "Finding your face and preparing the background."
        case .good: "Everything we can measure is fine. Also check by eye: neutral expression, eyes open, no glare on glasses."
        case .review: "You can continue, or fix the items below first."
        case .retake: "This photo is unlikely to be accepted. A new one takes a minute."
        }
    }

    static func symbol(for headline: PhotoCheckSummary.Headline) -> String {
        switch headline {
        case .checking: "sparkle.magnifyingglass"
        case .good: "checkmark.seal"
        case .review: "exclamationmark.circle"
        case .retake: "arrow.counterclockwise.circle"
        }
    }

    static func symbol(for topic: PhotoCheckSummary.Row.Topic) -> String {
        switch topic {
        case .face: "face.smiling"
        case .framing: "person.crop.rectangle"
        case .background: "rectangle.fill"
        case .light: "sun.max"
        case .detail: "sparkles"
        }
    }
}
