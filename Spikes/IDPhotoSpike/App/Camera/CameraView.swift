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
    @State private var countdown: Int?
    /// New key on purpose: devices that ran 0.8 to 0.10.1 have the old key stored as true.
    @AppStorage("autoCaptureEnabled") private var autoCapture = false
    @AppStorage(DeveloperMode.key) private var developerMode = false
    /// The instructions screen (ring, then Auto) shows before the camera on every launch until dismissed for good.
    @AppStorage("cameraIntroDismissed") private var introDismissed = false
    @State private var introSeen = false
    @State private var showRingHelp = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showingIntro: Bool { !introDismissed && !introSeen }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if showingIntro {
                CameraIntroView(autoCapture: $autoCapture, dismissed: $introDismissed, cancel: { dismiss() }) { introSeen = true }
            } else {
                cameraContent
            }
        }
        .task(id: showingIntro) { if !showingIntro { await camera.start() } }
        .onDisappear { camera.stop() }
        .onChange(of: scenePhase) { _, phase in
            guard !showingIntro else { return }
            if phase == .background { camera.stop() } else if phase == .active { Task { await camera.start() } }
        }
        .onCameraCaptureEvent(isEnabled: camera.state == .running && !showingIntro) { event in
            if event.phase == .ended { takePhoto() }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: camera.isCapturing) { _, capturing in capturing }
        .sensoryFeedback(.selection, trigger: countdown) { _, value in value != nil }
        .sensoryFeedback(.success, trigger: camera.hint) { _, hint in hint == .ready }
        .task(id: "\(camera.hint.rawValue)-\(autoCapture)-\(showRingHelp)-\(showingIntro)") {
            // Auto capture: "ready" held through a visible countdown; any hint change cancels it. Never while the
            // instructions are showing.
            guard autoCapture, !showRingHelp, !showingIntro, camera.hint == .ready, camera.state == .running, !camera.isCapturing
            else { countdown = nil; return }
            // Three seconds: enough to stop reading the screen and look at the lens.
            for value in [3, 2, 1] {
                countdown = value
                AccessibilityNotification.Announcement("\(value)").post()
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { countdown = nil; return }
            }
            countdown = nil
            takePhoto()
        }
        .onChange(of: camera.hint) { _, hint in
            // One spoken update per hint change; hints are already debounced.
            AccessibilityNotification.Announcement(String(localized: CameraPresentation.text(for: hint))).post()
        }
        .alert("Unable to take the photo", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .sheet(isPresented: $showRingHelp) {
            CameraIntroView(autoCapture: $autoCapture, dismissed: $introDismissed, cancel: nil) { showRingHelp = false }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }

    @ViewBuilder private var cameraContent: some View {
        Group {
            switch camera.state {
            case .running, .interrupted, .configuring:
                CameraPreviewView(layer: camera.previewLayer)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                headGuide
                eyeLine
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
    }

    private var headGuide: some View {
        GeometryReader { geometry in
            // Sized for a comfortable arm's-length framing; the guide is a composition aid, not the final crop.
            let height = geometry.size.height * 0.32
            let width = height * 0.78
            Ellipse()
                .strokeBorder(camera.hint == .ready ? StatusStyle.pass : Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .frame(width: width, height: height)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.44)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: camera.hint == .ready)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The detected eye line, rotated by the head's roll relative to the camera; green when level in the frame.
    /// What matters is this relative angle, not the phone's absolute attitude.
    @ViewBuilder private var eyeLine: some View {
        if let roll = camera.faceRollDegrees, abs(roll) < 25 {
            GeometryReader { geometry in
                let ok = abs(roll) <= CaptureGuidanceThresholds.default.maxRollDegrees
                Rectangle()
                    .fill(ok ? StatusStyle.pass : Color.white.opacity(0.8))
                    .frame(width: ok ? 140 : 110, height: 2)
                    .rotationEffect(.degrees(roll))
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.44)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: ok)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// The shutter with the readiness ring around it: four arcs (framing, head position, light, distance) that
    /// turn green as checks pass; when everything is ready the ring closes and the countdown runs inside.
    private var shutter: some View {
        let ready = camera.hint == .ready
        return ZStack {
            ReadinessRing(readiness: camera.readiness.staged, ready: ready, animated: !reduceMotion)
                .frame(width: 100, height: 100)
            Circle().strokeBorder(.white, lineWidth: 4).frame(width: 76, height: 76)
            Circle().fill(ready ? StatusStyle.pass : .white).frame(width: 62, height: 62)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: ready)
            if let countdown {
                Text("\(countdown)")
                    .font(.system(size: 34, weight: .bold, design: .rounded)).monospacedDigit()
                    .foregroundStyle(.black)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(reduceMotion ? nil : .snappy, value: countdown)
                    .accessibilityIdentifier("countdown")
            } else if camera.isCapturing {
                Image(systemName: "checkmark").font(.title.weight(.bold)).foregroundStyle(.black)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: camera.isCapturing)
    }

    private var overlayControls: some View {
        VStack(spacing: 0) {
            // Controls first, on one line and one height; the message sits below them, large enough to read at arm's length.
            HStack(spacing: 10) {
                Spacer()
                Button { showRingHelp = true } label: {
                    Image(systemName: "questionmark").font(.subheadline.weight(.semibold)).frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered).buttonBorderShape(.circle)
                .accessibilityLabel("Instructions")
                .accessibilityIdentifier("ringHelp")
                Toggle(isOn: $autoCapture) {
                    Label("Auto", systemImage: autoCapture ? "timer" : "timer.slash")
                        .font(.subheadline.weight(.semibold)).frame(height: 36)
                }
                .toggleStyle(.button)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .accessibilityLabel("Automatic capture when ready")
                .accessibilityIdentifier("autoCapture")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            Label(countdown != nil ? LocalizedStringResource("Look at the lens") : CameraPresentation.text(for: camera.hint),
                  systemImage: countdown != nil ? "eye" : CameraPresentation.symbol(for: camera.hint))
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18).padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .accessibilityIdentifier("cameraHint")
            if let advisory = camera.advisory, camera.hint == .holdStill || camera.hint == .ready {
                Label(CameraPresentation.text(for: advisory), systemImage: CameraPresentation.symbol(for: advisory))
                    .font(.footnote)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 6)
                    .accessibilityIdentifier("cameraTip")
            }

            if camera.state == .interrupted {
                Text("Camera paused. It resumes when the interruption ends.")
                    .font(.footnote).padding(8).background(.regularMaterial, in: Capsule())
            }
            if developerMode {
                if let startup = camera.startupMilliseconds {
                    Text("start \(startup) ms" + (camera.lastCaptureMilliseconds.map { " · last capture \($0) ms" } ?? ""))
                        .font(.caption2.monospacedDigit()).padding(6).background(.regularMaterial, in: Capsule())
                        .accessibilityHidden(true)
                }
                Text(debugLine)
                    .font(.caption2.monospacedDigit()).padding(6).background(.regularMaterial, in: Capsule())
                    .accessibilityHidden(true)
            }
            Spacer()
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("cameraCancel")
                Spacer()
                Button(action: takePhoto) { shutter }
                .disabled(camera.state != .running || camera.isCapturing)
                .accessibilityLabel("Take Photo")
                .accessibilityValue(Text(CameraPresentation.readinessSummary(camera.readiness.staged)))
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

    /// Raw numbers behind the hints, so a device screenshot can validate signs and thresholds (developer mode).
    private var debugLine: String {
        var parts: [String] = []
        if let level = camera.deviceLevel {
            parts.append(String(format: "roll %.1f° tilt %.1f°", level.rollDegrees, level.pitchDegrees))
        }
        if let slow = camera.lastSlowFrame {
            if let pitch = slow.pitchDegrees { parts.append(String(format: "pitch %+.1f°", pitch)) }
            if let distance = slow.distanceCM { parts.append(String(format: "%.0f cm", distance)) }
            if let light = slow.lighting {
                parts.append(String(format: "L/R %.2f bg %.2f face %.2f", light.leftRightRatio, light.backgroundRatio, light.faceMean))
            }
            parts.append("\(slow.processingMilliseconds) ms")
        } else {
            parts.append("no live analysis")
        }
        return parts.joined(separator: " · ")
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
        case .tooClose: "Too close: move back, or ask someone to take it"
        case .centerFace: "Centre your face in the oval"
        case .levelPhone: "Level the phone to match your head"
        case .uprightPhone: "Straighten the phone; it is leaning"
        case .keepLevel: "Keep your head level"
        case .faceCamera: "Look straight at the camera"
        case .eyeLevel: "Hold the phone at eye level"
        case .backlit: "Move away from the bright light behind you"
        case .moreLight: "Find more light on your face"
        case .turnLeft: "Tip: turn slightly to your left, towards the light"
        case .turnRight: "Tip: turn slightly to your right, towards the light"
        case .holdStill: "Hold still"
        case .ready: "Ready. Take the photo."
        }
    }

    static func symbol(for group: ReadinessGroup) -> String {
        switch group {
        case .framing: "person.crop.rectangle"
        case .pose: "face.dashed"
        case .light: "sun.max"
        case .distance: "ruler"
        }
    }

    /// One sentence for VoiceOver: "Framing OK, head position needs attention, lighting unknown, distance OK".
    static func readinessSummary(_ readiness: CaptureReadiness) -> String {
        ReadinessGroup.allCases.map { group in
            let state: String = switch readiness[group] {
            case .ok: String(localized: "OK")
            case .attention: String(localized: "needs attention")
            case .unknown: String(localized: "not measured")
            }
            return "\(String(localized: name(for: group))) \(state)"
        }.joined(separator: ", ")
    }

    static func name(for group: ReadinessGroup) -> LocalizedStringResource {
        switch group {
        case .framing: "Framing"
        case .pose: "Head position"
        case .light: "Lighting"
        case .distance: "Distance"
        }
    }

    static func explanation(for group: ReadinessGroup) -> LocalizedStringResource {
        switch group {
        case .framing: "One face, big enough and centred in the oval."
        case .pose: "Straight, level and looking at the camera. If the phone is tilted, you move the phone."
        case .light: "Bright enough, not lit from behind."
        case .distance: "About an arm's length. Too close distorts the nose."
        }
    }

    static func symbol(for hint: CaptureHint) -> String {
        switch hint {
        case .ready: "checkmark.circle"
        case .holdStill: "hand.raised"
        case .noFace, .multipleFaces: "person.crop.circle.badge.questionmark"
        case .moveCloser, .moveBack, .tooClose: "arrow.up.left.and.arrow.down.right"
        case .centerFace: "scope"
        case .levelPhone, .uprightPhone: "iphone"
        case .keepLevel: "level"
        case .faceCamera: "face.dashed"
        case .eyeLevel: "arrow.up.and.down"
        case .backlit, .moreLight: "sun.max"
        case .turnLeft: "arrow.turn.up.left"
        case .turnRight: "arrow.turn.up.right"
        }
    }
}


/// Instructions before the camera: page one is the ring, page two is Auto with its own switch. Shown full screen
/// on every launch until "Don't show this again"; the "?" button on the camera presents the same view as a sheet.
struct CameraIntroView: View {
    @Binding var autoCapture: Bool
    @Binding var dismissed: Bool
    /// Present on the full-screen launch variant (goes back to Home); nil when presented from "?".
    var cancel: (() -> Void)?
    let done: () -> Void
    @State private var page = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ringPage.tag(0)
                    autoPage.tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                VStack(spacing: 12) {
                    Toggle("Don't show this again", isOn: $dismissed)
                        .accessibilityIdentifier("introDismiss")
                    Button {
                        if page == 0 { withAnimation { page = 1 } } else { done() }
                    } label: {
                        Text(page == 0 ? LocalizedStringKey("Next") : cancel == nil ? LocalizedStringKey("Done") : LocalizedStringKey("Open the camera"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier(page == 0 ? "introNext" : "introStart")
                }
                .padding()
            }
            .navigationTitle(page == 0 ? Text("Before you start") : Text("Automatic capture"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let cancel {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel).accessibilityIdentifier("introCancel") }
                } else {
                    ToolbarItem(placement: .confirmationAction) { Button("Done", action: done).accessibilityIdentifier("introDone") }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    /// The ring, its colours, and the four checks. Sized to fit one screen without scrolling.
    private var ringPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 18) {
                ReadinessRing(readiness: CaptureReadiness(framing: .ok, pose: .unknown, light: .unknown, distance: .attention), ready: false, animated: false)
                    .frame(width: 84, height: 84)
                    .padding(14)
                    .accessibilityHidden(true)
                Text("The ring around the shutter checks four things, one after another. The message at the top tells you what to do.")
                    .font(.subheadline)
            }
            HStack(spacing: 14) {
                legend(.white.opacity(0.35), "Not yet")
                legend(StatusStyle.warn, "Needs attention")
                legend(StatusStyle.pass, "Fine")
                legend(StatusStyle.pass, "All four: ready", closed: true)
            }
            .font(.caption)
            .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(ReadinessGroup.allCases, id: \.self) { group in
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(CameraPresentation.name(for: group)).font(.subheadline.weight(.semibold))
                            Text(CameraPresentation.explanation(for: group)).font(.footnote).foregroundStyle(.secondary)
                        }
                    } icon: { Image(systemName: CameraPresentation.symbol(for: group)).frame(width: 24) }
                }
            }
            .padding(14)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 14))
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    /// Auto explained, with the switch right here so the decision is made before the camera opens.
    private var autoPage: some View {
        VStack(spacing: 22) {
            Image(systemName: "timer")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 12)
                .accessibilityHidden(true)
            Text("When the ring closes, a 3-second countdown runs and the photo is taken for you. Look at the lens during the countdown.")
                .multilineTextAlignment(.center)
            Text("Off, you press the shutter yourself when the ring is green.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Toggle(isOn: $autoCapture) {
                Label("Automatic capture", systemImage: "timer")
            }
            .padding()
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 14))
            .accessibilityIdentifier("introAutoToggle")
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
    }

    private func legend(_ color: Color, _ text: LocalizedStringResource, closed: Bool = false) -> some View {
        VStack(spacing: 6) {
            if closed {
                Circle().strokeBorder(color, lineWidth: 4).frame(width: 24, height: 24)
            } else {
                Circle().trim(from: 0.55, to: 0.95).stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round)).frame(width: 24, height: 24)
            }
            Text(text).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Four arcs around the shutter, one per readiness group, each with its icon; closes into a full green ring when ready.
