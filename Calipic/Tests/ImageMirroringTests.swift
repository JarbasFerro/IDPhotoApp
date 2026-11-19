import CoreGraphics
import Testing
@testable import Calipic

struct ImageMirroringTests {
    /// A two-pixel image, red then blue, comes back blue then red at the same size.
    @Test func mirroringSwapsLeftAndRight() throws {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        var pixels: [UInt8] = [255, 0, 0, 255, 0, 0, 255, 255]
        let context = try #require(CGContext(data: &pixels, width: 2, height: 1, bitsPerComponent: 8, bytesPerRow: 8,
                                             space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        let image = try #require(context.makeImage())
        let mirrored = try #require(image.mirroredHorizontally())
        #expect(mirrored.width == 2 && mirrored.height == 1)
        var out = [UInt8](repeating: 0, count: 8)
        let reader = try #require(CGContext(data: &out, width: 2, height: 1, bitsPerComponent: 8, bytesPerRow: 8,
                                            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        reader.draw(mirrored, in: CGRect(x: 0, y: 0, width: 2, height: 1))
        #expect(out[0] < 10 && out[2] > 245)
        #expect(out[4] > 245 && out[6] < 10)
    }
}
