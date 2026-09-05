import Foundation

struct ExportVerification: Codable, Sendable {
    let width: Int
    let height: Int
    let typeIdentifier: String
    let containsGPSMetadata: Bool
    let orientation: Int?
    let expectedWidth: Int
    let expectedHeight: Int
    let passed: Bool
}

struct SpikeRunReport: Codable, Sendable {
    let schemaVersion: Int
    let createdAt: String
    let hardwareIdentifier: String
    let operatingSystem: String
    let requestedCaptureWidth: Int32
    let requestedCaptureHeight: Int32
    let resolvedCaptureWidth: Int32
    let resolvedCaptureHeight: Int32
    let cameraEntryToPreviewMilliseconds: Double?
    let captureMilliseconds: Double
    let normalizedSourceWidth: Int
    let normalizedSourceHeight: Int
    let faceCount: Int
    let primaryFaceBoundingBox: [Double]
    let faceDetectionMilliseconds: Double
    let personSegmentationMilliseconds: Double
    let iterativeSegmentationStatus: String
    let iterativeSegmentationMilliseconds: Double?
    let renderAndExportMilliseconds: Double
    let totalPipelineMilliseconds: Double
    let exportVerification: ExportVerification
    let notes: [String]

    var passed: Bool {
        faceCount > 0 && exportVerification.passed
    }
}

struct PipelineResult: Sendable {
    let exportURL: URL
    let reportURL: URL
    let report: SpikeRunReport
}

enum PipelineError: LocalizedError {
    case cannotDecodeCapture
    case cannotCreateCGImage
    case noFace
    case noPersonMask
    case cannotCreateSRGB

    var errorDescription: String? {
        switch self {
        case .cannotDecodeCapture: "ImageIO/Core Image could not decode the captured still."
        case .cannotCreateCGImage: "Core Image could not materialize an orientation-normalized CGImage."
        case .noFace: "Vision did not detect a face in the captured photo."
        case .noPersonMask: "Vision did not generate a person-instance segmentation mask."
        case .cannotCreateSRGB: "The sRGB color space is unavailable."
        }
    }
}
