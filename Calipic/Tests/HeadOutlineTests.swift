import CoreGraphics
import Foundation
import Testing
@testable import Calipic

struct HeadOutlineTests {
    /// Medians measured on the founder's recordings and the sample portraits (0.20.10).
    @Test func calibratedValuesSeparate() {
        for plain in [2.22, 2.27, 2.38, 2.46, 2.63] { #expect(!HeadOutline.isWide(plain), "\(plain)") }
        for headphones in [2.74, 2.75, 2.85] { #expect(HeadOutline.isWide(headphones), "\(headphones)") }
        #expect(HeadOutline.medianWidth([3, 1, 2]) == 2)
        #expect(HeadOutline.medianWidth([4, 1, 2, 3]) == 2.5)
        #expect(HeadOutline.medianWidth([]) == nil)
    }

    /// A drawn mask: a head 2.4 inter-eye distances wide, then the same head with "ear cups" making it 3.0 wide.
    @Test func measuresTheMaskAroundTheHead() throws {
        let source = SourcePixels(width: 1_000, height: 1_250)
        let ied = 100.0, eyes = ImagePoint(x: 500, y: 560), eyeToChin = 125.0
        func mask(cups: Bool) throws -> CGImage {
            let gray = try #require(CGColorSpace(name: CGColorSpace.linearGray))
            let context = try #require(CGContext(data: nil, width: 1_000, height: 1_250, bitsPerComponent: 8, bytesPerRow: 0,
                                                 space: gray, bitmapInfo: CGImageAlphaInfo.none.rawValue))
            context.setFillColor(CGColor(gray: 0, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 1_000, height: 1_250))
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            // CGContext is bottom-up: the head spans y 380...760 from the top, 240 px wide (2.4 × IED).
            context.fill(CGRect(x: 380, y: 1_250 - 760, width: 240, height: 380))
            if cups { context.fill(CGRect(x: 350, y: 1_250 - 600, width: 300, height: 160)) }
            return try #require(context.makeImage())
        }
        let plain = try #require(FaceAnalyzer.headOutlineWidth(try mask(cups: false), eyeMidpoint: eyes, interEye: ied,
                                                                eyeToChin: eyeToChin, source: source))
        #expect(abs(plain - 2.4) < 0.05, "\(plain)")
        #expect(!HeadOutline.isWide(plain))
        let cups = try #require(FaceAnalyzer.headOutlineWidth(try mask(cups: true), eyeMidpoint: eyes, interEye: ied,
                                                               eyeToChin: eyeToChin, source: source))
        #expect(abs(cups - 3.0) < 0.05, "\(cups)")
        #expect(HeadOutline.isWide(cups))
    }
}
