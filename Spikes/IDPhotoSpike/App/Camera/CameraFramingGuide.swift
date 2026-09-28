import SwiftUI

/// One quiet target over the head. Only framing and distance errors put a cue on the oval; pose and light
/// remain verbal instructions so the guide never implies that the wrong part of the photo is at fault.
struct CameraFramingGuide: View {
    let ready: Bool
    let correction: GuideCorrection?
    let isCapturing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var didSettle = false
    @State private var settleScale: CGFloat = 1
    @State private var settleGlow = false

    struct Layout: Equatable {
        static let eyeLineFraction: CGFloat = 0.44
        let oval: CGRect

        init(in size: CGSize) {
            // The face detector excludes some hair and headwear. Give the visible head more room than its box.
            let height = max(0, min(size.height * 0.40, size.width * 0.85))
            let width = height * 0.78
            let eyeLine = size.height * Self.eyeLineFraction
            oval = CGRect(x: (size.width - width) / 2, y: eyeLine - height / 2,
                          width: width, height: height)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let oval = Layout(in: geometry.size).oval
            ZStack {
                Ellipse()
                    .strokeBorder(.white.opacity(contrast == .increased ? 1 : ready ? 0.96 : 0.82),
                                  lineWidth: Design.Stroke.guide(for: contrast))
                    .shadow(color: .black.opacity(0.48), radius: 4)
                    .shadow(color: .white.opacity(settleGlow ? 0.62 : 0), radius: 11)
                    .frame(width: oval.width, height: oval.height)
                    .scaleEffect(settleScale)
                    .position(x: oval.midX, y: oval.midY)
                if let correction {
                    Image(systemName: correction.symbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.9), radius: 4)
                        .position(correction.point(on: oval))
                        .environment(\.layoutDirection, .leftToRight)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: correction)
            .animation(Design.Motion.guideState.resolved(reduceMotion: reduceMotion), value: ready)
        }
        .opacity(isCapturing ? 0 : 1)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isCapturing)
        .task(id: ready) {
            guard ready else {
                settleScale = 1
                settleGlow = false
                return
            }
            guard !didSettle else { return }
            didSettle = true
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                settleScale = 1.025
                settleGlow = true
            }
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.36)) {
                settleScale = 1
                settleGlow = false
            }
        }
        .onChange(of: reduceMotion) { _, enabled in
            if enabled {
                settleScale = 1
                settleGlow = false
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private extension GuideCorrection {
    var symbol: String {
        switch self {
        case .left: "arrow.left"
        case .right: "arrow.right"
        case .up: "arrow.up"
        case .down: "arrow.down"
        case .closer: "arrow.up.left.and.arrow.down.right"
        case .farther: "arrow.down.right.and.arrow.up.left"
        }
    }

    func point(on oval: CGRect) -> CGPoint {
        let inset: CGFloat = 19
        return switch self {
        case .left: CGPoint(x: oval.minX - inset, y: oval.midY)
        case .right: CGPoint(x: oval.maxX + inset, y: oval.midY)
        case .up: CGPoint(x: oval.midX, y: oval.minY - inset)
        case .down: CGPoint(x: oval.midX, y: oval.maxY + inset)
        case .closer, .farther: CGPoint(x: oval.maxX + inset, y: oval.maxY - oval.height * 0.13)
        }
    }
}

#if DEBUG
/// Neutral stand-in for the camera feed. It contains no real person's image and exercises the production guide.
struct CameraFramingGuidePreviewScene: View {
    let ready: Bool
    var correction: GuideCorrection? = nil
    var faceOffset: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.53), Color(white: 0.30)], startPoint: .top, endPoint: .bottom)
            GeometryReader { geometry in
                let oval = CameraFramingGuide.Layout(in: geometry.size).oval
                let head = oval.insetBy(dx: oval.width * 0.07, dy: oval.height * 0.04)
                Ellipse().fill(Color(white: 0.19))
                    .frame(width: head.width, height: head.height)
                    .position(x: head.midX + faceOffset, y: head.midY)
                Ellipse().fill(Color(white: 0.19))
                    .frame(width: oval.width * 1.9, height: oval.height * 0.72)
                    .position(x: oval.midX + faceOffset, y: oval.maxY + oval.height * 0.25)
            }
            CameraFramingGuide(ready: ready, correction: correction, isCapturing: false)
        }
        .ignoresSafeArea()
    }
}

#Preview("Framing") { CameraFramingGuidePreviewScene(ready: false, correction: .right, faceOffset: -65) }
#Preview("Ready") { CameraFramingGuidePreviewScene(ready: true) }
#endif
