import SwiftUI
import Testing
import UIKit
@testable import IDPhotoSpike

/// The product frame must keep the icon's construction (BD-036): uniform stroke, equal small gaps at the top,
/// bottom and left centres, exact top/bottom mirror symmetry, and a clearly larger opening on the right.
struct CalipicFrameTests {
    private let iconRect = CGRect(x: 180, y: 180, width: 664, height: 664)
    private let iconFrame = CalipicFrame(lineWidth: 72)

    private func close(_ a: CGFloat, _ b: CGFloat, tolerance: CGFloat = 0.01) -> Bool { abs(a - b) <= tolerance }

    @Test func reproducesTheIconMasterNumbers() {
        let g = iconFrame.geometry(in: iconRect)
        #expect(close(g.radius, 130))
        // scripts/brand/build-icon-v2.py: g = (net_gap + stroke) / 2 = 51; the corner stops at sin/cos of 52°.
        #expect(close(g.halfGap, 51))
        #expect(close(g.topGap.left.x, 512 - 51) && close(g.topGap.right.x, 512 + 51))
        #expect(close(g.topRightEnd.x, 844 - 130 + 130 * sin(52 * .pi / 180)))
        #expect(close(g.topRightEnd.y, 180 + 130 * (1 - cos(52 * .pi / 180))))
    }

    @Test(arguments: [CGRect(x: 0, y: 0, width: 300, height: 300), CGRect(x: 12, y: 40, width: 260, height: 320),
                      CGRect(x: 0, y: 0, width: 320, height: 200)])
    func gapsSitOnTheCentreLinesAndAreEqual(rect: CGRect) {
        let g = CalipicFrame(lineWidth: 2).geometry(in: rect)
        #expect(close((g.topGap.left.x + g.topGap.right.x) / 2, rect.midX))
        #expect(close((g.bottomGap.left.x + g.bottomGap.right.x) / 2, rect.midX))
        #expect(close((g.leftGap.upper.y + g.leftGap.lower.y) / 2, rect.midY))
        let top = g.topGap.right.x - g.topGap.left.x
        #expect(close(g.bottomGap.right.x - g.bottomGap.left.x, top))
        #expect(close(g.leftGap.lower.y - g.leftGap.upper.y, top))
        // Visible gap = centre-line gap minus the two round caps.
        #expect(close(top - 2, CalipicFrame.Icon.gapRatio * min(rect.width, rect.height)))
        // The opening of the C is several times larger than the small gaps.
        #expect(g.opening > 4 * top)
    }

    @Test func topAndBottomAreMirrorImages() {
        let rect = CGRect(x: 10, y: 20, width: 260, height: 320)
        let frame = CalipicFrame(lineWidth: 6)
        let g = frame.geometry(in: rect)
        #expect(close(g.topRightEnd.x, g.bottomRightEnd.x))
        #expect(close(g.topRightEnd.y - rect.minY, rect.maxY - g.bottomRightEnd.y))
        let stroked = frame.path(in: rect).strokedPath(frame.strokeStyle())
        var mismatches = 0
        for x in stride(from: rect.minX - 8, through: rect.maxX + 8, by: 3) {
            for y in stride(from: rect.minY - 8, through: rect.midY, by: 3) {
                let mirrored = CGPoint(x: x, y: rect.minY + rect.maxY - y)
                if stroked.contains(CGPoint(x: x, y: y)) != stroked.contains(mirrored) { mismatches += 1 }
            }
        }
        #expect(mismatches == 0)
    }

