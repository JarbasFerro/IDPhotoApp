@preconcurrency import AVFoundation
import CoreVideo
import Foundation
import OSLog
import Vision

/// Result of the slow (about five frames per second) Vision pass over a live frame.
struct SlowFrameResult: Sendable, Hashable {
    var pitchDegrees: Double?
    var distanceCM: Double?
    var lighting: LightingSummary?
    var faceFound: Bool
    var processingMilliseconds: Int
}

/// Runs face landmarks and luminance statistics on video frames at a throttled rate. Frames arrive upright
/// and unmirrored (the controller rotates the connection), so image-right is the subject's left.
///
/// Safety: AVFoundation calls the delegate serially on `queue`; every stored property is read and written only
/// on that queue, except the field of view, which is guarded by its lock.
final class FrameAnalyzer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let queue = DispatchQueue(label: "com.jarbasferro.IDPhotoSpike.frames", qos: .userInitiated)
    /// Minimum interval between processed frames. Face landmarks at 480p cost a few milliseconds; the
    /// throttle keeps the thermal budget flat (C9-002).
    var minimumInterval: Duration = .milliseconds(200)
    private let onResult: @Sendable (SlowFrameResult) -> Void
    private let logger = Logger(subsystem: "com.jarbasferro.IDPhotoSpike", category: "Frames")
    private var lastProcessed: ContinuousClock.Instant?
    private let request: VNDetectFaceLandmarksRequest = {
        let request = VNDetectFaceLandmarksRequest()
        request.revision = VNDetectFaceLandmarksRequestRevision3
        return request
    }()
    private let fieldOfViewLock = OSAllocatedUnfairLock<Double?>(initialState: nil)
    private var visionFailed = false

    init(onResult: @escaping @Sendable (SlowFrameResult) -> Void) {
        self.onResult = onResult
    }

    /// Horizontal field of view of the active format; the focal length follows from each frame's long side.
    func setFieldOfView(degrees: Double) {
        fieldOfViewLock.withLock { $0 = degrees }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = ContinuousClock.now
        if let last = lastProcessed, now - last < minimumInterval { return }
        lastProcessed = now
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        onResult(analyze(buffer, started: now))
    }

    private func analyze(_ buffer: CVPixelBuffer, started: ContinuousClock.Instant) -> SlowFrameResult {
        let width = CVPixelBufferGetWidth(buffer), height = CVPixelBufferGetHeight(buffer)
        var result = SlowFrameResult(faceFound: false, processingMilliseconds: 0)
        defer { result.processingMilliseconds = Int(started.duration(to: .now) / .milliseconds(1)) }
        guard !visionFailed else { return result }
        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
            try handler.perform([request])
        } catch {
            // Simulators and some environments cannot create an inference context; stop trying.
            visionFailed = true
            logger.notice("Live face analysis unavailable: \(error.localizedDescription, privacy: .public)")
            return result
        }
        guard let face = (request.results ?? []).max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
        else { return result }
        result.faceFound = true
        if let pitch = face.pitch?.doubleValue { result.pitchDegrees = pitch * 180 / .pi }

        // Vision uses a bottom-left origin; convert to top-left pixel coordinates.
        let size = CGSize(width: width, height: height)
        let box = VNImageRectForNormalizedRect(face.boundingBox, width, height)
        let faceRect = (x: Int(box.minX), y: Int(size.height - box.maxY), width: Int(box.width), height: Int(box.height))

        if let left = face.landmarks?.leftPupil?.pointsInImage(imageSize: size).first,
           let right = face.landmarks?.rightPupil?.pointsInImage(imageSize: size).first,
           let fieldOfView = fieldOfViewLock.withLock({ $0 }),
           let focal = FaceLighting.focalLengthPixels(fieldOfViewDegrees: fieldOfView, longSidePixels: Double(max(width, height))) {
            let ied = hypot(left.x - right.x, left.y - right.y)
            result.distanceCM = FaceLighting.distanceCM(interpupillaryPixels: ied, focalLengthPixels: focal)
        }

        // Luma plane of the 420 buffer; BGRA falls back to nil (lighting hints are then unavailable).
        guard CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
                || CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange else { return result }
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddressOfPlane(buffer, 0) else { return result }
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
        let luma = UnsafeBufferPointer(start: base.assumingMemoryBound(to: UInt8.self), count: bytesPerRow * height)
        result.lighting = FaceLighting.analyze(luma: luma, width: width, height: height, bytesPerRow: bytesPerRow, face: faceRect)
        return result
    }
}
