import SwiftUI

/// A single face guide inspired by the calm focus of Face ID setup. It is a composition aid, never a
/// compliance mark or a promise that the final crop will be accepted.
struct CameraFramingGuide: View {
    let ready: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    struct Layout: Equatable {
        static let eyeLineFraction: CGFloat = 0.44
        let oval: CGRect

        init(in size: CGSize) {
            // Keep the guide at a comfortable arm's-length size, including on narrow devices.
            let height = max(0, min(size.height * 0.32, size.width * 0.68))
            let width = height * 0.78
            let eyeLine = size.height * Self.eyeLineFraction
            oval = CGRect(x: (size.width - width) / 2, y: eyeLine - height / 2,
                          width: width, height: height)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let oval = Layout(in: geometry.size).oval
            Ellipse()
                .strokeBorder(.white.opacity(contrast == .increased ? 1 : ready ? 0.94 : 0.76),
                              lineWidth: Design.Stroke.guide(for: contrast))
                .shadow(color: .black.opacity(0.38), radius: 4)
                .frame(width: oval.width, height: oval.height)
                .position(x: oval.midX, y: oval.midY)
                .animation(Design.Motion.guideState.resolved(reduceMotion: reduceMotion), value: ready)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#if DEBUG
/// Neutral stand-in for the camera feed. It contains no real person's image and exercises the production guide.
struct CameraFramingGuidePreviewScene: View {
    let ready: Bool

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.53), Color(white: 0.30)], startPoint: .top, endPoint: .bottom)
            GeometryReader { geometry in
                let oval = CameraFramingGuide.Layout(in: geometry.size).oval
                let head = oval.insetBy(dx: oval.width * 0.07, dy: oval.height * 0.04)
                Ellipse().fill(Color(white: 0.19))
                    .frame(width: head.width, height: head.height).position(x: head.midX, y: head.midY)
                Ellipse().fill(Color(white: 0.19))
                    .frame(width: oval.width * 1.9, height: oval.height * 0.72)
                    .position(x: oval.midX, y: oval.maxY + oval.height * 0.25)
            }
            CameraFramingGuide(ready: ready)
        }
        .ignoresSafeArea()
    }
}

#Preview("Framing") { CameraFramingGuidePreviewScene(ready: false) }
#Preview("Ready") { CameraFramingGuidePreviewScene(ready: true) }
#endif
