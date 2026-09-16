import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Draws a solved `PrintLayout` as a PDF (page box = paper) and as one exact-aspect JPEG per page.
/// Geometry comes from the layout only; rasters are placed, never re-measured.
enum SheetRenderer {
    static let jpegPixelsPerInch = 300.0
    private static let pdfPointsPerMM = 72.0 / 25.4

    static func writePDF(_ layout: PrintLayout, rasters: [PrintLayout.RasterKey: CGImage], to url: URL,
                         calibrationLabel: String) throws {
        guard let first = layout.pages.first else { throw PhotoError.renderFailed }
        var box = CGRect(x: 0, y: 0, width: first.widthMM * pdfPointsPerMM, height: first.heightMM * pdfPointsPerMM)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { throw PhotoError.renderFailed }
        for page in layout.pages {
            // The solver locks one paper orientation per job, so every page shares the document media box.
            var pageBox = CGRect(x: 0, y: 0, width: page.widthMM * pdfPointsPerMM, height: page.heightMM * pdfPointsPerMM)
            let boxData = Data(bytes: &pageBox, count: MemoryLayout<CGRect>.size) as CFData
            context.beginPDFPage([kCGPDFContextMediaBox: boxData] as CFDictionary)
            draw(page, in: context, scale: pdfPointsPerMM, flipHeight: page.heightMM * pdfPointsPerMM, rasters: rasters,
                 lineWidth: 0.25, antialiased: true, calibrationLabel: calibrationLabel)
            context.endPDFPage()
        }
        context.closePDF()
    }

