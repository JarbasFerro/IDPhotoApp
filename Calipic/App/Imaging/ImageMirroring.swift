import CoreGraphics

extension CGImage {
    /// The same pixels, left and right swapped. Used only for what the screen shows of a front-camera photo; files
    /// that are printed or shared are never mirrored.
    func mirroredHorizontally() -> CGImage? {
        guard let space = colorSpace?.model == .rgb ? colorSpace : CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.translateBy(x: CGFloat(width), y: 0)
        context.scaleBy(x: -1, y: 1)
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
