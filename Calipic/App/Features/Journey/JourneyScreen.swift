import SwiftUI

/// One edge-to-edge mat and one content-sized tray. Only the tray's content scrolls; its actions stay put.
struct JourneyScreen<Stage: View, Tray: View, Actions: View>: View {
    /// Reserve the photo's minimum on standard text sizes; the tray scrolls when its words need more room.
    var minimumObjectHeightFraction: CGFloat = 0
    var stageBottomReserve: CGFloat = 0
    /// Print reserves one tray footprint so the page keeps its position through layout, unlock and sending.
    var reservedTrayFraction: CGFloat? = nil
    @ViewBuilder let stage: (CGSize) -> Stage
    @ViewBuilder let tray: () -> Tray
    @ViewBuilder let actions: () -> Actions
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var scheme
    @State private var contentHeight: CGFloat = 0
    @State private var actionsHeight: CGFloat = 0

    var body: some View {
        GeometryReader { screen in
            let fraction = dynamicTypeSize.isAccessibilitySize ? 0.75 : (reservedTrayFraction ?? 0.55)
            let trayOverhead = actionsHeight + 22 + 8 + Design.Spacing.group
            let screenHeight = screen.size.height + screen.safeAreaInsets.top + screen.safeAreaInsets.bottom
            let minimumStage = dynamicTypeSize.isAccessibilitySize ? 0 :
                screenHeight * minimumObjectHeightFraction + (minimumObjectHeightFraction > 0 ? 2 * Design.Spacing.stageMargin + stageBottomReserve : 0)
            let limit = max(0, min(screen.size.height * fraction, screen.size.height - minimumStage) - trayOverhead)
            VStack(spacing: 0) {
                GeometryReader { area in
                    let margin = Design.Spacing.stageMargin
                    stage(CGSize(width: max(0, area.size.width - 2 * margin),
                                 height: max(0, area.size.height - 2 * margin)))
                        .frame(width: area.size.width, height: area.size.height)
                }
                VStack(alignment: .leading, spacing: Design.Spacing.group) {
                    ViewThatFits(in: .vertical) {
                        trayContent
                        ScrollView { trayContent }
                            .scrollBounceBehavior(.basedOnSize)
                            .scrollIndicatorsFlash(onAppear: true)
                    }
                    .frame(height: reservedTrayFraction == nil ? min(contentHeight, limit) : limit, alignment: .top)
                    actions()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { actionsHeight = $0 }
                        .guideAvoid()
                }
                .frame(height: reservedTrayFraction == nil ? nil : max(0, screen.size.height * fraction - 30), alignment: .top)
                .padding(.horizontal, Design.Spacing.tray)
                .padding(.top, 22)
                .padding(.bottom, 8)
                .background {
                    UnevenRoundedRectangle(topLeadingRadius: Design.Radius.tray, topTrailingRadius: Design.Radius.tray)
                        .fill(Design.Surface.tray)
                        .shadow(color: .black.opacity(scheme == .dark ? 0.6 : 0.12), radius: 16, y: -4)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
        }
        .background { MatSurface().ignoresSafeArea() }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var trayContent: some View {
        tray()
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
    }
}

#if DEBUG
/// Exercises the shared tray's height cap without depending on photo analysis or a particular document.
struct JourneyTrayFixture: View {
    var body: some View {
        NavigationStack {
            JourneyScreen { size in
                Image(systemName: "photo")
                    .resizable().scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .accessibilityIdentifier("journeyStageFixture")
            } tray: {
                VStack(alignment: .leading, spacing: 20) {
                    Text(verbatim: "Tray height check").font(Design.Typography.trayTitle)
                    TrayRows(leadingInset: 0) {
                        ForEach(0..<30) { row in
                            TrayRow(title: Text(verbatim: "Row \(row)"))
                                .accessibilityIdentifier("fixtureRow-\(row)")
                        }
                    }
                }
            } actions: {
                TrayActions {
                    Button {} label: { Text(verbatim: "Continue").frame(maxWidth: .infinity) }
                        .accessibilityIdentifier("fixtureAction")
                }
            }
        }
    }
}
#endif
