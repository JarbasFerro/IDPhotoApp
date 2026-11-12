import SwiftUI

/// After the print is confirmed to be the right size: the person's own page with the cuts drawn in order,
/// three cutting tips and Done. Pushed inside a NavigationStack owned by the presenter.
struct FinishedView: View {
    let model: PhotoWorkflow
    let onDone: () -> Void

    @State private var appeared = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: PhotoWorkflow, onDone: @escaping () -> Void) {
        self.model = model
        self.onDone = onDone
    }

    var body: some View {
        let layout = model.layout
        ScrollView {
            VStack(spacing: Design.Spacing.sectionTight) {
                header
                if let page = layout.pages.first {
                    pageDrawing(page, layout: layout)
                }
                tips
                if dynamicTypeSize.isAccessibilitySize { doneButton }
            }
            .padding(.horizontal)
            .padding(.vertical, Design.Spacing.text)
        }
        .background(Design.Surface.screen)
        .safeAreaInset(edge: .bottom) {
            if !dynamicTypeSize.isAccessibilitySize {
                doneButton
                    .padding(.horizontal)
                    .padding(.top, Design.Spacing.text)
                    .padding(.bottom, Design.Spacing.caption)
                    .background(Design.Surface.screen)
            }
        }
        .navigationTitle("Finished")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear { appeared = true }
    }

    private var header: some View {
        VStack(spacing: Design.Spacing.control) {
            if reduceMotion {
                checkmark
            } else {
                checkmark.symbolEffect(.bounce, value: appeared)
            }
            Text("Your photos are the right size")
                .font(Design.Typography.hero)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("finishedScreen")
            Text("Cut them out and they are ready to use.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var checkmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 56))
            .foregroundStyle(StatusStyle.pass)
            .accessibilityHidden(true)
    }

    private func pageDrawing(_ page: PrintPage, layout: PrintLayout) -> some View {
        let plan = CutPlan(page: page)
        // Fit the page in a 300 × 280 pt box so a landscape page never runs off a narrow screen.
        let aspect = page.widthMM / page.heightMM
        let width = min(300, 280 * aspect)
        let height = width / aspect
        let samePlans = layout.pages.dropFirst().allSatisfy { CutPlan(page: $0).cuts.count == plan.cuts.count }
        return VStack(spacing: Design.Spacing.control) {
            ZStack {
                SheetPageView(page: page, thumbnails: model.sheetThumbnails, animated: false)
                    .frame(width: width, height: height)
                    .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
                CutOverlay(plan: plan, page: page)
                    .frame(width: width + 2 * CutOverlay.margin, height: height + 2 * CutOverlay.margin)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page with \(plan.cuts.count) cuts, in order")
            if layout.pages.count > 1 {
                Text(samePlans ? "Every page is cut the same way." : "Page 1 shown.")
                    .font(Design.Typography.note)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var tips: some View {
        VStack(spacing: 0) {
            tip(1, title: Text("Cut the rows apart first"),
                detail: Text("Follow the marks at the corners, not the edge of the photo"))
            Divider().padding(.leading, 56)
            tip(2, title: Text("Then cut each photo out"),
                detail: Text("A paper trimmer gives the straightest edges; scissors work too"))
            Divider().padding(.leading, 56)
            tip(3, title: Text("Keep the spare copies flat"), detail: Text("In an envelope, away from light"))
        }
        .background(Design.Surface.card, in: RoundedRectangle(cornerRadius: Design.Radius.group))
    }

    private func tip(_ number: Int, title: Text, detail: Text) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Design.Spacing.control) {
            Text(verbatim: "\(number)")
                .font(.subheadline.weight(.bold)).monospacedDigit()
                .foregroundStyle(Color.brandAccent)
                .frame(width: 28, height: 28)
                .background(Color.brandAccent.opacity(0.14), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Design.Spacing.titlePair) {
                title
                detail.font(Design.Typography.note).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal).padding(.vertical, Design.Spacing.control)
        .accessibilityElement(children: .combine)
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text("Done").frame(maxWidth: .infinity)
        }
        .brandProminentButtonStyle()
        .controlSize(.large)
        .accessibilityIdentifier("finishedDone")
    }
}

/// The cut lines over the page, with a halo so they read over photos. The step badges sit outside the page and use
/// the numbers of the tips below: 1 where the row cuts start, 2 where the photo cuts start. Trims are dashed.
private struct CutOverlay: View {
    let plan: CutPlan
    let page: PrintPage
    /// Room around the page for the badges.
    static let margin: CGFloat = 16

    var body: some View {
        Canvas { context, size in
            let inset = Self.margin
            let scale = min((size.width - 2 * inset) / page.widthMM, (size.height - 2 * inset) / page.heightMM)
            func point(_ p: MillimeterPoint) -> CGPoint { CGPoint(x: inset + p.x * scale, y: inset + p.y * scale) }
            for cut in plan.cuts {
                var path = Path()
                path.move(to: point(cut.from))
                path.addLine(to: point(cut.to))
                let dash: [CGFloat] = cut.stage == .trims ? [4, 3] : []
                context.stroke(path, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, dash: dash))
                context.stroke(path, with: .color(.brandAccent), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: dash))
            }
            func badge(_ number: Int, at centre: CGPoint) {
                let rect = CGRect(x: centre.x - 9, y: centre.y - 9, width: 18, height: 18)
                context.fill(Path(ellipseIn: rect), with: .color(.brandAccent))
                context.draw(Text(verbatim: "\(number)").font(.caption2.weight(.bold)).foregroundStyle(.white), at: centre)
            }
            if let rows = plan.firstCut(of: .rows) { badge(1, at: CGPoint(x: inset / 2, y: point(rows.from).y)) }
            if let columns = plan.firstCut(of: .columns) { badge(2, at: CGPoint(x: point(columns.from).x, y: inset / 2)) }
        }
        .allowsHitTesting(false)
    }
}
