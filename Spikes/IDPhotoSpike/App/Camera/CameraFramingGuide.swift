import SwiftUI

/// One quiet head target. A short arrow grows from its edge when a phone movement is useful.
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
            // A target for the head, with room for hair. It must not dominate the visible preview.
            let height = max(0, min(size.height * 0.34, size.width * 0.82))
            let width = height * 0.74
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
                    .strokeBorder(ready ? Color.green : Color.white.opacity(contrast == .increased ? 1 : 0.9),
                                  lineWidth: Design.Stroke.guide(for: contrast))
                    .shadow(color: .black.opacity(0.48), radius: 4)
                    .shadow(color: .green.opacity(settleGlow ? 0.62 : 0), radius: 11)
                    .frame(width: oval.width, height: oval.height)
                    .scaleEffect(settleScale)
                    .position(x: oval.midX, y: oval.midY)
                if let correction {
                    GuideArrow(correction: correction, oval: oval)
                        .stroke(.white, style: StrokeStyle(lineWidth: contrast == .increased ? 4 : 3,
                                                           lineCap: .round, lineJoin: .round))
                        .shadow(color: .black.opacity(0.8), radius: 4)
                        .transition(.opacity)
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

/// The stem starts on the oval, so its arrowhead reads as movement of the phone rather than of the face.
private struct GuideArrow: Shape {
    let correction: GuideCorrection
    let oval: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        func arrow(from start: CGPoint, to end: CGPoint) {
            path.move(to: start)
            path.addLine(to: end)
            arrowHead(at: end, angle: atan2(end.y - start.y, end.x - start.x))
        }
        func arrowHead(at end: CGPoint, angle: CGFloat) {
            let wing: CGFloat = 8
            for offset in [-CGFloat.pi / 4, CGFloat.pi / 4] {
                path.move(to: CGPoint(x: end.x - wing * cos(angle + offset),
                                      y: end.y - wing * sin(angle + offset)))
                path.addLine(to: end)
            }
        }
        func tiltArrow(up: Bool) {
            let sign: CGFloat = up ? -1 : 1
            let start = CGPoint(x: oval.midX + oval.width * 0.19,
                                y: oval.midY + sign * oval.height * 0.46)
            let control = CGPoint(x: start.x + 31, y: start.y + sign * 30)
            let end = CGPoint(x: start.x + 14, y: start.y + sign * 40)
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
            arrowHead(at: end, angle: atan2(end.y - control.y, end.x - control.x))
        }
        let reach: CGFloat = 30
        switch correction {
        case .left:
            arrow(from: CGPoint(x: oval.minX, y: oval.midY), to: CGPoint(x: oval.minX - reach, y: oval.midY))
        case .right:
            arrow(from: CGPoint(x: oval.maxX, y: oval.midY), to: CGPoint(x: oval.maxX + reach, y: oval.midY))
        case .raise:
            arrow(from: CGPoint(x: oval.midX, y: oval.minY), to: CGPoint(x: oval.midX, y: oval.minY - reach))
        case .lower:
            arrow(from: CGPoint(x: oval.midX, y: oval.maxY), to: CGPoint(x: oval.midX, y: oval.maxY + reach))
        case .tiltUp: tiltArrow(up: true)
        case .tiltDown: tiltArrow(up: false)
        case .closer:
            // The portrait grows as the phone comes closer.
            arrow(from: CGPoint(x: oval.minX, y: oval.midY), to: CGPoint(x: oval.minX - reach, y: oval.midY))
            arrow(from: CGPoint(x: oval.maxX, y: oval.midY), to: CGPoint(x: oval.maxX + reach, y: oval.midY))
        case .farther:
            // The portrait shrinks as the phone moves farther away.
            arrow(from: CGPoint(x: oval.minX - reach, y: oval.midY), to: CGPoint(x: oval.minX, y: oval.midY))
            arrow(from: CGPoint(x: oval.maxX + reach, y: oval.midY), to: CGPoint(x: oval.maxX, y: oval.midY))
        }
        return path
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

#Preview("Framing") { CameraFramingGuidePreviewScene(ready: false, correction: .left, faceOffset: -65) }
#Preview("Ready") { CameraFramingGuidePreviewScene(ready: true) }
#endif
