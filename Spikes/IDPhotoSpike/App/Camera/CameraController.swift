@preconcurrency import AVFoundation
import CoreMotion
import Foundation
import Observation
import OSLog
import UIKit

enum CameraError: Error, LocalizedError, Sendable {
    case unavailable, configurationFailed, captureFailed, noPhotoData

    var errorDescription: String? {
        switch self {
        case .unavailable: String(localized: "No camera is available on this device.")
        case .configurationFailed: String(localized: "The camera could not be set up. Try again.")
        case .captureFailed: String(localized: "The photo could not be taken. Try again.")
        case .noPhotoData: String(localized: "The camera returned no photo. Try again.")
        }
    }
}

/// AVFoundation capture session for the guided camera (FR-020, FR-021, FR-023).
///
/// Threading contract: `session`, `photoOutput`, `metadataOutput`, and `videoInput` are created on the main
/// actor and afterwards configured, started, stopped, and asked to capture only on `sessionQueue`. The main
/// actor only hands `session` to the preview layer and reads immutable properties, which AVFoundation permits.
/// Face metadata is delivered on the main queue by request, so guidance stays on the main actor.
@MainActor
@Observable
final class CameraController: NSObject {
    enum State: Equatable, Sendable {
        case idle, requestingAccess, denied, unavailable, configuring, running, interrupted, failed(String)
    }

    private(set) var state: State = .idle
    private(set) var hint: CaptureHint = .noFace
    private(set) var readiness = CaptureReadiness()
    /// Head roll relative to the camera from the last frame, for the eye-line indicator.
    private(set) var faceRollDegrees: Double?
    /// Phone attitude from Core Motion, nil until the first sample.
    private(set) var deviceLevel: DeviceLevel?
    /// Latest slow-pass result, for the debug overlay.
    private(set) var lastSlowFrame: SlowFrameResult?
    private(set) var position: AVCaptureDevice.Position = .front
    private(set) var isCapturing = false
    /// Milliseconds from `start()` to the running session, for the spike report.
    private(set) var startupMilliseconds: Int?
    private(set) var lastCaptureMilliseconds: Int?

    let previewLayer = AVCaptureVideoPreviewLayer()
    nonisolated(unsafe) let session = AVCaptureSession()
    nonisolated(unsafe) private let photoOutput = AVCapturePhotoOutput()
    nonisolated(unsafe) private let metadataOutput = AVCaptureMetadataOutput()
    nonisolated(unsafe) private let videoDataOutput = AVCaptureVideoDataOutput()
    @ObservationIgnored nonisolated(unsafe) private var videoInput: AVCaptureDeviceInput?
    @ObservationIgnored nonisolated(unsafe) private var frameAnalyzer: FrameAnalyzer?
    @ObservationIgnored private let motionManager = CMMotionManager()
    @ObservationIgnored private var slowFrame: (result: SlowFrameResult, at: ContinuousClock.Instant)?
    @ObservationIgnored private var lastExposurePoint: (point: CGPoint, at: ContinuousClock.Instant)?
    private let sessionQueue = DispatchQueue(label: "com.jarbasferro.IDPhotoSpike.camera", qos: .userInitiated)
    private let signposter = OSSignposter(subsystem: "com.jarbasferro.IDPhotoSpike", category: "Camera")
    private let logger = Logger(subsystem: "com.jarbasferro.IDPhotoSpike", category: "Camera")
    @ObservationIgnored private var tracker = GuidanceTracker()
    @ObservationIgnored private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    @ObservationIgnored private var rotationObservation: NSKeyValueObservation?
    @ObservationIgnored private var notificationTokens: [NSObjectProtocol] = []
    @ObservationIgnored private var inFlight: [Int64: PhotoCaptureProcessor] = [:]
    @ObservationIgnored private var isStarting = false

    override init() {
        super.init()
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        frameAnalyzer = FrameAnalyzer { [weak self] result in
            Task { @MainActor in self?.receive(result) }
        }
    }

    /// 12.6 MP: covers 4032 x 3024 stills while excluding 24 and 48 MP modes.
    nonisolated static let maxStillPixels = 12_600_000

    static var isSupported: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
            || AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    // MARK: - Lifecycle

