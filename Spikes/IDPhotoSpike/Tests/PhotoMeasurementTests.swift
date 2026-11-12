import Foundation
import Testing
@testable import IDPhotoSpike

/// The measuring lines on Photo Check (D-2) must agree with the crop solver that made the framing.
struct PhotoMeasurementTests {
    private func geometry(eyeY: Double = 0.40, ied: Double = 0.14, roll: Double = 0,
                          source: SourcePixels = SourcePixels(width: 3_000, height: 4_000)) -> FaceGeometry {
        let w = Double(source.width), h = Double(source.height)
        let iedPx = ied * w
        let frame = HeadFrame(center: ImagePoint(x: 0.5 * w, y: eyeY * h), angleRadians: -roll * .pi / 180)
        let left = frame.toImage(ImagePoint(x: iedPx / 2, y: 0)), right = frame.toImage(ImagePoint(x: -iedPx / 2, y: 0))
        let eyeToChin = 1.25 * iedPx
        let chin = frame.toImage(ImagePoint(x: 0, y: eyeToChin))
        let crown = CrownEstimator.estimate(eyeToChin: eyeToChin, maskAboveEyes: 0.8 * eyeToChin + 0.02 * iedPx,
                                            interEyeDistancePixels: iedPx)
        return FaceGeometry(source: source, faceCount: 1,
                            faceBox: NormalizedCrop(x: 0.5 - ied, y: eyeY - 0.05, width: ied * 2, height: 0.2),
                            leftEye: ImagePoint(x: left.x / w, y: left.y / h), rightEye: ImagePoint(x: right.x / w, y: right.y / h),
                            chin: ImagePoint(x: chin.x / w, y: chin.y / h), crown: crown, eyeToChinPixels: eyeToChin,
                            yawDegrees: 0, pitchDegrees: 0)
    }

    /// Level and tilted faces: what the lines show equals what the solver aimed for.
    @Test(arguments: [0.0, 6.0, -11.0])
    func agreesWithTheSolver(roll: Double) throws {
        let g = geometry(roll: roll)
        let spec = CompositionSpec.icaoEngineeringDefault
        let solution = CropSolver.solve(geometry: g, format: .spainPrototype, spec: spec)
        let m = try #require(PhotoMeasurement.measure(geometry: g, adjustment: solution.adjustment, format: .spainPrototype, spec: spec))
        #expect(abs(m.headFraction - solution.headHeightFraction) < 0.002, "head \(m.headFraction) vs \(solution.headHeightFraction)")
        #expect(abs(m.eyeY - solution.eyeLineFraction) < 0.002, "eyes \(m.eyeY) vs \(solution.eyeLineFraction)")
        #expect(abs(m.eyeX - 0.5) < 0.002)
        #expect(m.crownY < m.eyeY && m.eyeY < m.chinY)
    }

    @Test func millimetresFollowThePhotoHeight() throws {
        let g = geometry()
        let spec = CompositionSpec.icaoEngineeringDefault
        let solution = CropSolver.solve(geometry: g, format: .spainPrototype, spec: spec)
        let m = try #require(PhotoMeasurement.measure(geometry: g, adjustment: solution.adjustment, format: .spainPrototype, spec: spec))
        #expect(m.photoHeightMM == PhotoFormat.spainPrototype.heightMM)
        #expect(abs(m.headHeightMM - m.headFraction * m.photoHeightMM) < 1e-9)
        #expect(abs(m.headRangeMM.lowerBound - spec.headHeightRange.lowerBound * m.photoHeightMM) < 1e-9)
        #expect(abs(m.eyeHeightFromBottomMM - (1 - m.eyeY) * m.photoHeightMM) < 1e-9)
        #expect(m.headInRange && m.eyesInRange)
        #expect(!m.crownIsEstimate)
    }

    /// Zooming in makes the head larger on the photo; the lines must follow the person's own framing.
    @Test func followsTheCurrentFramingNotOnlyTheAutomaticOne() throws {
        let g = geometry()
        let spec = CompositionSpec.icaoEngineeringDefault
        var adjustment = CropSolver.solve(geometry: g, format: .spainPrototype, spec: spec).adjustment
        let before = try #require(PhotoMeasurement.measure(geometry: g, adjustment: adjustment, format: .spainPrototype, spec: spec))
        adjustment.zoom *= 1.2
        let after = try #require(PhotoMeasurement.measure(geometry: g, adjustment: adjustment, format: .spainPrototype, spec: spec))
        #expect(after.headFraction > before.headFraction * 1.15)
    }

    @Test func noMeasurementWithoutExactlyOneFace() {
        let g = geometry()
        let two = FaceGeometry(source: g.source, faceCount: 2, faceBox: g.faceBox, leftEye: g.leftEye, rightEye: g.rightEye,
                               chin: g.chin, crown: g.crown, eyeToChinPixels: g.eyeToChinPixels, yawDegrees: 0, pitchDegrees: 0)
        #expect(PhotoMeasurement.measure(geometry: two, adjustment: CropAdjustment(), format: .spainPrototype,
                                         spec: .icaoEngineeringDefault) == nil)
    }
}
