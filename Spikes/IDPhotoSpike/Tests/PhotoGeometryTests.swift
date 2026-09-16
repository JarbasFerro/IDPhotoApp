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

    @Test func formatLookupAndBleedExpansion() {
        #expect(PhotoFormat.format(widthMM: 35, heightMM: 45) == .europe35x45)
        let custom = PhotoFormat.format(widthMM: 30, heightMM: 40)
        #expect(custom.output == OutputPixels(width: 600, height: 800))
        let crop = NormalizedCrop(x: 0.1, y: 0.2, width: 0.5, height: 0.5)
        let expanded = crop.expanded(byFractionX: 1 / 26, fractionY: 1 / 32)
        #expect(abs(expanded.width - 0.5 * (1 + 2 / 26.0)) < 0.000_001)
        #expect(abs(expanded.x - (0.1 - 0.5 / 26)) < 0.000_001)
        // A 1 mm bleed on a 26 x 32 crop at the source edge legitimately reaches outside 0...1.
        let edge = NormalizedCrop(x: 0, y: 0, width: 1, height: 1).expanded(byFractionX: 1 / 26, fractionY: 1 / 32)
        #expect(edge.x < 0 && edge.y < 0)
    }
}
