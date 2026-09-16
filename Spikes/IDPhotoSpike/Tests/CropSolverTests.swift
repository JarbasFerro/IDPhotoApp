import Foundation
import Testing
@testable import IDPhotoSpike

private extension Double { static let agreeing = -1.0 }

struct CropSolverTests {
    /// A synthetic adult face: inter-eye distance `ied` as a fraction of width, chin 1.25 IED below the eyes,
    /// and by default a person mask that agrees with anatomy.
    private func geometry(eyeY: Double = 0.40, eyeX: Double = 0.5, ied: Double = 0.14, roll: Double = 0,
                          faceCount: Int = 1, maskTop: Double? = .agreeing, source: SourcePixels = SourcePixels(width: 3_000, height: 4_000),
                          ratio: Double = CrownEstimator.defaultAdultRatio) -> FaceGeometry {
        let iedPx = ied * Double(source.width)
        let chinY = eyeY + 1.25 * iedPx / Double(source.height)
        let maskTop = maskTop == .agreeing ? chinY - ratio * (chinY - eyeY) + 0.004 : maskTop
        let crown = CrownEstimator.estimate(chinY: chinY, eyeY: eyeY, maskTopY: maskTop, interEyeDistancePixels: iedPx,
                                            sourceHeight: source.height, ratio: ratio)
        return FaceGeometry(source: source, faceCount: faceCount,
                            faceBox: NormalizedCrop(x: eyeX - ied, y: eyeY - 0.05, width: ied * 2, height: 0.2),
                            leftEye: ImagePoint(x: eyeX + ied / 2, y: eyeY), rightEye: ImagePoint(x: eyeX - ied / 2, y: eyeY),
                            chin: ImagePoint(x: eyeX, y: chinY), crown: crown,
                            rollDegrees: roll, yawDegrees: 0, pitchDegrees: 0)
    }

    @Test func crownAgreesWithMaskWhenClose() {
        let chinY = 0.535, eyeY = 0.40
        let anthro = chinY - 1.8 * (chinY - eyeY)
        let close = CrownEstimator.estimate(chinY: chinY, eyeY: eyeY, maskTopY: anthro + 0.01, interEyeDistancePixels: 300, sourceHeight: 4_000)
        #expect(close.method == .mask && close.confidence >= 0.8 && !close.hairVolume)
        let tallHair = CrownEstimator.estimate(chinY: chinY, eyeY: eyeY, maskTopY: anthro - 0.08, interEyeDistancePixels: 300, sourceHeight: 4_000)
        #expect(tallHair.method == .anthropometric && tallHair.hairVolume)
        let badMask = CrownEstimator.estimate(chinY: chinY, eyeY: eyeY, maskTopY: anthro + 0.08, interEyeDistancePixels: 300, sourceHeight: 4_000)
        #expect(badMask.method == .anthropometric && !badMask.hairVolume && badMask.confidence < 0.5)
        let cut = CrownEstimator.estimate(chinY: chinY, eyeY: eyeY, maskTopY: 0, interEyeDistancePixels: 300, sourceHeight: 4_000)
        #expect(cut.headTouchesTop)
        let noMask = CrownEstimator.estimate(chinY: chinY, eyeY: eyeY, maskTopY: nil, interEyeDistancePixels: 300, sourceHeight: 4_000)
        #expect(noMask.method == .anthropometric && abs(noMask.y - anthro) < 0.000_001)
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

    @Test func tiltIsLevelledWithinLimitAndReportedBeyond() {
        let mild = CropSolver.solve(geometry: geometry(roll: 4))
        #expect(mild.adjustment.rotationDegrees == -4)
        #expect(mild.checks.first { $0.kind == .roll }?.state == .pass)
        let strong = CropSolver.solve(geometry: geometry(roll: 12))
        #expect(strong.adjustment.rotationDegrees == 0)
        #expect(strong.checks.first { $0.kind == .roll }?.state == .warn)
    }

    @Test func smallFaceHitsZoomLimitAndResolutionWarning() {
        let g = geometry(eyeY: 0.45, ied: 0.02, maskTop: nil, source: SourcePixels(width: 1_440, height: 960))
        let solution = CropSolver.solve(geometry: g)
        #expect(solution.checks.first { $0.kind == .resolution }?.state == .fail)
        #expect(solution.adjustment.zoom <= 4)
        #expect(solution.checks.first { $0.kind == .zoomRange }?.state == .warn)
        #expect(solution.overall == .fail)
    }

    @Test func faceNearTopKeepsHeadroomAndStaysInsideSource() {
        // No mask: with the face this high, a real mask would touch the top row and correctly fail headroom.
        let g = geometry(eyeY: 0.08, maskTop: nil)
        let solution = CropSolver.solve(geometry: g)
        let crop = solution.adjustment.crop(in: g.source)
        #expect(crop.y >= 0 && crop.y + crop.height <= 1.000_001)
        #expect(solution.checks.first { $0.kind == .headroom }?.state != .fail)
        #expect(solution.checks.first { $0.kind == .eyeLine }?.state != .pass || solution.eyeLineFraction >= 0.30)
    }

    @Test func multipleFacesAndHairVolumeAreSurfaced() {
        let two = CropSolver.solve(geometry: geometry(faceCount: 2))
        #expect(two.checks.first { $0.kind == .faceCount }?.state == .fail)
        let hair = CropSolver.solve(geometry: geometry(maskTop: 0.10))
        let noMask = CropSolver.solve(geometry: geometry(maskTop: nil))
        #expect(noMask.checks.first { $0.kind == .crown }?.state == .warn)
        #expect(hair.checks.first { $0.kind == .crown }?.state == .manualCheck)
    }

    @Test func rotationIsClampedAndDefaultsToZeroForInvalidValues() {
        #expect(CropAdjustment(rotationDegrees: 20).clamped().rotationDegrees == 8)
        #expect(CropAdjustment(rotationDegrees: .nan).clamped().rotationDegrees == 0)
        #expect(CropAdjustment().rotationDegrees == 0)
    }

    @Test func solutionIsDeterministic() {
        let g = geometry(eyeY: 0.37, eyeX: 0.48, roll: -2.5, maskTop: 0.27)
        #expect(CropSolver.solve(geometry: g) == CropSolver.solve(geometry: g))
    }
}
