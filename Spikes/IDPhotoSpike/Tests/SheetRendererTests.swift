import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import IDPhotoSpike

struct SheetRendererTests {
    private func raster(width: Int, height: Int) throws -> CGImage {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                             bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        // sRGB mid-grey; a generic-gray 0.5 would land near 145 after colour matching.
        context.setFillColor(CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return try #require(context.makeImage())
    }

    @Test(arguments: [PaperSize.photo4x6, .photo13x18, .a4])
    func pdfPageBoxesAndJPEGPixelsMatchPaper(paper: PaperSize) throws {
        let job = PrintJob(paper: paper, items: [
            PrintItem(photoID: UUID(), trimWidthMM: 26, trimHeightMM: 32, copies: 30),
            PrintItem(photoID: UUID(), trimWidthMM: 35, trimHeightMM: 45, copies: 5)
        ])
        let layout = PrintLayoutSolver.solve(job)
        var rasters: [PrintLayout.RasterKey: CGImage] = [:]
        for key in layout.rasterKeys { rasters[key] = try raster(width: 60, height: 70) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("SheetTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let pdf = directory.appendingPathComponent("sheet.pdf")
        try SheetRenderer.writePDF(layout, rasters: rasters, to: pdf, calibrationLabel: "50 mm")
        try SheetRenderer.verifyPDF(pdf, layout: layout)
        let document = try #require(CGPDFDocument(pdf as CFURL))
        #expect(document.numberOfPages == layout.pages.count)
        let box = try #require(document.page(at: 1)).getBoxRect(.mediaBox)
        #expect(abs(box.width / 72 * 25.4 - layout.pages[0].widthMM) < 0.01)

        let pages = try SheetRenderer.writeJPEGPages(layout, rasters: rasters, in: directory, baseName: "sheet", calibrationLabel: "50 mm")
        try SheetRenderer.verifyJPEGPages(pages, layout: layout)
        let source = try #require(CGImageSourceCreateWithURL(pages[0] as CFURL, nil))
        let props = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let expected = SheetRenderer.jpegPixelSize(for: layout.pages[0])
        #expect(props[kCGImagePropertyPixelWidth] as? Int == expected.width)
        #expect(props[kCGImagePropertyDPIWidth] as? Double == 300)
        // Photo paper at 300 ppi: 10 x 15 cm -> 1181 x 1772, 4 x 6 in -> 1200 x 1800 (portrait pages).
        if paper == .photo4x6 { #expect(expected == OutputPixels(width: 1_200, height: 1_800) || expected == OutputPixels(width: 1_800, height: 1_200)) }
        if paper == .photo4x6 { #expect(expected == OutputPixels(width: 1_200, height: 1_800) || expected == OutputPixels(width: 1_800, height: 1_200)) }
    }

    @Test func rasterIsPlacedInsideItsBleedBoxAndTicksAreBlack() throws {
        let job = PrintJob(paper: .photo4x6, items: [PrintItem(photoID: UUID(), trimWidthMM: 35, trimHeightMM: 45, copies: 1)])
        let layout = PrintLayoutSolver.solve(job)
        let page = layout.pages[0]
        let placement = page.placements[0]
        let rasters = try Dictionary(uniqueKeysWithValues: layout.rasterKeys.map { ($0, try raster(width: 70, height: 90)) })
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("SheetTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = try SheetRenderer.writeJPEGPages(layout, rasters: rasters, in: directory, baseName: "one", calibrationLabel: "50 mm")[0]
        let imageSource = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(imageSource, 0, nil))
        let scale = Double(image.width) / page.widthMM
        let center = try pixel(image, x: (placement.trim.minX + placement.trim.width / 2) * scale,
                               y: (placement.trim.minY + placement.trim.height / 2) * scale)
        #expect(abs(Int(center) - 128) <= 8, "center \(center) at trim \(placement.trim) rotated \(placement.rotated) page \(page.widthMM)x\(page.heightMM) image \(image.width)x\(image.height)")
        let outside = try pixel(image, x: (placement.bleed.maxX + 1.2) * scale, y: (placement.bleed.minY + 5) * scale)
        #expect(outside >= 245, "outside \(outside)")
        let tick = try #require(page.cornerTicks.first { $0.fromY == $0.toY && $0.toX == placement.bleed.minX })
        // A 1 px hairline snapped to a pixel centre; JPEG ringing keeps it well below mid-grey.
        let rows = (-1...1).map { offset in (try? pixel(image, x: (tick.fromX + 0.5) * scale, y: tick.fromY * scale + Double(offset))) ?? 255 }
        #expect(try #require(rows.min()) <= 90)
    }

    /// Grey value at a top-left pixel coordinate, read from an explicit RGBA rasterization of the whole image.
    private func pixel(_ image: CGImage, x: Double, y: Double) throws -> UInt8 {
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
            let context = try #require(CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                                 bytesPerRow: width * 4, space: space,
                                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        let column = min(width - 1, max(0, Int(x.rounded(.down))))
        let row = min(height - 1, max(0, Int(y.rounded(.down))))
        return bytes[(row * width + column) * 4 + 1]
    }
}
