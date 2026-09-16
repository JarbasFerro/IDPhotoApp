import SwiftUI

struct CropPreview: View {
    let photo: PreparedPhoto
    @Binding var adjustment: CropAdjustment
    @State private var dragStart: CropAdjustment?
    @State private var pinchStart: CropAdjustment?

    var body: some View {
        GeometryReader { geometry in
            let crop = adjustment.crop(in: photo.pixels)
            Image(decorative: photo.preview, scale: 1)
                .resizable()
                .frame(width: geometry.size.width / crop.width, height: geometry.size.height / crop.height)
                .offset(x: -crop.x / crop.width * geometry.size.width,
                        y: -crop.y / crop.height * geometry.size.height)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped()
                .contentShape(Rectangle())
                .gesture(DragGesture().onChanged { value in
                    if dragStart == nil { dragStart = adjustment }
                    adjustment = (dragStart ?? adjustment).translated(
                        x: value.translation.width, y: value.translation.height,
                        previewWidth: geometry.size.width, source: photo.pixels)
                }.onEnded { _ in dragStart = nil })
                .simultaneousGesture(MagnifyGesture().onChanged { value in
                    if pinchStart == nil { pinchStart = adjustment }
                    var next = adjustment
                    next.zoom = (pinchStart?.zoom ?? 1) * value.magnification
                    adjustment = next.clamped()
                }.onEnded { _ in pinchStart = nil })
        }
        .aspectRatio(PhotoFormat.spainPrototype.aspectRatio, contentMode: .fit)
        // Photo pixel axes remain physical left/right even in an RTL interface.
        .environment(\.layoutDirection, .leftToRight)
        .background(.white)
        .overlay { Rectangle().strokeBorder(.primary.opacity(0.25), lineWidth: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Photo crop preview")
        .accessibilityValue("26 millimeters wide, 32 millimeters high")
        .accessibilityHint("Use the zoom and position controls below to adjust the crop.")
        .accessibilityIdentifier("cropPreview")
    }
}