    /// Requests access at point of use, configures once, and starts (or restarts) the session.
    /// Safe to call again after an interruption, a lock/unlock cycle, or a denied-then-granted permission.
    func start() async {
        guard !isStarting, state != .unavailable else { return }
        if state == .running, session.isRunning { return }
        isStarting = true
        defer { isStarting = false }
        guard Self.isSupported else { state = .unavailable; return }
        let started = ContinuousClock.now
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            state = .requestingAccess
            guard await AVCaptureDevice.requestAccess(for: .video) else { state = .denied; return }
        default:
            state = .denied
            return
        }
        state = .configuring
        installObservers()
        let interval = signposter.beginInterval("CameraStart")
        let requestedPosition = position
        let result = await withCheckedContinuation { (continuation: CheckedContinuation<Result<Void, CameraError>, Never>) in
            sessionQueue.async { [self] in
                do {
                    if videoInput == nil { try configureSession(position: requestedPosition) }
                    if !session.isRunning { session.startRunning() }
                    continuation.resume(returning: .success(()))
                } catch let error as CameraError {
                    continuation.resume(returning: .failure(error))
                } catch {
                    continuation.resume(returning: .failure(.configurationFailed))
                }
            }
        }
        signposter.endInterval("CameraStart", interval)
        switch result {
        case .success:
            startupMilliseconds = Int(started.duration(to: .now) / .milliseconds(1))
            state = .running
            installRotationCoordinator()
            startMotionUpdates()
            if let format = videoInput?.device.activeFormat { frameAnalyzer?.setFieldOfView(degrees: Double(format.videoFieldOfView)) }
        case .failure(let error):
            state = .failed(error.localizedDescription)
        }
    }

    func stop() {
        sessionQueue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
        if state == .running || state == .interrupted || state == .configuring { state = .idle }
        motionManager.stopDeviceMotionUpdates()
        deviceLevel = nil
        slowFrame = nil
        tracker = GuidanceTracker()
        hint = .noFace
        readiness = CaptureReadiness()
        faceRollDegrees = nil
    }

    func switchCamera() {
        guard state == .running else { return }
        let next: AVCaptureDevice.Position = position == .front ? .back : .front
        position = next
        tracker = GuidanceTracker()
        slowFrame = nil
        sessionQueue.async { [self] in
            do { try configureSession(position: next) } catch { logger.error("Camera switch failed") }
        }
        installRotationCoordinator()
        if let format = videoInput?.device.activeFormat { frameAnalyzer?.setFieldOfView(degrees: Double(format.videoFieldOfView)) }
    }

    // MARK: - Motion (phone attitude)

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable, !motionManager.isDeviceMotionActive else { return }
        motionManager.deviceMotionUpdateInterval = 1 / 15
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            let g = motion.gravity
            // Device axes: x right, y towards the top edge, z out of the screen. Upright portrait: gravity (0, −1, 0).
            let roll = atan2(g.x, -g.y) * 180 / .pi
            let pitch = atan2(-g.z, sqrt(g.x * g.x + g.y * g.y)) * 180 / .pi
            MainActor.assumeIsolated { self?.deviceLevel = DeviceLevel(rollDegrees: roll, pitchDegrees: pitch) }
        }
    }

    // MARK: - Slow frame results

    private func receive(_ result: SlowFrameResult) {
        lastSlowFrame = result
        slowFrame = (result, .now)
    }

    /// Slow-pass values are folded into the per-frame summary while they are fresh (under a second).
    private var freshSlowFrame: SlowFrameResult? {
        guard let slowFrame, .now - slowFrame.at < .seconds(1), slowFrame.result.faceFound else { return nil }
        return slowFrame.result
    }

    /// Meter exposure and focus on the face so skin, not the wall, sets the exposure (throttled).
    private func meterOnFace(rawBounds: CGRect) {
        let point = CGPoint(x: rawBounds.midX, y: rawBounds.midY)
        let now = ContinuousClock.now
        if let last = lastExposurePoint, hypot(point.x - last.point.x, point.y - last.point.y) < 0.08, now - last.at < .seconds(1.5) { return }
        lastExposurePoint = (point, now)
        guard let device = videoInput?.device else { return }
        sessionQueue.async {
            guard (try? device.lockForConfiguration()) != nil else { return }
            defer { device.unlockForConfiguration() }
            if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposurePointOfInterest = point
                device.exposureMode = .continuousAutoExposure
            }
            if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .continuousAutoFocus
            }
        }
    }

    /// Full-quality still into the same private staging path as an import.
    func capture() async throws -> StagedPhoto {
        guard state == .running, !isCapturing else { throw CameraError.captureFailed }
        isCapturing = true
        defer { isCapturing = false }
        let started = ContinuousClock.now
        let interval = signposter.beginInterval("Capture")
        let rotation = rotationCoordinator?.videoRotationAngleForHorizonLevelCapture ?? 90
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            let processor = PhotoCaptureProcessor(continuation: continuation)
            sessionQueue.async { [self] in
                let settings: AVCapturePhotoSettings
                if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                } else {
                    settings = AVCapturePhotoSettings()
                }
                settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
                        settings.photoQualityPrioritization = .balanced
                if let connection = photoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(rotation) {
                    connection.videoRotationAngle = rotation
                }
                Task { @MainActor in self.inFlight[settings.uniqueID] = processor }
                photoOutput.capturePhoto(with: settings, delegate: processor)
            }
        }
        signposter.endInterval("Capture", interval)
        inFlight = inFlight.filter { !$0.value.isFinished }
        lastCaptureMilliseconds = Int(started.duration(to: .now) / .milliseconds(1))
        return try await StagedPhoto.stage(data: data)
    }

    // MARK: - Configuration (session queue only)

    nonisolated private func configureSession(position: AVCaptureDevice.Position) throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.unavailable
        }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo
        if let current = videoInput { session.removeInput(current) }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw CameraError.configurationFailed }
        session.addInput(input)
        videoInput = input

        if !session.outputs.contains(photoOutput) {
            guard session.canAddOutput(photoOutput) else { throw CameraError.configurationFailed }
            session.addOutput(photoOutput)
        }
        // An ID photo needs at most about 12 MP (a 35 x 45 mm print at 600 ppi is under 1 MP). Requesting the
        // sensor's 48 MP maximum with quality prioritization added seconds of processing per shot on the first
        // device run, so cap the still at the largest format up to 12 MP and use balanced processing.
        let dimensions = device.activeFormat.supportedMaxPhotoDimensions
        let capped = dimensions.filter { Int($0.width) * Int($0.height) <= Self.maxStillPixels }
        if let chosen = (capped.isEmpty ? dimensions : capped).max(by: { $0.width * $0.height < $1.width * $1.height }) {
            photoOutput.maxPhotoDimensions = chosen
        }
        photoOutput.maxPhotoQualityPrioritization = .balanced
        if photoOutput.isResponsiveCaptureSupported { photoOutput.isResponsiveCaptureEnabled = true }
        // Captured stills are never mirrored, even from the front camera; the preview mirrors itself.
        photoOutput.connection(with: .video)?.isVideoMirrored = false

        if !session.outputs.contains(metadataOutput), session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        }
        if metadataOutput.availableMetadataObjectTypes.contains(.face) {
            metadataOutput.metadataObjectTypes = [.face]
        }

        // Slow analysis frames: luma plane only, late frames dropped, delivered upright and unmirrored so the
        // analyser's left/right and pitch signs match the subject.
        if !session.outputs.contains(videoDataOutput), session.canAddOutput(videoDataOutput) {
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            if let analyzer = frameAnalyzer { videoDataOutput.setSampleBufferDelegate(analyzer, queue: analyzer.queue) }
            session.addOutput(videoDataOutput)
        }
        if let connection = videoDataOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
            if connection.isVideoMirroringSupported { connection.isVideoMirrored = false }
        }
    }

    private func installRotationCoordinator() {
        guard let device = videoInput?.device else { return }
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        rotationCoordinator = coordinator
        // The coordinator delivers KVO on the main queue.
        rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.initial, .new]) { [weak self] coordinator, _ in
            MainActor.assumeIsolated {
                guard let self, let connection = self.previewLayer.connection else { return }
                let angle = coordinator.videoRotationAngleForHorizonLevelPreview
                if connection.isVideoRotationAngleSupported(angle) { connection.videoRotationAngle = angle }
            }
        }
    }

    private func installObservers() {
        guard notificationTokens.isEmpty else { return }
        let center = NotificationCenter.default
        notificationTokens.append(center.addObserver(forName: AVCaptureSession.wasInterruptedNotification, object: session, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.state = .interrupted }
        })
        notificationTokens.append(center.addObserver(forName: AVCaptureSession.interruptionEndedNotification, object: session, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.state == .interrupted else { return }
                // Locking the phone interrupts the session and we stop it on background; on unlock the
                // interruption ends before the scene is active again, so restart explicitly.
                if self.session.isRunning { self.state = .running } else { self.state = .idle; Task { await self.start() } }
            }
        })
        notificationTokens.append(center.addObserver(forName: AVCaptureSession.runtimeErrorNotification, object: session, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.state = .failed(CameraError.configurationFailed.localizedDescription) }
        })
    }

    deinit {
        for token in notificationTokens { NotificationCenter.default.removeObserver(token) }
    }
}

