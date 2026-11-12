import Foundation

/// Where the top of the head, the eye line, and the chin fall on the finished photo for the person's current framing,
/// in fractions of the photo and in millimetres (docs/03-design.md U3, decision D-2).
///
/// Coordinate spaces: the face geometry is in normalized source-image space; the crop is in normalized source space
/// with a rotation about its centre (`CropAdjustment.rotationDegrees`, applied as R(−θ) in y-down image coordinates,
/// the same transform as `CropSolver` and `CropPreview`); the result is in photo space (0 at the top edge, 1 at the
/// bottom) and in millimetres of the printed photo.
struct PhotoMeasurement: Sendable, Hashable {
    /// Fractions of the photo height from its top edge.
    let crownY: Double
    let eyeY: Double
    let chinY: Double
    /// Fraction of the photo width of the eye midpoint, for drawing the eye line where the face is.
    let eyeX: Double
    let photoHeightMM: Double

    /// The head-height band of the document, in fractions of the photo height.
    let headRange: ClosedRange<Double>
    let eyeRange: ClosedRange<Double>
    /// True when the top of the head is an estimate (hair, headwear, or a weak outline), so the length is shown as "about".
    let crownIsEstimate: Bool

    var headFraction: Double { chinY - crownY }
    var headHeightMM: Double { headFraction * photoHeightMM }
    var headRangeMM: ClosedRange<Double> { (headRange.lowerBound * photoHeightMM)...(headRange.upperBound * photoHeightMM) }
    /// Eyes measured from the bottom edge, the way most official rules state it.
    var eyeHeightFromBottomMM: Double { (1 - eyeY) * photoHeightMM }
    var headInRange: Bool { headRange.contains(headFraction) }
    var eyesInRange: Bool { eyeRange.contains(eyeY) }

    static func measure(geometry g: FaceGeometry, adjustment: CropAdjustment, format: PhotoFormat,
                        spec: CompositionSpec) -> PhotoMeasurement? {
        guard g.faceCount == 1, g.source.width > 0, g.source.height > 0 else { return nil }
        let width = Double(g.source.width), height = Double(g.source.height)
        let crop = adjustment.crop(in: g.source, format: format)
        let cropW = crop.width * width, cropH = crop.height * height
        guard cropW > 0, cropH > 0 else { return nil }
        let centre = ImagePoint(x: (crop.x + crop.width / 2) * width, y: (crop.y + crop.height / 2) * height)
        let theta = adjustment.clamped().rotationDegrees * .pi / 180
        let c = cos(theta), s = sin(theta)

        /// Normalized source point → fraction of the photo, after levelling about the crop centre.
        func photoPoint(_ p: ImagePoint) -> (x: Double, y: Double) {
            let dx = p.x * width - centre.x, dy = p.y * height - centre.y
            let x = dx * c + dy * s, y = -dx * s + dy * c
            return ((x + cropW / 2) / cropW, (y + cropH / 2) / cropH)
        }
        let crown = photoPoint(g.crownPoint)
        let eyes = photoPoint(g.eyeMidpoint)
        let chin = photoPoint(g.chin)
        return PhotoMeasurement(crownY: crown.y, eyeY: eyes.y, chinY: chin.y, eyeX: eyes.x,
                                photoHeightMM: format.heightMM, headRange: spec.headHeightRange, eyeRange: spec.eyeLineRange,
                                crownIsEstimate: g.crown.hairVolume || g.crown.confidence < 0.8)
    }
}