    @Test func theRightSideIsOpenAndTheLeftSideIsDrawn() {
        let rect = CGRect(x: 0, y: 0, width: 260, height: 320)
        let frame = CalipicFrame(lineWidth: 6)
        let g = frame.geometry(in: rect)
        let stroked = frame.path(in: rect).strokedPath(frame.strokeStyle())
        // Drawn: left edge between corner and gap, both right-hand corner arcs part-way along their sweep.
        #expect(stroked.contains(CGPoint(x: rect.minX, y: rect.midY - 60)))
        #expect(stroked.contains(CGPoint(x: rect.minX, y: rect.midY + 60)))
        let half = g.sweepRadians / 2
        let onTopArc = CGPoint(x: rect.maxX - g.radius + g.radius * sin(half), y: rect.minY + g.radius * (1 - cos(half)))
        #expect(stroked.contains(onTopArc))
        #expect(stroked.contains(CGPoint(x: onTopArc.x, y: rect.maxY - (onTopArc.y - rect.minY))))
        // Open: the small gaps, and the whole right edge between the corner ends.
        // Slightly off the centre line: a hit test exactly through the caps' end points is degenerate in Core Graphics.
        #expect(!stroked.contains(CGPoint(x: rect.midX, y: rect.minY + 0.7)))
        #expect(!stroked.contains(CGPoint(x: rect.midX, y: rect.maxY - 0.7)))
        #expect(stroked.contains(CGPoint(x: rect.midX - 40, y: rect.minY + 0.7)))
        #expect(stroked.contains(CGPoint(x: rect.midX + 40, y: rect.maxY - 0.7)))
        #expect(!stroked.contains(CGPoint(x: rect.minX, y: rect.midY)))
        for y in stride(from: g.topRightEnd.y + 6, through: g.bottomRightEnd.y - 6, by: 4) {
            #expect(!stroked.contains(CGPoint(x: rect.maxX, y: y)))
        }
        // The drawn path never reaches the right edge: the corners stop early.
        #expect(frame.path(in: rect).boundingRect.maxX < rect.maxX - 1)
    }

    @Test func insetMovesTheCentreLineInwards() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let g = CalipicFrame(lineWidth: 4).inset(by: 2).inset(by: 3).geometry(in: rect)
        #expect(g.rect == rect.insetBy(dx: 5, dy: 5))
    }

    @Test func degenerateInputsStayFinite() {
        #expect(CalipicFrame(lineWidth: 2).path(in: .zero).isEmpty)
        // An inset larger than the rect collapses to a point, not to CGRect.null with infinite coordinates.
        let swallowed = CalipicFrame(lineWidth: 2).inset(by: 50).geometry(in: CGRect(x: 0, y: 0, width: 20, height: 30))
        #expect(swallowed.rect == CGRect(x: 10, y: 15, width: 0, height: 0))
        #expect(swallowed.topRightEnd.x.isFinite && swallowed.leftGap.upper.y.isFinite && swallowed.halfGap == 0)
        #expect(CalipicFrame(lineWidth: 2).inset(by: 50).path(in: CGRect(x: 0, y: 0, width: 20, height: 30)).isEmpty)
        #expect(CalipicFrame(lineWidth: -8).geometry(in: CGRect(x: 0, y: 0, width: 100, height: 100)).halfGap >= 0)
        let tiny = CalipicFrame(cornerRatio: 3, gapRatio: 3, rightSweepDegrees: 400, lineWidth: 50).geometry(in: CGRect(x: 0, y: 0, width: 10, height: 10))
        #expect(tiny.radius == 5 && tiny.halfGap == 0 && tiny.sweepRadians == .pi / 2)
    }
}

struct CameraFramingGuideLayoutTests {
    @Test(arguments: [CGSize(width: 420, height: 912), CGSize(width: 393, height: 852), CGSize(width: 375, height: 667),
                      CGSize(width: 320, height: 568)])
    func theFrameSurroundsTheOvalAndStaysOnScreen(size: CGSize) throws {
        let layout = CameraFramingGuide.Layout(in: size)
        // The oval is exactly where the camera always drew it.
        #expect(abs(layout.oval.height - size.height * 0.32) < 0.001)
        #expect(abs(layout.oval.midY - size.height * 0.44) < 0.001)
        #expect(abs(layout.oval.width - layout.oval.height * 0.78) < 0.001)
        // The frame clears the oval, and so the face, on every side, and fits the view.
        let frame = try #require(layout.frame)
        #expect(frame.insetBy(dx: 4, dy: 4).contains(layout.oval))
        #expect(CGRect(origin: .zero, size: size).contains(frame))
        #expect(abs(frame.midX - size.width / 2) < 0.001)
        #expect(abs(frame.width / frame.height - PhotoFormat.spainPrototype.aspectRatio) < 0.001)
        // The photo's eye line runs through the oval's centre.
        #expect(abs(frame.minY + frame.height * CompositionSpec.icaoEngineeringDefault.eyeLineTarget - layout.oval.midY) < 0.001)
    }

