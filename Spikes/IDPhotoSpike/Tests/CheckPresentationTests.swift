import CoreGraphics
import Foundation
import Testing
@testable import IDPhotoSpike

struct CheckPresentationTests {
    private func entry(analysis: FaceAnalysis? = nil, unavailable: Bool = false, analyzing: Bool = false,
                       segmentation: SegmentationResult? = nil, tone: ToneAssessment? = nil,
                       background: BackgroundChoice = .original) throws -> PhotoEntry {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(CGContext(data: nil, width: 8, height: 10, bitsPerComponent: 8, bytesPerRow: 0,
                                             space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        let image = try #require(context.makeImage())
        var entry = PhotoEntry(photo: PreparedPhoto(id: UUID(), pixels: SourcePixels(width: 800, height: 1_000), preview: image))
        entry.analysis = analysis
        entry.analysisUnavailable = unavailable
        entry.isAnalyzing = analyzing
        entry.segmentation = segmentation
        entry.toneAssessment = tone
        entry.adjustment.background = background
        return entry
    }

    private func solution(_ checks: [AlignmentCheck]) -> CropSolution {
        CropSolution(adjustment: CropAdjustment(), checks: checks, headHeightFraction: 0.74, eyeLineFraction: 0.42)
    }

    private func analysis(faces: Int = 1, checks: [AlignmentCheck] = [], smudge: Double? = nil) -> FaceAnalysis {
        FaceAnalysis(faceCount: faces, geometry: nil, solution: faces == 1 ? solution(checks) : nil, visionRollDegrees: nil, lensSmudgeConfidence: smudge)
    }

    /// Builds a segmentation whose derived states match the requested ones.
    private func segmentation(background: CheckState, mask: CheckState) throws -> SegmentationResult {
        let space = try #require(CGColorSpace(name: CGColorSpace.linearGray))
        let context = try #require(CGContext(data: nil, width: 8, height: 10, bitsPerComponent: 8, bytesPerRow: 0,
                                             space: space, bitmapInfo: CGImageAlphaInfo.none.rawValue))
        let image = try #require(context.makeImage())
        let assessment: BackgroundAssessment = switch background {
        case .pass: BackgroundAssessment(meanLuminance: 0.92, luminanceDeviation: 0.02, sampleFraction: 0.4)
        case .warn: BackgroundAssessment(meanLuminance: 0.70, luminanceDeviation: 0.02, sampleFraction: 0.4)
        case .fail: BackgroundAssessment(meanLuminance: 0.50, luminanceDeviation: 0.30, sampleFraction: 0.4)
        case .manualCheck: BackgroundAssessment(meanLuminance: 0.9, luminanceDeviation: 0.02, sampleFraction: 0.01)
        }
        #expect(assessment.state == background)
        let statistics = MaskStatistics(coverage: 0.4, faceCoverage: 1, uncertainRatio: 0.05, topEdgeForeground: 0)
        return SegmentationResult(mask: image, method: .foregroundInstance, statistics: statistics,
                                  quality: MaskQuality(state: mask, reasons: []), background: assessment)
    }

    @Test func checkingWhileAnalysisRuns() throws {
        let summary = CheckPresentation.summary(for: try entry(analyzing: true), whiteApplied: false, sourceIsSmall: false)
        #expect(summary.headline == .checking && summary.rows.isEmpty)
    }

    @Test func allGoodIsLooksGood() throws {
        let good = analysis(checks: [
            AlignmentCheck(kind: .faceCount, state: .pass, measured: 1), AlignmentCheck(kind: .roll, state: .pass, measured: 2),
            AlignmentCheck(kind: .headHeight, state: .pass, measured: 0.74), AlignmentCheck(kind: .eyeLine, state: .pass, measured: 0.42)
        ])
        let summary = CheckPresentation.summary(for: try entry(analysis: good, segmentation: try segmentation(background: .warn, mask: .pass),
                                                               tone: ToneAssessment(issues: []), background: .color(.white)),
                                                whiteApplied: true, sourceIsSmall: false)
        #expect(summary.headline == .good)
        #expect(summary.rows.map(\.topic) == [.face, .framing, .background, .light])
        #expect(summary.rows.allSatisfy { $0.state == .pass })
    }

    @Test func warningsMeanReviewAndFailuresMeanRetake() throws {
        let tilted = analysis(checks: [AlignmentCheck(kind: .roll, state: .warn, measured: 12), AlignmentCheck(kind: .headHeight, state: .pass, measured: 0.7)])
        var summary = CheckPresentation.summary(for: try entry(analysis: tilted), whiteApplied: false, sourceIsSmall: false)
        #expect(summary.headline == .review)
        #expect(summary.rows.first { $0.topic == .face }?.state == .warn)

        let cut = analysis(checks: [AlignmentCheck(kind: .headroom, state: .fail, measured: 0)])
        summary = CheckPresentation.summary(for: try entry(analysis: cut), whiteApplied: false, sourceIsSmall: false)
        #expect(summary.headline == .retake)
        #expect(summary.rows.first { $0.topic == .framing }?.state == .fail)

        summary = CheckPresentation.summary(for: try entry(analysis: analysis(faces: 2)), whiteApplied: false, sourceIsSmall: false)
        #expect(summary.headline == .retake && summary.rows.first?.topic == .face)
    }

    @Test func unavailableAnalysisIsManualNotFailure() throws {
        let summary = CheckPresentation.summary(for: try entry(unavailable: true), whiteApplied: false, sourceIsSmall: true)
        #expect(summary.headline == .review)
        #expect(summary.rows.map(\.topic) == [.face, .background, .detail])
        #expect(summary.rows.allSatisfy { $0.state == .manualCheck || $0.state == .warn })
    }

    @Test func backgroundRowReflectsChoiceAndQuality() throws {
        let plain = try segmentation(background: .fail, mask: .fail)
        var summary = CheckPresentation.summary(for: try entry(analysis: analysis(), segmentation: plain), whiteApplied: false, sourceIsSmall: false)
        #expect(summary.rows.first { $0.topic == .background }?.state == .fail)
        let replaceable = try segmentation(background: .fail, mask: .pass)
        summary = CheckPresentation.summary(for: try entry(analysis: analysis(), segmentation: replaceable), whiteApplied: false, sourceIsSmall: false)
        #expect(summary.rows.first { $0.topic == .background }?.state == .warn)
        summary = CheckPresentation.summary(for: try entry(analysis: analysis(), segmentation: replaceable, background: .color(.white)), whiteApplied: true, sourceIsSmall: false)
        #expect(summary.rows.first { $0.topic == .background }?.state == .pass)
    }
}
