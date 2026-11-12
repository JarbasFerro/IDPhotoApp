import SwiftUI
import UIKit

/// Capture protection (ADR-049, D-9): content that iOS leaves blank in screenshots and screen recordings.
///
/// iOS has no public API for this. The widely used technique hosts the content inside the internal canvas view of a
/// secure `UITextField`, whose layer the system excludes from captures. It is undocumented and may break in any iOS
/// release, so it lives behind this one small view: if the canvas is not found, the content is shown unprotected and
/// `CaptureProtection.isAvailable` reports false. Never use it to hide anything the person needs to act on.
struct CaptureProtected<Content: View>: UIViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    func makeUIView(context: Context) -> SecureContainerView {
        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        // Touches fall through to the SwiftUI gestures attached around this view (hold to compare).
        host.view.isUserInteractionEnabled = false
        context.coordinator.host = host
        return SecureContainerView(content: host.view)
    }

    func updateUIView(_ uiView: SecureContainerView, context: Context) {
        context.coordinator.host?.rootView = content
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator { var host: UIHostingController<Content>? }
}

final class SecureContainerView: UIView {
    private let field = UITextField()
    /// True when the secure canvas was found and the content is inside it.
    private(set) var isProtected = false

    init(content: UIView) {
        super.init(frame: .zero)
        backgroundColor = .clear
        field.isSecureTextEntry = true
        let canvas = CaptureProtection.secureCanvas(of: field)
        let parent: UIView
        if let canvas {
            canvas.subviews.forEach { $0.removeFromSuperview() }
            canvas.isUserInteractionEnabled = true
            pin(canvas, in: self)
            parent = canvas
            isProtected = true
        } else {
            parent = self
        }
        pin(content, in: parent)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private func pin(_ child: UIView, in parent: UIView) {
        child.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(child)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.topAnchor.constraint(equalTo: parent.topAnchor),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }
}

/// Whether this iOS still exposes the secure canvas the technique depends on; shown in developer details.
@MainActor
enum CaptureProtection {
    static let isAvailable: Bool = {
        let field = UITextField()
        field.isSecureTextEntry = true
        return secureCanvas(of: field) != nil
    }()

    static func secureCanvas(of field: UITextField) -> UIView? {
        field.subviews.first { String(describing: type(of: $0)).contains("CanvasView") }
    }
}