// MARK: - Face metadata → guidance

// The delegate queue is the main queue, so the main-actor method satisfies the requirement; the
// @preconcurrency conformance adds a runtime isolation check rather than a compile-time hole.
extension CameraController: @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        do {
            let faces = metadataObjects.compactMap { $0 as? AVMetadataFaceObject }
            let layerBounds = previewLayer.bounds
            guard layerBounds.width > 0, layerBounds.height > 0 else { return }
            // Raw face angles are relative to the unrotated (landscape) sensor picture, so a level head reads
            // 90° when the phone is upright. The layer-transformed object carries angles in preview space.
            let largest = faces.compactMap { face -> (CGRect, AVMetadataFaceObject)? in
                guard let transformed = previewLayer.transformedMetadataObject(for: face) as? AVMetadataFaceObject else { return nil }
                return (transformed.bounds, transformed)
            }.max { $0.0.width * $0.0.height < $1.0.width * $1.0.height }
            var summary = FaceFrameSummary(
                faceCount: faces.count,
                bounds: largest.map { NormalizedCrop(x: $0.0.minX / layerBounds.width, y: $0.0.minY / layerBounds.height,
                                                     width: $0.0.width / layerBounds.width, height: $0.0.height / layerBounds.height) },
                rollDegrees: largest?.1.hasRollAngle == true ? largest?.1.rollAngle.normalizedRoll : nil,
                yawDegrees: largest?.1.hasYawAngle == true ? largest?.1.yawAngle.normalizedRoll : nil)
            summary.device = deviceLevel
            if let slow = freshSlowFrame {
                summary.pitchDegrees = slow.pitchDegrees
                summary.distanceCM = slow.distanceCM
                summary.lighting = slow.lighting
            }
            if let device = videoInput?.device {
                summary.lowLight = device.iso >= device.activeFormat.maxISO * 0.8
            }
            if faces.count == 1, let raw = faces.first { meterOnFace(rawBounds: raw.bounds) }
            let next = tracker.update(summary)
            readiness = tracker.readiness
            if faceRollDegrees != summary.rollDegrees { faceRollDegrees = summary.rollDegrees }
            if next != hint { hint = next }
        }
    }
}

private extension CGFloat {
    /// Face metadata angles are 0…360; express as −180…180.
    var normalizedRoll: Double { let d = Double(self); return d > 180 ? d - 360 : d }
}

/// Bridges `AVCapturePhotoCaptureDelegate` to a continuation.
///
/// Safety: AVFoundation invokes the delegate methods serially on the photo output's callback queue, and
/// `continuation` is resumed exactly once from that queue; no other code reads or writes it. `isFinished`
/// is set once, after resumption, and only read on the main actor afterwards.
final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private var continuation: CheckedContinuation<Data, Error>?
    private(set) var isFinished = false

    init(continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { continuation = nil; isFinished = true }
        if error != nil { continuation?.resume(throwing: CameraError.captureFailed); return }
        guard let data = photo.fileDataRepresentation() else { continuation?.resume(throwing: CameraError.noPhotoData); return }
        continuation?.resume(returning: data)
    }
}