    /// Without room the frame is dropped; the oval never moves or shrinks to make room for it.
    @Test(arguments: [CGSize(width: 852, height: 393), CGSize(width: 320, height: 1_000), CGSize(width: 400, height: 400), CGSize.zero])
    func noFrameInLandscapeOrWhenItCannotClearTheOval(size: CGSize) {
        let layout = CameraFramingGuide.Layout(in: size)
        #expect(layout.frame == nil)
        #expect(abs(layout.oval.height - size.height * 0.32) < 0.001)
    }

    @Test func unusableCompositionValuesDropTheFrameInsteadOfProducingNaN() {
        var spec = CompositionSpec()
        for value in [0.0, -1.0, 1.5, Double.nan] {
            spec.headHeightTarget = value
            #expect(CameraFramingGuide.Layout(in: CGSize(width: 393, height: 852), composition: spec).frame == nil)
        }
    }
}

struct DesignTokensTests {
    @Test func reduceMotionRemovesEveryAnimation() {
        let all: [Design.Motion] = [.landing, .reframe, .compare, .rearrange, .backgroundFade, .guideState]
        for motion in all {
            #expect(motion.resolved(reduceMotion: true) == nil)
            #expect(motion.resolved(animated: false) == nil)
            #expect(motion.resolved(reduceMotion: false) != nil)
            #expect(motion.resolved(reduceMotion: false) == motion.resolved(animated: true))
        }
        #expect(Design.Motion.landingDelay(reduceMotion: true) < Design.Motion.landingDelay(reduceMotion: false))
    }

    @Test func scalesAreOrdered() {
        let spacing = [Design.Spacing.titlePair, Design.Spacing.tight, Design.Spacing.caption, Design.Spacing.text,
                       Design.Spacing.row, Design.Spacing.control, Design.Spacing.cardContent, Design.Spacing.group,
                       Design.Spacing.block, Design.Spacing.sectionTight, Design.Spacing.section]
        #expect(spacing == spacing.sorted())
        #expect(Design.Radius.photo < Design.Radius.tile && Design.Radius.tile < Design.Radius.card)
        #expect(Design.Stroke.guide(for: .increased) > Design.Stroke.guide(for: .standard))
        #expect(Design.Size.minimumTarget >= 44)
    }
}

#if DEBUG
/// The camera guide rendered without a camera, from the same scene as the `#Preview`s, for
/// docs/brand/prototypes/08-frame-motif-in-product.md. Evidence capture, not a regression test: it only runs with
/// TEST_RUNNER_FRAME_MOTIF_RENDER_DIR=<folder>, because rendering holds the main actor long enough to starve the
/// yield-counting waits in PhotoWorkflowTests when the suites run in parallel.
@MainActor
struct FrameMotifRenderTests {
    private nonisolated static let outputDirectory = ProcessInfo.processInfo.environment["FRAME_MOTIF_RENDER_DIR"]

    private func render(ready: Bool) throws -> UIImage {
        let renderer = ImageRenderer(content: CameraFramingGuidePreviewScene(ready: ready).frame(width: 420, height: 912))
        renderer.scale = 2
        return try #require(renderer.uiImage)
    }

    @Test(.enabled(if: outputDirectory != nil, "Set TEST_RUNNER_FRAME_MOTIF_RENDER_DIR to render the camera guide."))
    func rendersFramingAndReady() throws {
        let framing = try render(ready: false), ready = try render(ready: true)
        #expect(framing.size == CGSize(width: 420, height: 912) && ready.size == framing.size)
        #expect(framing.pngData() != ready.pngData())
        let folder = URL(fileURLWithPath: try #require(Self.outputDirectory), isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try #require(framing.pngData()).write(to: folder.appendingPathComponent("camera-after-framing.png"))
        try #require(ready.pngData()).write(to: folder.appendingPathComponent("camera-after-ready.png"))
    }
}
#endif
