import SwiftUI

/// One prominent action and at most one plain alternative. Labels expand inside their native Buttons.
struct TrayActions<Primary: View, Alternative: View>: View {
    let primary: Primary
    let alternative: Alternative
    private let isPeer: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(@ViewBuilder primary: () -> Primary, @ViewBuilder peer: () -> Alternative) {
        self.primary = primary(); alternative = peer(); isPeer = true
    }

    init(@ViewBuilder primary: () -> Primary, @ViewBuilder secondary: () -> Alternative) {
        self.primary = primary(); alternative = secondary(); isPeer = false
    }

    var body: some View {
        if isPeer && !dynamicTypeSize.isAccessibilitySize {
            GeometryReader { geometry in
                HStack(spacing: 8) {
                    textAction.frame(width: max(0, geometry.size.width - 8) / 3)
                    primaryAction
                }
            }
            .frame(height: 50)
        } else {
            VStack(spacing: 0) {
                primaryAction
                if Alternative.self != EmptyView.self { textAction }
            }
        }
    }

    private var primaryAction: some View {
        primary.brandProminentButtonStyle().controlSize(.large).frame(maxWidth: .infinity)
    }

    private var textAction: some View {
        alternative.buttonStyle(.plain).foregroundStyle(Color.brandAccent)
            .frame(maxWidth: .infinity, minHeight: Design.Size.minimumTarget)
    }
}

extension TrayActions where Alternative == EmptyView {
    init(@ViewBuilder primary: () -> Primary) {
        self.init(primary: primary, secondary: { EmptyView() })
    }
}
