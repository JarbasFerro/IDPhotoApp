import SwiftUI

/// A native button (or a row with a native trailing control), without another surface inside the tray.
struct TrayRow<Leading: View, Trailing: View>: View {
    let title: Text
    var detail: Text? = nil
    var value: Text? = nil
    var chevron = false
    var action: (() -> Void)? = nil
    let leading: () -> Leading
    let trailing: () -> Trailing

    init(title: Text, detail: Text? = nil, value: Text? = nil, chevron: Bool = false,
         action: (() -> Void)? = nil,
         @ViewBuilder leading: @escaping () -> Leading = { EmptyView() },
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title; self.detail = detail; self.value = value; self.chevron = chevron
        self.action = action; self.leading = leading; self.trailing = trailing
    }

    var body: some View {
        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            if Leading.self != EmptyView.self { leading().frame(width: 24) }
            VStack(alignment: .leading, spacing: 2) {
                title.font(.body).foregroundStyle(.primary)
                if let detail { detail.font(Design.Typography.cardDetail).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 0)
            if let value { value.font(Design.Typography.cardDetail).foregroundStyle(.secondary) }
            trailing()
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .multilineTextAlignment(.leading)
        .frame(minHeight: 50)
        .contentShape(Rectangle())
    }
}

struct TrayRows<Content: View>: View {
    var leadingInset: CGFloat = 36
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content()) { rows in
                ForEach(rows.indices, id: \.self) { index in
                    if index != rows.startIndex { Divider().padding(.leading, leadingInset) }
                    rows[index]
                }
            }
        }
    }
}
