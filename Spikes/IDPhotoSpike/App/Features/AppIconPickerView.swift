import SwiftUI

/// Choose-your-icon (BD-038): the same C-frame with a different character inside. Opened from Home only; it never
/// appears between capture, check and print.
struct AppIconPickerView: View {
    let controller: AppIconController
    @Environment(\.dismiss) private var dismiss
    /// The previews grow with Dynamic Type; the adaptive grid then simply fits fewer columns.
    @ScaledMetric(relativeTo: .body) private var iconSide: CGFloat = Design.Size.pickerIcon

    var body: some View {
        @Bindable var controller = controller
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Spacing.section) {
                    ForEach(AppIconChoice.Group.allCases, id: \.self) { group in
                        VStack(alignment: .leading, spacing: Design.Spacing.cardContent) {
                            Text(group.title)
                                .font(Design.Typography.cardTitle)
                                .accessibilityAddTraits(.isHeader)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: side, maximum: side + 8), spacing: Design.Spacing.group, alignment: .top)],
                                      alignment: .leading, spacing: Design.Spacing.group) {
                                ForEach(AppIconChoice.choices(in: group)) { choice in
                                    cell(choice)
                                }
                            }
                        }
                    }
                    Text("Changes the Calipic icon on your Home Screen.")
                        .font(Design.Typography.note)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("We couldn't change the icon.", isPresented: $controller.changeFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Try again in a moment.")
            }
            .onAppear { controller.refresh() }
        }
    }

    /// About 76 pt at the default text size (cells stretch by at most 8 pt), larger with accessibility sizes.
    /// Capped at 120 pt so that two columns still fit the narrowest iPhone (2 × 128 + 16 < 288 pt).
    private var side: CGFloat { min(max(iconSide, 72), 120) }

    private func cell(_ choice: AppIconChoice) -> some View {
        let isSelected = choice == controller.current
        return Button {
            Task { await controller.select(choice) }
        } label: {
            VStack(spacing: Design.Spacing.caption) {
                Image(choice.previewAssetName)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(alignment: .bottomTrailing) { selectionBadge(isSelected) }
                // Two lines keep longer names ("Fones de ouvido") whole; cells are top-aligned in the grid.
                Text(choice.label)
                    .font(Design.Typography.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(controller.isChanging)
        .accessibilityLabel(Text(choice.label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("appIcon-\(choice.name)")
    }

    @ViewBuilder
    private func selectionBadge(_ isSelected: Bool) -> some View {
        if isSelected {
            // Shape and position carry the state; the colour only matches the brand.
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(6)
                .background(Color.brandAccentFill, in: Circle())
                .overlay(Circle().strokeBorder(Color(.systemBackground), lineWidth: Design.Stroke.separation))
                .offset(x: 6, y: 6)
                .accessibilityHidden(true)
        }
    }
}
