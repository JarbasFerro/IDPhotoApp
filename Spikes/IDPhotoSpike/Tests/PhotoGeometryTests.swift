import Foundation
import Testing
@testable import IDPhotoSpike

struct PhotoGeometryTests {
    @Test(arguments: [SourcePixels(width: 4_032, height: 3_024),
                      SourcePixels(width: 3_024, height: 4_032),
                      SourcePixels(width: 1_000, height: 1_000),
                      SourcePixels(width: 8_064, height: 6_048),
                      SourcePixels(width: 101, height: 333)])
    func cropStaysInsideSourceAndPreservesPortraitRatio(source: SourcePixels) {
        for zoom in [1.0, 1.25, 4.0] {
            for horizontal in [0.0, 0.5, 1.0] {
                for vertical in [0.0, 0.5, 1.0] {
                    let crop = CropAdjustment(zoom: zoom, horizontal: horizontal, vertical: vertical).crop(in: source)
                    #expect(crop.x >= 0 && crop.y >= 0)
                    #expect(crop.x + crop.width <= 1.000_000_001)
                    #expect(crop.y + crop.height <= 1.000_000_001)
                    let aspect = crop.width * Double(source.width) / (crop.height * Double(source.height))
                    #expect(abs(aspect - 13.0 / 16) < 0.000_000_001)
                }
            }
        }
    }

    @Test func invalidAdjustmentsCannotMakeEmptyPixels() {
        let source = SourcePixels(width: 400, height: 600)
        let edit = CropAdjustment(zoom: .nan, horizontal: -.infinity, vertical: 30).clamped()
        #expect(edit == CropAdjustment(zoom: 1, horizontal: 0, vertical: 1))
        let crop = edit.crop(in: source)
        #expect(crop.width > 0 && crop.height > 0)
    }

    @Test func draggingImageRightMovesCropLeftAndClampsAtEdge() {
        let source = SourcePixels(width: 1_000, height: 1_000)
        let edit = CropAdjustment(zoom: 2)
        let moved = edit.translated(x: 100, y: 100, previewWidth: 260, source: source)
        #expect(moved.horizontal < edit.horizontal)
        #expect(moved.vertical < edit.vertical)
        let edge = edit.translated(x: 10_000, y: -10_000, previewWidth: 260, source: source)
        #expect(edge.horizontal == 0 && edge.vertical == 1)
    }

    @Test func portraitPhysicalAxesAndRasterAspectMatch() {
        let format = PhotoFormat.spainPrototype
        #expect(format.widthMM == 26 && format.heightMM == 32)
        #expect(format.output.width == 520 && format.output.height == 640)
        #expect(Double(format.output.width) / Double(format.output.height) == format.aspectRatio)
        #expect(abs(format.pixelsPerInch - 508) < 0.000_001)
        #expect(abs(PhotoFormat.pdfPoints(mm: 25.4) - 72) < 0.000_001)
    }

    @Test func sixPhotoRectanglesFitA6WithoutOverlap() {
        let layout = PrintLayout()
        #expect(layout.origins.count == 6)
        #expect(abs(layout.photoWidth / 72 * 25.4 - 26) < 0.000_001)
        #expect(abs(layout.photoHeight / 72 * 25.4 - 32) < 0.000_001)
        for (index, origin) in layout.origins.enumerated() {
            #expect(origin.x >= 0 && origin.y >= 0)
            #expect(origin.x + layout.photoWidth <= layout.pageWidth)
            #expect(origin.y + layout.photoHeight <= layout.pageHeight)
            for other in layout.origins.dropFirst(index + 1) {
                let separate = origin.x + layout.photoWidth <= other.x || other.x + layout.photoWidth <= origin.x
                    || origin.y + layout.photoHeight <= other.y || other.y + layout.photoHeight <= origin.y
                #expect(separate)
            }
        }
    }
}
