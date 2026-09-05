import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class SpikeModel {
    enum State: Equatable {
        case idle
        case startingCamera
        case cameraReady
        case capturing
        case processing
        case passed
        case failed(String)

        var title: String {
            switch self {
            case .idle: "Ready to start"
            case .startingCamera: "Starting AVFoundation…"
            case .cameraReady: "Camera ready"
            case .capturing: "Capturing high-resolution still…"
            case .processing: "Running Vision → segmentation → Core Image → export…"
            case .passed: "M1 core pipeline PASS"
            case .failed(let message): "FAIL — \(message)"
            }
        }
    }

    @ObservationIgnored let camera = CaptureService()
    @ObservationIgnored private let pipeline = ImagePipeline()

    var state: State = .idle
    var cameraStartEvidence: CameraStartEvidence?
    var cameraEntryToPreviewMilliseconds: Double?
    var outputPreview: UIImage?
    var exportURL: URL?
    var reportURL: URL?
    var report: SpikeRunReport?

    @ObservationIgnored private var cameraEntryInstant: ContinuousClock.Instant?

    var canStartCamera: Bool {
        switch state {
        case .idle, .failed: true
        default: false
        }
    }

    var canCapture: Bool {
        state == .cameraReady
    }

    func startCamera() async {
        state = .startingCamera
        cameraEntryInstant = .now
        cameraEntryToPreviewMilliseconds = nil
        outputPreview = nil
        exportURL = nil
        reportURL = nil
        report = nil

        do {
            cameraStartEvidence = try await camera.start()
            state = .cameraReady
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func noteFirstPreviewFrame() {
        guard cameraEntryToPreviewMilliseconds == nil, let cameraEntryInstant else { return }
        cameraEntryToPreviewMilliseconds = milliseconds(since: cameraEntryInstant)
    }

    func captureAndRunPipeline() async {
        guard canCapture else { return }
        state = .capturing

        do {
            let captured = try await camera.capturePhoto()
            state = .processing
            let result = try await pipeline.process(
                captured,
                cameraEntryToPreviewMilliseconds: cameraEntryToPreviewMilliseconds
            )

            exportURL = result.exportURL
            reportURL = result.reportURL
            report = result.report
            outputPreview = UIImage(contentsOfFile: result.exportURL.path)
            state = result.report.passed
                ? .passed
                : .failed("Post-export verification did not satisfy the M1 invariants.")
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