    /// One JPEG per page at exactly the paper aspect. Kiosks read pixels, not DPI tags, so the aspect is what matters.
    static func writeJPEGPages(_ layout: PrintLayout, rasters: [PrintLayout.RasterKey: CGImage], in directory: URL,
                               baseName: String, calibrationLabel: String) throws -> [URL] {
        var urls: [URL] = []
        for (index, page) in layout.pages.enumerated() {
            let pixels = jpegPixelSize(for: page)
            guard let space = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(data: nil, width: pixels.width, height: pixels.height, bitsPerComponent: 8,
                                          bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            else { throw PhotoError.renderFailed }
            let scale = Double(pixels.width) / page.widthMM
            draw(page, in: context, scale: scale, flipHeight: Double(pixels.height), rasters: rasters,
                 lineWidth: 1, antialiased: false, calibrationLabel: calibrationLabel)
            guard let image = context.makeImage() else { throw PhotoError.renderFailed }
            let url = directory.appendingPathComponent("\(baseName)-page\(index + 1).jpg")
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
            else { throw PhotoError.renderFailed }
            CGImageDestinationAddImage(destination, image, [
                kCGImageDestinationLossyCompressionQuality: 0.92,
                kCGImagePropertyOrientation: 1,
                kCGImagePropertyDPIWidth: jpegPixelsPerInch,
                kCGImagePropertyDPIHeight: jpegPixelsPerInch
            ] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { throw PhotoError.renderFailed }
            urls.append(url)
        }
        return urls
    }

    static func jpegPixelSize(for page: PrintPage) -> OutputPixels {
        OutputPixels(width: Int((page.widthMM / 25.4 * jpegPixelsPerInch).rounded()),
                     height: Int((page.heightMM / 25.4 * jpegPixelsPerInch).rounded()))
    }

    // MARK: - Drawing (context origin bottom-left; layout origin top-left)

    /// `flipHeight` is the context height used to convert top-left layout coordinates to Core Graphics'
    /// bottom-left origin; for bitmaps it is the exact pixel height so rows map one-to-one.
    private static func draw(_ page: PrintPage, in context: CGContext, scale: Double, flipHeight: Double,
                             rasters: [PrintLayout.RasterKey: CGImage], lineWidth: CGFloat, antialiased: Bool,
                             calibrationLabel: String) {
        let pageHeight = flipHeight
        func rect(_ r: MillimeterRect) -> CGRect {
            CGRect(x: r.x * scale, y: pageHeight - (r.y + r.height) * scale, width: r.width * scale, height: r.height * scale)
        }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: page.widthMM * scale, height: pageHeight))
        context.interpolationQuality = .high

        for placement in page.placements {
            guard let image = rasters[PrintLayout.RasterKey(itemID: placement.itemID, bleedMM: page.bleedMM)] else { continue }
            let target = rect(placement.bleed)
            context.saveGState()
            if placement.rotated {
                context.translateBy(x: target.midX, y: target.midY)
                context.rotate(by: -.pi / 2) // clockwise on the page
                context.draw(image, in: CGRect(x: -target.height / 2, y: -target.width / 2, width: target.height, height: target.width))
            } else {
                context.draw(image, in: target)
            }
            context.restoreGState()
        }

        context.setShouldAntialias(antialiased)
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setLineWidth(lineWidth)
        context.setLineCap(.butt)
        // Align 1 px lines to pixel centres when drawing into a bitmap.
        let snap: (Double) -> CGFloat = { antialiased ? $0 : ($0.rounded(.down) + 0.5) }
        for tick in page.cornerTicks {
            context.move(to: CGPoint(x: snap(tick.fromX * scale), y: snap(pageHeight - tick.fromY * scale)))
            context.addLine(to: CGPoint(x: snap(tick.toX * scale), y: snap(pageHeight - tick.toY * scale)))
        }
        context.strokePath()

        if let bar = page.calibrationBar {
            let y = snap(pageHeight - bar.y * scale)
            let x0 = snap(bar.x * scale), x1 = snap((bar.x + bar.lengthMM) * scale)
            let cap = 1.5 * scale
            context.move(to: CGPoint(x: x0, y: y)); context.addLine(to: CGPoint(x: x1, y: y))
            context.move(to: CGPoint(x: x0, y: y - cap)); context.addLine(to: CGPoint(x: x0, y: y + cap))
            context.move(to: CGPoint(x: x1, y: y - cap)); context.addLine(to: CGPoint(x: x1, y: y + cap))
            context.strokePath()
            context.setShouldAntialias(true)
            let font = CTFontCreateUIFontForLanguage(.system, 2.2 * scale, nil) ?? CTFontCreateWithName("Helvetica" as CFString, 2.2 * scale, nil)
            let attributes: [CFString: Any] = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: CGColor(gray: 0, alpha: 1)]
            let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, calibrationLabel as CFString, attributes as CFDictionary))
            let width = CTLineGetTypographicBounds(line, nil, nil, nil)
            context.textPosition = CGPoint(x: (x0 + x1) / 2 - width / 2, y: y + 1.2 * scale)
            CTLineDraw(line, context)
        }
    }

    // MARK: - Verification

    static func verifyPDF(_ url: URL, layout: PrintLayout) throws {
        guard let document = CGPDFDocument(url as CFURL), document.numberOfPages == layout.pages.count else {
            throw PhotoError.verificationFailed
        }
        for (index, page) in layout.pages.enumerated() {
            guard let pdfPage = document.page(at: index + 1) else { throw PhotoError.verificationFailed }
            let box = pdfPage.getBoxRect(.mediaBox)
            guard abs(box.width - page.widthMM * pdfPointsPerMM) < 0.01,
                  abs(box.height - page.heightMM * pdfPointsPerMM) < 0.01 else { throw PhotoError.verificationFailed }
        }
    }

    static func verifyJPEGPages(_ urls: [URL], layout: PrintLayout) throws {
        guard urls.count == layout.pages.count else { throw PhotoError.verificationFailed }
        for (url, page) in zip(urls, layout.pages) {
            let expected = jpegPixelSize(for: page)
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  CGImageSourceGetType(source) as String? == UTType.jpeg.identifier,
                  let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  props[kCGImagePropertyPixelWidth] as? Int == expected.width,
                  props[kCGImagePropertyPixelHeight] as? Int == expected.height,
                  props[kCGImagePropertyGPSDictionary] == nil else { throw PhotoError.verificationFailed }
        }
    }
}
