@preconcurrency import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let onFirstPreviewFrame: @MainActor () -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.attach(session: session)
        view.beginFirstFrameProbe(onFirstPreviewFrame)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.attach(session: session)
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
