@preconcurrency import AVFoundation
import Dispatch
import Foundation

struct CameraStartEvidence: Sendable {
    let sessionStartMilliseconds: Double
    let requestedPhotoWidth: Int32
    let requestedPhotoHeight: Int32
}

struct CapturedPhoto: Sendable {
    let data: Data
    let requestedWidth: Int32
    let requestedHeight: Int32
    let resolvedWidth: Int32
    let resolvedHeight: Int32
    let captureMilliseconds: Double
}

enum CaptureServiceError: LocalizedError {
    case cameraDenied
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    case notConfigured
    case captureAlreadyInProgress
    case noPhotoData

    var errorDescription: String? {
        switch self {
        case .cameraDenied: "Camera access is denied or restricted."
        case .cameraUnavailable: "A rear camera is not available."
        case .cannotAddInput: "The camera input cannot be added to the capture session."
        case .cannotAddOutput: "The photo output cannot be added to the capture session."
        case .notConfigured: "The capture session is not configured."
        case .captureAlreadyInProgress: "A photo capture is already in progress."
        case .noPhotoData: "AVFoundation returned no encoded photo data."
        }
    }
}

/// A deliberately narrow bridge that transports the identity of an `AVCaptureSession`
/// from the capture actor to the main-actor preview layer.
///
/// Safety proof for `@unchecked Sendable`:
/// - `session` is immutable reference identity after initialization.
/// - All session configuration, start/stop, and capture mutation happens only inside
///   `CaptureService`, whose executor is one serial dispatch queue.
/// - Main-actor code may only attach this exact reference to
///   `AVCaptureVideoPreviewLayer.session`; it never configures or starts/stops it.
/// - The bridge contains no other mutable application state.
final class CaptureSessionPreviewHandle: @unchecked Sendable {
    let session: AVCaptureSession

    init(session: AVCaptureSession) {
        self.session = session
    }
}

actor CaptureService {
    private let captureSession: AVCaptureSession
    nonisolated let previewHandle: CaptureSessionPreviewHandle

    private let sessionQueue = DispatchSerialQueue(
        label: "com.jarbasferro.IDPhoto.M1PipelineSpike.capture-session"
    )

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }

    private let photoOutput = AVCapturePhotoOutput()
    private var configured = false
    private var requestedDimensions = CMVideoDimensions(width: 0, height: 0)
    private var activePhotoDelegate: PhotoCaptureDelegate?

    init() {
        let session = AVCaptureSession()
        captureSession = session
        previewHandle = CaptureSessionPreviewHandle(session: session)
    }

    func start() async throws -> CameraStartEvidence {
        try await authorizeCameraAtPointOfUse()
        if !configured {
            try configureSession()
        }

        let start = ContinuousClock.now
        if !captureSession.isRunning {
            captureSession.startRunning()
        }

        return CameraStartEvidence(
            sessionStartMilliseconds: milliseconds(since: start),
            requestedPhotoWidth: requestedDimensions.width,
            requestedPhotoHeight: requestedDimensions.height
        )
    }

    func stop() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    func capturePhoto() async throws -> CapturedPhoto {
        guard configured, captureSession.isRunning else {
            throw CaptureServiceError.notConfigured
        }
        guard activePhotoDelegate == nil else {
            throw CaptureServiceError.captureAlreadyInProgress
        }

        let settings = makePhotoSettings()
        let start = ContinuousClock.now
        let captured: CapturedPhoto = try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate(
                requestedDimensions: requestedDimensions,
                captureStart: start,
                continuation: continuation
            )
            activePhotoDelegate = delegate
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }

        // AVCam-style lifetime discipline: retain through didFinishCaptureFor.
        activePhotoDelegate = nil
        return captured
    }

    private func authorizeCameraAtPointOfUse() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                throw CaptureServiceError.cameraDenied
            }
        case .denied, .restricted:
            throw CaptureServiceError.cameraDenied
        @unknown default:
            throw CaptureServiceError.cameraDenied
        }
    }

    private func configureSession() throws {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CaptureServiceError.cameraUnavailable
        }

        let input = try AVCaptureDeviceInput(device: camera)

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        captureSession.sessionPreset = .photo
        captureSession.automaticallyRunsDeferredStart = true

        guard captureSession.canAddInput(input) else {
            throw CaptureServiceError.cannotAddInput
        }
        captureSession.addInput(input)

        if photoOutput.isDeferredStartSupported {
            photoOutput.isDeferredStartEnabled = true
        }
        guard captureSession.canAddOutput(photoOutput) else {
            throw CaptureServiceError.cannotAddOutput
        }
        captureSession.addOutput(photoOutput)

        photoOutput.maxPhotoQualityPrioritization = .quality
        if photoOutput.isResponsiveCaptureSupported {
            photoOutput.isResponsiveCaptureEnabled = true
        }

        if let largest = camera.activeFormat.supportedMaxPhotoDimensions.max(by: {
            Int64($0.width) * Int64($0.height) < Int64($1.width) * Int64($1.height)
        }) {
            requestedDimensions = largest
            photoOutput.maxPhotoDimensions = largest
        }

        // Give AVFoundation an early resource hint without blocking first preview.
        // With deferred start enabled, preparation work participates in the session's deferred work.
        photoOutput.setPreparedPhotoSettingsArray([makePhotoSettings()])
        configured = true
    }

    private func makePhotoSettings() -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .quality
        if requestedDimensions.width > 0, requestedDimensions.height > 0 {
            settings.maxPhotoDimensions = requestedDimensions
        }
        return settings
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let requestedDimensions: CMVideoDimensions
    private let captureStart: ContinuousClock.Instant
    private var continuation: CheckedContinuation<CapturedPhoto, Error>?
    private var processedResult: Result<CapturedPhoto, Error>?
    private let lock = NSLock()

    init(
        requestedDimensions: CMVideoDimensions,
        captureStart: ContinuousClock.Instant,
        continuation: CheckedContinuation<CapturedPhoto, Error>
    ) {
        self.requestedDimensions = requestedDimensions
        self.captureStart = captureStart
        self.continuation = continuation
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            storeProcessedResult(.failure(error))
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            storeProcessedResult(.failure(CaptureServiceError.noPhotoData))
            return
        }

        let resolved = photo.resolvedSettings.photoDimensions
        storeProcessedResult(.success(CapturedPhoto(
            data: data,
            requestedWidth: requestedDimensions.width,
            requestedHeight: requestedDimensions.height,
            resolvedWidth: resolved.width,
            resolvedHeight: resolved.height,
            captureMilliseconds: milliseconds(since: captureStart)
        )))
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        if let error {
            finish(.failure(error))
            return
        }

        lock.lock()
        let processedResult = self.processedResult
        lock.unlock()
        finish(processedResult ?? .failure(CaptureServiceError.noPhotoData))
    }

    private func storeProcessedResult(_ result: Result<CapturedPhoto, Error>) {
        lock.lock()
        processedResult = result
        lock.unlock()
    }

    private func finish(_ result: Result<CapturedPhoto, Error>) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }
}

func milliseconds(since start: ContinuousClock.Instant) -> Double {
    let duration = start.duration(to: .now)
    let components = duration.components
    return Double(components.seconds) * 1_000 + Double(components.attoseconds) / 1_000_000_000_000_000
}
