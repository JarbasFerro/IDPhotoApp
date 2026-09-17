import SwiftUI

/// Step 4: files are prepared on arrival; two cards, print first.
struct ShareView: View {
    @Bindable var model: PhotoWorkflow
    @Binding var path: [Route]
    @State private var completed = false
    @State private var celebrated = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let result = model.exported {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(StatusStyle.pass)
                            .symbolEffect(.bounce, options: .nonRepeating, isActive: celebrated && !reduceMotion)
                        Text("Your files are ready.").font(.title2.weight(.semibold))
                        Text("Print the sheet or share the photos.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .combine)
                    .onAppear { celebrated = true }
                    printCard(result)
                    digitalCard(result)
                    Button {
                        completed = true
                        path.removeAll()
                    } label: {
                        Text("Done").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityIdentifier("shareDone")
                } else if model.activity == .exporting {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Preparing your files…")
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .accessibilityElement(children: .combine)
                } else {
                    ContentUnavailableView {
                        Label("Files not ready", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("Something went wrong while preparing the files.")
                    } actions: {
                        Button("Try Again") { model.prepareExport() }.buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Share")
        .navigationBarTitleDisplayMode(.inline)
        .task { if model.exported == nil, model.activity == nil { model.prepareExport() } }
        .onDisappear { model.finishExport() }
        .sensoryFeedback(.success, trigger: model.exported?.id)
    }

    private func printCard(_ result: PhotoExport) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                SheetPreview(layout: result.layout, thumbnails: model.sheetThumbnails, compact: true)
                    .frame(width: 96)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Print sheet").font(.headline)
                    Text("\(PaperNames.name(for: model.printJob.paper)) · ^[\(result.layout.placedCount) copy](inflect: true) · ^[\(result.layout.pages.count) page](inflect: true)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("Print at Actual Size (100 %), not Fit to Page. Then measure the 50 mm bar before cutting.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if PrintController.isAvailable {
                Button {
                    PrintController.shared.present(pdf: result.pdf, jobName: String(localized: "Calipic sheet"))
                } label: {
                    Label("Print", systemImage: "printer").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("print")
            }
            HStack(spacing: 12) {
                ShareLink(item: result.pdf) { Label("Share PDF", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("sharePDF")
                ShareLink(items: result.pages) { Label("Share JPEG", systemImage: "photo.on.rectangle.angled").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("sharePages")
            }
        }
        .padding()
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
    }

    /// One thumbnail per person; tap a thumbnail to share that JPEG. The badge in the corner says so.
    private func digitalCard(_ result: PhotoExport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(result.jpegs.count == 1 ? "Digital photo" : "Digital photos").font(.headline)
                Spacer()
                if result.jpegs.count > 1 {
                    ShareLink(items: result.jpegs) { Label("Share all", systemImage: "square.and.arrow.up.on.square") }
                        .font(.subheadline)
                        .accessibilityIdentifier("shareAllJPEGs")
                }
            }
            Text("JPEG, 520 × 640 pixels, for online forms. Tap a photo to share it.")
                .font(.footnote).foregroundStyle(.secondary)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(Array(result.jpegs.enumerated()), id: \.offset) { index, url in
                        ShareLink(item: url) {
                            VStack(spacing: 6) {
                                ZStack(alignment: .bottomTrailing) {
                                    if let entry = model.entries.dropFirst(index).first {
                                        PortraitView(entry: entry).frame(width: 86)
                                    } else {
                                        RoundedRectangle(cornerRadius: 6).fill(.fill).frame(width: 86, height: 106)
                                    }
                                    Image(systemName: "square.and.arrow.up.circle.fill")
                                        .font(.title2)
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.accentColor)
                                        .offset(x: 8, y: 6)
                                }
                                if result.jpegs.count > 1 {
                                    Text("Photo \(index + 1)").font(.caption).foregroundStyle(.primary)
                                }
                            }
                            .padding(.top, 4).padding(.trailing, 8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(result.jpegs.count == 1 ? "Share JPEG" : "Share JPEG, photo \(index + 1)"))
                        .accessibilityIdentifier(index == 0 ? "shareJPEG" : "shareJPEG-\(index + 1)")
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
        .padding()
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
    }
}
