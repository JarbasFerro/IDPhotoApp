import SwiftUI

/// One composition guide: the Calipic frame when it fits, otherwise the head oval.
///
/// The frame has the photo's proportions and leaves room for the head. The oval is retained as the fallback on
/// narrow or landscape layouts. Neither is the final crop. The guide remains white so a measured camera state
/// does not paint an approval mark across the person's face; the shutter ring and spoken hint carry that state.
struct CameraFramingGuide: View {
    let ready: Bool
    var format: PhotoFormat = .spainPrototype
    var composition: CompositionSpec = .icaoEngineeringDefault
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    /// Where the guide sits in the camera view. Pure geometry, so it can be tested without a camera.
    struct Layout: Equatable {
        /// The eye line's height in the camera view; the oval is centred on it for geometry only.
        static let eyeLineFraction: CGFloat = 0.44

        let oval: CGRect
        /// `nil` when the frame has no room to stand clear of the oval and the controls: landscape, or a view too
        /// narrow for the photo's proportions. The oval is never changed to make room for it.
        let frame: CGRect?

        init(in size: CGSize, format: PhotoFormat = .spainPrototype, composition: CompositionSpec = .icaoEngineeringDefault) {
            // Sized for a comfortable arm's-length framing.
            let ovalHeight = size.height * 0.32
            let ovalWidth = ovalHeight * 0.78
            let eyeLine = size.height * Self.eyeLineFraction
            oval = CGRect(x: size.width / 2 - ovalWidth / 2, y: eyeLine - ovalHeight / 2, width: ovalWidth, height: ovalHeight)
            // The oval stands for the head: the frame is the photo that head height implies, with the oval's centre
            // on the photo's eye line.
            let headHeight = composition.headHeightTarget
            guard size.height > size.width, headHeight > 0, headHeight <= 1, format.aspectRatio > 0 else { frame = nil; return }
            let frameHeight = ovalHeight / headHeight
            let frameWidth = frameHeight * format.aspectRatio
            let candidate = CGRect(x: size.width / 2 - frameWidth / 2, y: eyeLine - frameHeight * composition.eyeLineTarget,
                                   width: frameWidth, height: frameHeight)
            let room = CGRect(origin: .zero, size: size).insetBy(dx: Design.Spacing.group, dy: 0)
            let clearsOval = candidate.insetBy(dx: Design.Stroke.guideHighContrast, dy: Design.Stroke.guideHighContrast).contains(oval)
            frame = room.contains(candidate) && clearsOval ? candidate : nil
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = Layout(in: geometry.size, format: format, composition: composition)
            let lineWidth = Design.Stroke.guide(for: contrast)
            let color = Color.white.opacity(contrast == .increased ? 1 : ready ? 0.9 : 0.75)
            ZStack {
                if let frame = layout.frame {
                    CalipicFrameGuide(color: color)
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                } else {
                    Ellipse()
                        .strokeBorder(color, style: StrokeStyle(lineWidth: lineWidth, dash: [8, 6]))
                        .frame(width: layout.oval.width, height: layout.oval.height)
                        .position(x: layout.oval.midX, y: layout.oval.midY)
                }
            }
            .animation(Design.Motion.guideState.resolved(reduceMotion: reduceMotion), value: ready)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#if DEBUG
/// Stand-in for the live view: a neutral wall and a plain bust, so the guide can be judged without a camera.
struct CameraFramingGuidePreviewScene: View {
    let ready: Bool

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.55), Color(white: 0.32)], startPoint: .top, endPoint: .bottom)
            GeometryReader { geometry in
                let layout = CameraFramingGuide.Layout(in: geometry.size)
                let frame = layout.frame ?? layout.oval
                let head = layout.oval.insetBy(dx: layout.oval.width * 0.06, dy: layout.oval.height * 0.04)
                Ellipse().fill(Color(white: 0.2))
                    .frame(width: head.width, height: head.height).position(x: head.midX, y: head.midY)
                Ellipse().fill(Color(white: 0.2))
                    .frame(width: frame.width * 1.15, height: frame.height * 0.6)
                    .position(x: frame.midX, y: frame.maxY + frame.height * 0.08)
            }
            CameraFramingGuide(ready: ready)
        }
        .ignoresSafeArea()
    }
}

#Preview("Framing") { CameraFramingGuidePreviewScene(ready: false) }
#Preview("Ready") { CameraFramingGuidePreviewScene(ready: true) }
#endif
