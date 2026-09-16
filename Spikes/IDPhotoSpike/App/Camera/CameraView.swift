import AVFoundation
import AVKit
import SwiftUI
import UIKit

/// Hosts the controller's preview layer. UIKit is used only because SwiftUI has no camera preview surface.
struct CameraPreviewView: UIViewRepresentable {
    let layer: AVCaptureVideoPreviewLayer

    final class HostView: UIView {
        var previewLayer: AVCaptureVideoPreviewLayer? {
            didSet {
                oldValue?.removeFromSuperlayer()
                if let previewLayer { self.layer.addSublayer(previewLayer) }
                setNeedsLayout()
            }
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin(); CATransaction.setDisableActions(true)
            previewLayer?.frame = bounds
            CATransaction.commit()
        }
    }

    func makeUIView(context: Context) -> HostView {
        let view = HostView()
        view.backgroundColor = .black
        view.previewLayer = layer
        return view
    }

    func updateUIView(_ uiView: HostView, context: Context) {
        if uiView.previewLayer !== layer { uiView.previewLayer = layer }
    }
}

/// Guided camera: edge-to-edge preview, one calm hint, a head guide, and a large shutter (Signature 1).
/// Start-up and shutter timings from the last camera session, for the spike report.
struct CameraMetrics: Sendable, Hashable {
    let startupMilliseconds: Int?
    let captureMilliseconds: Int?
}

struct CameraView: View {
    let onCapture: (StagedPhoto, CameraMetrics) -> Void
    @State private var camera = CameraController()
    @State private var errorMessage: String?
    @State private var flash = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch camera.state {
            case .running, .interrupted, .configuring:
                CameraPreviewView(layer: camera.previewLayer)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                headGuide
                overlayControls
                // Immediate acknowledgement of the shutter press while the still is processed.
                Color.white.ignoresSafeArea().opacity(flash ? 0.85 : 0).allowsHitTesting(false)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: flash)
            case .denied:
                deniedView
            case .unavailable:
                unavailableView
            case .failed(let message):
                ContentUnavailableView(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.white)
            case .idle, .requestingAccess:
                ProgressView().tint(.white)
            }
        }
        .task { await camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { camera.stop() } else if phase == .active { Task { await camera.start() } }
        }
        .onCameraCaptureEvent(isEnabled: camera.state == .running) { event in
            if event.phase == .ended { takePhoto() }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: camera.isCapturing) { _, capturing in capturing }
        .onChange(of: camera.hint) { _, hint in
            // One spoken update per hint change; hints are already debounced.
            AccessibilityNotification.Announcement(String(localized: CameraPresentation.text(for: hint))).post()
        }
        .alert("Unable to take the photo", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }

    private var headGuide: some View {
        GeometryReader { geometry in
            // Sized for a comfortable arm's-length framing; the guide is a composition aid, not the final crop.
            let height = geometry.size.height * 0.32
            let width = height * 0.78
            Ellipse()
                .strokeBorder(camera.hint == .ready ? Color.green : Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .frame(width: width, height: height)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.44)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: camera.hint == .ready)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var overlayControls: some View {
        VStack {
            HStack {
                Spacer()
                Label(CameraPresentation.text(for: camera.hint), systemImage: CameraPresentation.symbol(for: camera.hint))
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .accessibilityIdentifier("cameraHint")
                Spacer()
            }
            .padding(.top, 12)
            if camera.state == .interrupted {
                Text("Camera paused. It resumes when the interruption ends.")
                    .font(.footnote).padding(8).background(.regularMaterial, in: Capsule())
            }
            #if DEBUG
            if let startup = camera.startupMilliseconds {
                Text("start \(startup) ms" + (camera.lastCaptureMilliseconds.map { " · last capture \($0) ms" } ?? "") + " · " + camera.studioLightStatus)
                    .font(.caption2.monospacedDigit()).padding(6).background(.regularMaterial, in: Capsule())
                    .accessibilityHidden(true)
            }
            #endif
            Spacer()
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("cameraCancel")
                Spacer()
                Button(action: takePhoto) {
                    ZStack {
                        Circle().strokeBorder(.white, lineWidth: 4).frame(width: 76, height: 76)
                        Circle().fill(.white).frame(width: 62, height: 62)
                    }
                }
                .disabled(camera.state != .running || camera.isCapturing)
                .opacity(camera.isCapturing ? 0.5 : 1)
                .accessibilityLabel("Take Photo")
                .accessibilityHint(Text(CameraPresentation.text(for: camera.hint)))
                .accessibilityIdentifier("shutter")
                Spacer()
                Button { camera.switchCamera() } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.title2).frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Switch Camera")
                .accessibilityIdentifier("switchCamera")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .foregroundStyle(.white)
    }

    private var deniedView: some View {
        VStack(spacing: 16) {
            ContentUnavailableView {
                Label("Camera access is off", systemImage: "camera.badge.ellipsis")
            } description: {
                Text("Allow camera access in Settings, or choose an existing photo instead. Photos stay on this iPhone.")
            }
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link("Open Settings", destination: url).buttonStyle(.borderedProminent)
            }
            Button("Choose Photo Instead") { dismiss() }.buttonStyle(.bordered)
        }
        .padding()
        .foregroundStyle(.white)
    }

    private var unavailableView: some View {
        VStack(spacing: 16) {
            ContentUnavailableView("No camera on this device", systemImage: "camera.slash",
                                   description: Text("Choose an existing photo instead."))
            Button("Choose Photo Instead") { dismiss() }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("cameraUnavailableChoose")
        }
        .padding()
        .foregroundStyle(.white)
    }

    private func takePhoto() {
        guard camera.state == .running, !camera.isCapturing else { return }
        flash = true
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            flash = false
        }
        Task {
            do {
                let staged = try await camera.capture()
                onCapture(staged, CameraMetrics(startupMilliseconds: camera.startupMilliseconds,
                                                captureMilliseconds: camera.lastCaptureMilliseconds))
            } catch {
                errorMessage = (error as? CameraError)?.errorDescription ?? CameraError.captureFailed.errorDescription
            }
        }
    }
}

enum CameraPresentation {
    static func text(for hint: CaptureHint) -> LocalizedStringResource {
        switch hint {
        case .noFace: "Show your face in the oval"
        case .multipleFaces: "Only one person in the frame"
        case .moveCloser: "Move a little closer"
        case .moveBack: "Move a little farther away"
        case .centerFace: "Centre your face in the oval"
        case .keepLevel: "Keep your head level"
        case .faceCamera: "Look straight at the camera"
        case .holdStill: "Hold still"
        case .ready: "Ready. Take the photo."
        }
    }

    static func symbol(for hint: CaptureHint) -> String {
        switch hint {
        case .ready: "checkmark.circle"
        case .holdStill: "hand.raised"
        case .noFace, .multipleFaces: "person.crop.circle.badge.questionmark"
        case .moveCloser, .moveBack: "arrow.up.left.and.arrow.down.right"
        case .centerFace: "scope"
        case .keepLevel: "level"
        case .faceCamera: "face.dashed"
        }
    }
}
