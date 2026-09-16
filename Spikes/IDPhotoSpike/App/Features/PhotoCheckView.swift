import SwiftUI

/// Step 2: the framed portrait, one headline, a few plain rows, and one primary action.
struct PhotoCheckView: View {
    @Bindable var model: PhotoWorkflow
    let photoID: UUID
    @Binding var path: [Route]
    let acquire: Acquire
    @State private var showAdjust = false
    @State private var confirmRemove = false
    @State private var comparing = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var entry: PhotoEntry? { model.entries.first { $0.id == photoID } }
    private var position: (Int, Int)? {
        guard let index = model.entries.firstIndex(where: { $0.id == photoID }) else { return nil }
        return (index + 1, model.entries.count)
    }

    var body: some View {
        ScrollView {
            if let entry {
                VStack(alignment: .leading, spacing: 24) {
                    portrait(entry)
                    summaryBlock(entry)
                    actions
                }
                .padding()
            } else {
                ContentUnavailableView("This photo was removed", systemImage: "photo")
            }
        }
        .navigationTitle(position.map { $0.1 > 1 ? String(localized: "Photo \($0.0) of \($0.1)") : String(localized: "Your photo") } ?? String(localized: "Your photo"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Remove Photo", systemImage: "trash", role: .destructive) { confirmRemove = true }
                    .disabled(model.activity != nil)
            }
        }
        .confirmationDialog("Remove this photo and its copies on the sheet?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Remove Photo", role: .destructive) {
                model.selectedID = photoID
                model.removePhoto()
                path.removeAll()
            }
        } message: { Text("The original in your photo library is kept.") }
        .sheet(isPresented: $showAdjust) { AdjustSheet(model: model, photoID: photoID) }
        .onAppear { model.selectedID = photoID; model.showsOriginal = false }
        .accessibilityIdentifier("photoCheck")
    }

    /// The final look. Press and hold to see the original.
    private func portrait(_ entry: PhotoEntry) -> some View {
        VStack(spacing: 8) {
            PortraitView(entry: entry, showsOriginal: comparing, label: comparing ? "Original photo" : "Framed photo")
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? 220 : 300)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                .onLongPressGesture(minimumDuration: 0.15, maximumDistance: 40) {} onPressingChanged: { pressing in comparing = pressing }
                .accessibilityHint("Press and hold to compare with the original.")
                .accessibilityAction(named: Text("Compare with original")) { comparing.toggle() }
                .accessibilityIdentifier("portrait")
            Text(comparing ? "Original" : "Hold to compare with the original")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func summaryBlock(_ entry: PhotoEntry) -> some View {
        let whiteApplied: Bool = { if case .color = entry.adjustment.background { return true } else { return false } }()
        let summary = CheckPresentation.summary(for: entry, whiteApplied: whiteApplied, sourceIsSmall: model.sourceIsSmall)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if summary.headline == .checking {
                    ProgressView()
                } else {
                    Image(systemName: CheckPresentation.symbol(for: summary.headline))
                        .font(.title2)
                        .foregroundStyle(headlineTint(summary.headline))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(CheckPresentation.title(for: summary.headline)).font(.title3.weight(.semibold))
                    Text(CheckPresentation.subtitle(for: summary.headline)).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("checkHeadline")
            ForEach(summary.rows) { row in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Image(systemName: AlignmentPresentation.symbol(for: row.state))
                        .foregroundStyle(rowTint(row.state))
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title).font(.subheadline.weight(.medium))
                        Text(row.detail).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .animation(.default, value: summary)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button { path.append(.sheet) } label: {
                Label("Add to sheet", systemImage: "printer").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.activity != nil)
            .accessibilityIdentifier("addToSheet")
            HStack(spacing: 12) {
                Button { showAdjust = true } label: {
                    Label("Adjust", systemImage: "slider.horizontal.3").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("adjust")
                Menu {
                    Button { acquire(.camera, .replace) } label: { Label("Take Photo", systemImage: "camera") }
                    Button { acquire(.library, .replace) } label: { Label("Choose Photo", systemImage: "photo.on.rectangle") }
                } label: {
                    Label("Retake", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("retake")
            }
        }
    }

    private func headlineTint(_ headline: PhotoCheckSummary.Headline) -> Color {
        switch headline {
        case .checking: .secondary
        case .good: .green
        case .review: .orange
        case .retake: .red
        }
    }

    private func rowTint(_ state: CheckState) -> Color {
        switch state {
        case .pass: .green
        case .warn: .orange
        case .fail: .red
        case .manualCheck: .secondary
        }
    }
}

/// Non-interactive rendering of an entry's crop with its background and tone, or the untouched original.
struct PortraitView: View {
    let entry: PhotoEntry
    var showsOriginal = false
    /// Without a label the portrait is decorative and hidden from assistive technologies.
    var label: LocalizedStringResource? = nil

    var body: some View {
        GeometryReader { geometry in
            let adjustment = showsOriginal ? CropAdjustment() : entry.adjustment
            let crop = adjustment.crop(in: entry.photo.pixels)
            Image(decorative: showsOriginal ? entry.photo.preview : (entry.backgroundPreview ?? entry.photo.preview), scale: 1)
                .resizable()
                .frame(width: geometry.size.width / crop.width, height: geometry.size.height / crop.height)
                .rotationEffect(.degrees(-adjustment.clamped().rotationDegrees),
                                anchor: UnitPoint(x: crop.x + crop.width / 2, y: crop.y + crop.height / 2))
                .offset(x: -crop.x / crop.width * geometry.size.width, y: -crop.y / crop.height * geometry.size.height)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped()
        }
        .aspectRatio(PhotoFormat.spainPrototype.aspectRatio, contentMode: .fit)
        .environment(\.layoutDirection, .leftToRight)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.primary.opacity(0.15), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label ?? ""))
        .accessibilityHidden(label == nil)
    }
}
