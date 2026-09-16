import Foundation
import Testing
@testable import IDPhotoSpike

private extension Double { static let agreeing = -1.0 }

struct CropSolverTests {
    /// A synthetic adult face: inter-eye distance `ied` as a fraction of width, chin 1.25 IED below the eyes along
    /// the head axis, eye line tilted by `roll` degrees (counter-clockwise positive), and by default a person mask
    /// that agrees with anatomy.
    private func geometry(eyeY: Double = 0.40, eyeX: Double = 0.5, ied: Double = 0.14, roll: Double = 0,
                          faceCount: Int = 1, maskAbove: Double? = .agreeing, source: SourcePixels = SourcePixels(width: 3_000, height: 4_000),
                          ratio: Double = CrownEstimator.defaultAdultRatio) -> FaceGeometry {
        let w = Double(source.width), h = Double(source.height)
        let iedPx = ied * w
        let angle = -roll * .pi / 180
        let frame = HeadFrame(center: ImagePoint(x: eyeX * w, y: eyeY * h), angleRadians: angle)
        let left = frame.toImage(ImagePoint(x: iedPx / 2, y: 0)), right = frame.toImage(ImagePoint(x: -iedPx / 2, y: 0))
        let eyeToChin = 1.25 * iedPx
        let chinPx = frame.toImage(ImagePoint(x: 0, y: eyeToChin))
        let mask = maskAbove == .agreeing ? (ratio - 1) * eyeToChin + 0.02 * iedPx : maskAbove
        let crown = CrownEstimator.estimate(eyeToChin: eyeToChin, maskAboveEyes: mask, interEyeDistancePixels: iedPx, ratio: ratio)
        return FaceGeometry(source: source, faceCount: faceCount,
                            faceBox: NormalizedCrop(x: eyeX - ied, y: eyeY - 0.05, width: ied * 2, height: 0.2),
                            leftEye: ImagePoint(x: left.x / w, y: left.y / h), rightEye: ImagePoint(x: right.x / w, y: right.y / h),
                            chin: ImagePoint(x: chinPx.x / w, y: chinPx.y / h), crown: crown, eyeToChinPixels: eyeToChin,
                            yawDegrees: 0, pitchDegrees: 0)
    }

    @Test func headFrameRoundTripsAndMeasuresRoll() {
        let frame = HeadFrame(center: ImagePoint(x: 100, y: 200), angleRadians: 0.3)
        let p = ImagePoint(x: 130, y: 260)
        let back = frame.toImage(frame.toAligned(p))
        #expect(abs(back.x - p.x) < 0.000_001 && abs(back.y - p.y) < 0.000_001)
        // Image-right eye lower than image-left eye = clockwise tilt = negative roll.
        let g = geometry(roll: -12)
        #expect(g.leftEye.y > g.rightEye.y)
        #expect(abs(g.rollDegrees + 12) < 0.000_1)
    }

    @Test func crownAgreesWithMaskWhenClose() {
        let eyeToChin = 525.0, ied = 420.0
        let anthro = 0.8 * eyeToChin
        let close = CrownEstimator.estimate(eyeToChin: eyeToChin, maskAboveEyes: anthro + 40, interEyeDistancePixels: ied)
        #expect(close.method == .mask && close.confidence >= 0.8 && !close.hairVolume)
        let tallHair = CrownEstimator.estimate(eyeToChin: eyeToChin, maskAboveEyes: anthro + 320, interEyeDistancePixels: ied)
        #expect(tallHair.method == .anthropometric && tallHair.hairVolume)
        let badMask = CrownEstimator.estimate(eyeToChin: eyeToChin, maskAboveEyes: anthro - 320, interEyeDistancePixels: ied)
        #expect(badMask.method == .anthropometric && !badMask.hairVolume && badMask.confidence < 0.5)
        let cut = CrownEstimator.estimate(eyeToChin: eyeToChin, maskAboveEyes: anthro, maskTouchesEdge: true, interEyeDistancePixels: ied)
        #expect(cut.headTouchesEdge && cut.confidence < 0.5)
        let noMask = CrownEstimator.estimate(eyeToChin: eyeToChin, maskAboveEyes: nil, interEyeDistancePixels: ied)
        #expect(noMask.method == .anthropometric && abs(noMask.distanceAboveEyes - anthro) < 0.000_001)
    }

    @Test func wellFramedFaceLandsOnTargets() {
        let g = geometry()
        let solution = CropSolver.solve(geometry: g)
        #expect(abs(solution.headHeightFraction - 0.74) < 0.01)
        #expect(abs(solution.eyeLineFraction - 0.42) < 0.02)
        #expect(solution.overall == .pass, "\(solution.checks)")
        // Round trip through the editor model reproduces the same crop.
        let crop = solution.adjustment.crop(in: g.source)
        let eyeInCrop = (g.eyeMidpoint.y - crop.y) / crop.height
        #expect(abs(eyeInCrop - solution.eyeLineFraction) < 0.01)
        #expect(abs(crop.width * Double(g.source.width) / (crop.height * Double(g.source.height)) - 13.0 / 16) < 0.000_001)
    }