struct ReadinessRing: View {
    let readiness: CaptureReadiness
    let ready: Bool
    var animated = true

    var body: some View {
        let groups = ReadinessGroup.allCases
        let gap = ready ? 0.0 : 0.035
        let span = 1.0 / Double(groups.count)
        ZStack {
            ForEach(Array(groups.enumerated()), id: \.element) { index, group in
                Circle()
                    .trim(from: Double(index) * span + gap / 2, to: Double(index + 1) * span - gap / 2)
                    .stroke(color(for: ready ? .ok : readiness[group]), style: StrokeStyle(lineWidth: 5, lineCap: gap == 0 ? .butt : .round))
                    .rotationEffect(.degrees(-90))
                // Icon just outside the arc's midpoint, so the ring explains itself.
                GeometryReader { geometry in
                    let radius = min(geometry.size.width, geometry.size.height) / 2 + 12
                    let angle = (Double(index) + 0.5) * span * 2 * .pi - .pi / 2
                    Image(systemName: CameraPresentation.symbol(for: group))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(color(for: ready ? .ok : readiness[group]))
                        .symbolEffect(.bounce, options: .nonRepeating, value: readiness[group] == .ok)
                        .shadow(color: .black.opacity(0.6), radius: 2)
                        .position(x: geometry.size.width / 2 + cos(angle) * radius, y: geometry.size.height / 2 + sin(angle) * radius)
                }
            }
        }
        .animation(animated ? .easeInOut(duration: 0.3) : nil, value: readiness)
        .animation(animated ? .spring(duration: 0.45, bounce: 0.2) : nil, value: ready)
        .accessibilityHidden(true)
    }

    private func color(for state: CaptureReadiness.State) -> Color {
        switch state {
        case .ok: StatusStyle.pass
        case .attention: StatusStyle.warn
        case .unknown: .white.opacity(0.28)
        }
    }
}
