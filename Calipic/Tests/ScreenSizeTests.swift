import Foundation
import Testing
@testable import Calipic

/// True size on the screen for the print check (docs/03-design.md U1).
struct ScreenSizeTests {
    @Test func a460ppiScreenAt3xDraws50MillimetresAs302Points() throws {
        let perMM = try #require(ScreenSize.pointsPerMillimetre(model: "iPhone16,2", nativeScale: 3))
        #expect(abs(perMM - 460 / 25.4 / 3) < 1e-12)
        #expect(abs(perMM * 50 - 301.837) < 0.001)
    }

    /// Display Zoom and downsampled panels change the native scale, and the drawn size must follow it.
    @Test(arguments: [(3.0, 50.0), (3.4, 50.0), (2.88, 50.0)])
    func physicalLengthIsIndependentOfTheNativeScale(scale: Double, millimetres: Double) throws {
        let perMM = try #require(ScreenSize.pointsPerMillimetre(model: "iPhone13,1", nativeScale: scale))
        let physicalPixels = perMM * millimetres * scale
        #expect(abs(physicalPixels / 476 * 25.4 - millimetres) < 1e-9)
    }

    @Test func unknownModelsAndImpossibleScalesHaveNoSize() {
        #expect(ScreenSize.pointsPerMillimetre(model: "iPhone99,9", nativeScale: 3) == nil)
        #expect(ScreenSize.pointsPerMillimetre(model: "arm64", nativeScale: 3) == nil)
        #expect(ScreenSize.pointsPerMillimetre(model: "iPhone16,2", nativeScale: 0) == nil)
    }

    @Test func everyTableEntryIsAnIPhoneWithARealDensity() {
        for (model, ppi) in ScreenSize.pixelsPerInch {
            #expect(model.hasPrefix("iPhone"))
            #expect([326.0, 458, 460, 476].contains(ppi), "\(model): \(ppi)")
            // At the panel's own scale, every listed screen must fall inside the plausible calibration range.
            let scale = ppi == 326 ? 2.0 : 3.0
            #expect(ScreenSize.plausibleRange.contains(ppi / 25.4 / scale), "\(model)")
        }
    }

    @Test func aMatchedCardGivesPointsPerMillimetre() throws {
        let perMM = try #require(ScreenSize.pointsPerMillimetre(cardShortSidePoints: 325.86))
        #expect(abs(perMM - 325.86 / 53.98) < 1e-12)
        #expect(ScreenSize.pointsPerMillimetre(cardShortSidePoints: 0) == nil)
    }

    @Test func theTableWinsThenACalibrationThenNothing() {
        #expect(ScreenScale.resolve(model: "iPhone16,2", nativeScale: 3, storedCalibration: 7) == .known(pointsPerMM: 460 / 25.4 / 3))
        #expect(ScreenScale.resolve(model: "iPhone99,9", nativeScale: 3, storedCalibration: 6.1) == .calibrated(pointsPerMM: 6.1))
        #expect(ScreenScale.resolve(model: "iPhone99,9", nativeScale: 3, storedCalibration: 42) == .unknown)
        #expect(ScreenScale.resolve(model: "iPhone99,9", nativeScale: 3, storedCalibration: nil) == .unknown)
        #expect(ScreenScale.unknown.pointsPerMM == nil)
    }
}