    @Test func tiltIsLevelledUpToTheLimitAndReportedAbove() {
        let mild = CropSolver.solve(geometry: geometry(roll: 4))
        #expect(abs(mild.adjustment.rotationDegrees + 4) < 0.000_1)
        #expect(mild.checks.first { $0.kind == .roll }?.state == .pass)
        let medium = CropSolver.solve(geometry: geometry(roll: 12))
        #expect(abs(medium.adjustment.rotationDegrees + 12) < 0.000_1)
        #expect(medium.checks.first { $0.kind == .roll }?.state == .warn)
        let strong = CropSolver.solve(geometry: geometry(roll: 35))
        #expect(strong.adjustment.rotationDegrees == 0)
        #expect(strong.checks.first { $0.kind == .roll }?.state == .warn)
    }

    @Test func tiltedHeadIsMeasuredAlongItsAxis() {
        let source = SourcePixels(width: 3_000, height: 4_000)
        let upright = CropSolver.solve(geometry: geometry())
        let tilted = CropSolver.solve(geometry: geometry(roll: 35))
        let uprightCrop = upright.adjustment.crop(in: source)
        let tiltedCrop = tilted.adjustment.crop(in: source)
        // Same head length, so the same crop size even though the vertical chin-to-crown distance shrank by cos 35°.
        #expect(abs(tiltedCrop.height - uprightCrop.height) < 0.002)
        #expect(abs(tilted.headHeightFraction - 0.74) < 0.01)
        // The crop still contains both eyes, the chin, and the crown.
        let g = geometry(roll: 35)
        for point in [g.leftEye, g.rightEye, g.chin, g.crownPoint] {
            #expect(point.x > tiltedCrop.x && point.x < tiltedCrop.x + tiltedCrop.width, "\(point)")
            #expect(point.y > tiltedCrop.y && point.y < tiltedCrop.y + tiltedCrop.height, "\(point)")
        }
        // A levelled 12° tilt keeps the eye line where the target says.
        let levelled = CropSolver.solve(geometry: geometry(roll: 12))
        #expect(abs(levelled.eyeLineFraction - 0.42) < 0.02)
    }

    @Test func smallFaceHitsZoomLimitAndResolutionWarning() {
        let g = geometry(eyeY: 0.45, ied: 0.02, maskAbove: nil, source: SourcePixels(width: 1_440, height: 960))
        let solution = CropSolver.solve(geometry: g)
        #expect(solution.checks.first { $0.kind == .resolution }?.state == .fail)
        #expect(solution.adjustment.zoom <= 4)
        #expect(solution.checks.first { $0.kind == .zoomRange }?.state == .warn)
        #expect(solution.overall == .fail)
    }

    @Test func faceNearTopKeepsHeadroomAndStaysInsideSource() {
        let g = geometry(eyeY: 0.08, maskAbove: nil)
        let solution = CropSolver.solve(geometry: g)
        let crop = solution.adjustment.crop(in: g.source)
        #expect(crop.y >= 0 && crop.y + crop.height <= 1.000_001)
        #expect(solution.checks.first { $0.kind == .headroom }?.state != .fail)
    }

    @Test func multipleFacesAndHairVolumeAreSurfaced() {
        let two = CropSolver.solve(geometry: geometry(faceCount: 2))
        #expect(two.checks.first { $0.kind == .faceCount }?.state == .fail)
        let hair = CropSolver.solve(geometry: geometry(maskAbove: 1_200))
        #expect(hair.checks.first { $0.kind == .crown }?.state == .manualCheck)
        let noMask = CropSolver.solve(geometry: geometry(maskAbove: nil))
        #expect(noMask.checks.first { $0.kind == .crown }?.state == .warn)
    }

    @Test func rotationIsClampedAndDefaultsToZeroForInvalidValues() {
        #expect(CropAdjustment(rotationDegrees: 20).clamped().rotationDegrees == 15)
        #expect(CropAdjustment(rotationDegrees: .nan).clamped().rotationDegrees == 0)
        #expect(CropAdjustment().rotationDegrees == 0)
    }

    @Test func solutionIsDeterministic() {
        let g = geometry(eyeY: 0.37, eyeX: 0.48, roll: -2.5, maskAbove: 500)
        #expect(CropSolver.solve(geometry: g) == CropSolver.solve(geometry: g))
    }
}
