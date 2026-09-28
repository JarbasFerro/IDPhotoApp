@preconcurrency import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {
    let sessionHandle: CaptureSessionPreviewHandle
    let onFirstPreviewFrame: @MainActor () -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.attach(session: sessionHandle.session)
        view.beginFirstFrameProbe(onFirstPreviewFrame)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        if uiView.previewLayer.session !== sessionHandle.session {
            uiView.attach(session: sessionHandle.session)
        }
        uiView.beginFirstFrameProbe(onFirstPreviewFrame)
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    private var firstFrameTask: Task<Void, Never>?
    private var didReportFirstFrame = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        if previewLayer.isDeferredStartSupported {
            previewLayer.isDeferredStartEnabled = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        firstFrameTask?.cancel()
    }

    func attach(session: AVCaptureSession) {
        // This is the preview handle's only use of the session reference.
        // CaptureService remains the sole owner of session mutation.
        previewLayer.session = session
        didReportFirstFrame = false
    }

    func beginFirstFrameProbe(_ callback: @escaping @MainActor () -> Void) {
        guard !didReportFirstFrame, firstFrameTask == nil else { return }

        firstFrameTask = Task { @MainActor [weak self] in
            defer { self?.firstFrameTask = nil }
            for _ in 0..<300 {
                guard let self, !Task.isCancelled else { return }
                if previewLayer.isPreviewing {
                    didReportFirstFrame = true
                    callback()
                    return
                }
                try? await Task.sleep(for: .milliseconds(10))
            }
        }
    }
}
