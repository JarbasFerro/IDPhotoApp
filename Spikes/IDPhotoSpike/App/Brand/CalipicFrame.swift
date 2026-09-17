import SwiftUI

/// The Calipic crop frame: the fixed brand element of the app icon (BD-036), as a reusable shape.
///
/// Same construction as `frame_paths` in scripts/brand/build-icon-v2.py: a rounded rectangle drawn as four open
/// segments. Small equal gaps interrupt it at the top centre, the bottom centre and the left centre; the two
/// right-hand corners are drawn for only part of their quarter turn, which leaves the right side wide open so the
/// frame reads as a capital C. The path is the stroke's centre line: stroke it with round caps
/// (`strokeStyle()`), and pass that width as `lineWidth` so the visible gaps come out as intended.
///
/// The shape is decorative. Callers hide it from assistive technologies and choose its colour: neutral or a status
/// colour over a photo, never the brand teal over a portrait (docs/brand/prototypes/08-frame-motif-in-product.md).
struct CalipicFrame: InsettableShape {
    /// Icon master values on the 1024 canvas: a 664-unit frame, radius 130, 30-unit visible gaps (the 72-unit stroke is the caller's).
    enum Icon {
        static let side: CGFloat = 664
        static let cornerRatio: CGFloat = 130 / side
        static let gapRatio: CGFloat = 30 / side
        static let rightSweepDegrees: CGFloat = 52
    }

    /// Corner radius as a fraction of the shorter side.
    var cornerRatio: CGFloat = Icon.cornerRatio
    /// Visible gap between the round caps, as a fraction of the shorter side.
    var gapRatio: CGFloat = Icon.gapRatio
    /// Degrees of each right-hand corner that are drawn, out of 90. Smaller opens the C wider.
    var rightSweepDegrees: CGFloat = Icon.rightSweepDegrees
    /// Width of the stroke the caller applies. Round caps extend half of it into each gap.
    var lineWidth: CGFloat = 0
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> CalipicFrame {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    /// Round caps, round joins: the icon's "identical rounded endpoints".
    func strokeStyle() -> StrokeStyle {
        StrokeStyle(lineWidth: max(lineWidth, 0), lineCap: .round, lineJoin: .round)
    }

    /// Centre-line geometry in the rect's coordinate space (y grows downwards).
    struct Geometry: Equatable {
        let rect: CGRect
        let radius: CGFloat
        /// Half the distance between two facing centre-line ends, caps excluded.
        let halfGap: CGFloat
        let sweepRadians: CGFloat

        var center: CGPoint { CGPoint(x: rect.midX, y: rect.midY) }
        /// Centre-line ends at the top gap, left then right. The bottom gap mirrors them.
        var topGap: (left: CGPoint, right: CGPoint) {
            (CGPoint(x: rect.midX - halfGap, y: rect.minY), CGPoint(x: rect.midX + halfGap, y: rect.minY))
        }
        var bottomGap: (left: CGPoint, right: CGPoint) {
            (CGPoint(x: rect.midX - halfGap, y: rect.maxY), CGPoint(x: rect.midX + halfGap, y: rect.maxY))
        }
        /// Centre-line ends at the left gap, upper then lower.
        var leftGap: (upper: CGPoint, lower: CGPoint) {
            (CGPoint(x: rect.minX, y: rect.midY - halfGap), CGPoint(x: rect.minX, y: rect.midY + halfGap))
        }
        /// Where the top right corner stops; the bottom one mirrors it.
        var topRightEnd: CGPoint {
            CGPoint(x: rect.maxX - radius + radius * sin(sweepRadians), y: rect.minY + radius * (1 - cos(sweepRadians)))
        }
        var bottomRightEnd: CGPoint { CGPoint(x: topRightEnd.x, y: rect.maxY - (topRightEnd.y - rect.minY)) }
        /// Height of the opening on the right, between the two corner ends.
        var opening: CGFloat { bottomRightEnd.y - topRightEnd.y }
    }

    func geometry(in rect: CGRect) -> Geometry {
        // An inset larger than the rect collapses to a point instead of CGRect.null, so every value stays finite.
        let inset = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let frame = inset.isNull || inset.isInfinite ? CGRect(x: rect.midX, y: rect.midY, width: 0, height: 0) : inset
        let side = max(min(frame.width, frame.height), 0)
        let radius = min(max(cornerRatio, 0) * side, side / 2)
        // A gap never eats more than the straight run between the centre line and the corner.
        let halfGap = min((max(gapRatio, 0) * side + max(lineWidth, 0)) / 2, max(side / 2 - radius, 0))
        let sweep = min(max(rightSweepDegrees, 0), 90) * .pi / 180
        return Geometry(rect: frame, radius: radius, halfGap: halfGap, sweepRadians: sweep)
    }

    func path(in rect: CGRect) -> Path {
        let g = geometry(in: rect)
        let r = g.rect
        guard r.width > 0, r.height > 0 else { return Path() }
        var path = Path()
        // Top left: from the top gap, round the corner, down to the left gap.
        path.move(to: g.topGap.left)
        path.addLine(to: CGPoint(x: r.minX + g.radius, y: r.minY))
        path.addArc(tangent1End: CGPoint(x: r.minX, y: r.minY), tangent2End: CGPoint(x: r.minX, y: r.minY + g.radius), radius: g.radius)
        path.addLine(to: g.leftGap.upper)
        // Bottom left, its mirror image.
        path.move(to: g.bottomGap.left)
        path.addLine(to: CGPoint(x: r.minX + g.radius, y: r.maxY))
        path.addArc(tangent1End: CGPoint(x: r.minX, y: r.maxY), tangent2End: CGPoint(x: r.minX, y: r.maxY - g.radius), radius: g.radius)
        path.addLine(to: g.leftGap.lower)
        // Right-hand corners stop after `rightSweepDegrees`: that is the opening of the C. Angles are measured in
        // the y-down space, so "up" is -90° and the top corner runs towards 0°.
        path.move(to: g.topGap.right)
        path.addLine(to: CGPoint(x: r.maxX - g.radius, y: r.minY))
        path.addArc(center: CGPoint(x: r.maxX - g.radius, y: r.minY + g.radius), radius: g.radius,
                    startAngle: .radians(-.pi / 2), endAngle: .radians(-.pi / 2 + g.sweepRadians), clockwise: false)
        path.move(to: g.bottomGap.right)
        path.addLine(to: CGPoint(x: r.maxX - g.radius, y: r.maxY))
        path.addArc(center: CGPoint(x: r.maxX - g.radius, y: r.maxY - g.radius), radius: g.radius,
                    startAngle: .radians(.pi / 2), endAngle: .radians(.pi / 2 - g.sweepRadians), clockwise: true)
        return path
    }
}

/// The frame used as a guide around or over a photo. Decorative: hidden from assistive technologies and never a hit
/// target. The caller picks the colour (neutral or a status colour, never the brand teal over a portrait); the line
/// gets heavier under Increase Contrast.
struct CalipicFrameGuide: View {
    let color: Color
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let width = Design.Stroke.guide(for: contrast)
        let frame = CalipicFrame(lineWidth: width)
        frame.strokeBorder(color, style: frame.strokeStyle())
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
