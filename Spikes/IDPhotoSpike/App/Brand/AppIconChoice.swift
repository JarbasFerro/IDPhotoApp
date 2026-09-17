import Observation
import UIKit

/// A character people can put inside the app icon (BD-038). The C-frame, teal and finish are constant; only the
/// character changes. The list, `AppIconChoice.all`, is generated into AppIconCatalog.swift from `VARIANTS` in
/// scripts/brand/build-icon-v2.py, together with the app-icon sets, the previews and the build setting that lists
/// the alternates. Changing the set: edit VARIANTS, run scripts/brand/generate-brand-assets.py, and add or remove
/// the "AppIcon.<name>" label in Localizable.xcstrings.
struct AppIconChoice: Identifiable, Hashable, Sendable {
    enum Group: CaseIterable, Sendable {
        case people, fun

        var title: LocalizedStringResource {
            switch self {
            case .people: "People"
            case .fun: "Just for fun"
            }
        }
    }

    /// The VARIANTS name, for example "unicorn".
    let name: String
    let group: Group

    var id: String { name }

    /// The first generated entry is the primary icon.
    static var primary: AppIconChoice { all[0] }

    static func choices(in group: Group) -> [AppIconChoice] {
        all.filter { $0.group == group }
    }

    /// The choice the system reports; an unknown name (an icon removed in an update) reads as the primary icon.
    static func current(alternateIconName: String?) -> AppIconChoice {
        all.first { $0.alternateIconName == alternateIconName } ?? primary
    }

    /// The name iOS knows the icon by; `nil` is the primary icon.
    var alternateIconName: String? {
        self == Self.primary ? nil : "AppIcon-\(name)"
    }

    /// Small pre-masked image for the picker. App-icon sets themselves cannot be loaded as images.
    var previewAssetName: String { "IconPreview-\(name)" }

    /// String Catalog key of the label. The keys are built at run time, so the entries are maintained by hand
    /// (`extractionState: manual`) and checked by the generator and by AppIconChoiceTests.
    var labelKey: String { "AppIcon.\(name)" }

    /// Short plain noun for VoiceOver and Voice Control, for example "Short hair" or "Unicorn".
    var label: String {
        Bundle.main.localizedString(forKey: labelKey, value: nil, table: nil)
    }
}

/// The part of `UIApplication` the icon picker needs, so tests can stand in for it.
@MainActor
protocol AppIconApplication: AnyObject {
    var supportsAlternateIcons: Bool { get }
    var alternateIconName: String? { get }
    func setAlternateIconName(_ alternateIconName: String?) async throws
}

extension UIApplication: AppIconApplication {}

/// Reads and sets the app icon. The selection lives in the system (`alternateIconName`); nothing is persisted here.
@MainActor
@Observable
final class AppIconController {
    private(set) var current: AppIconChoice
    /// True after a change the system refused; the picker shows one plain message.
    var changeFailed = false

    @ObservationIgnored private let application: any AppIconApplication

    init(application: any AppIconApplication = UIApplication.shared) {
        self.application = application
        current = AppIconChoice.current(alternateIconName: application.alternateIconName)
    }

    var isSupported: Bool { application.supportsAlternateIcons }

    /// Re-reads the system's value, which is the source of truth.
    func refresh() {
        current = AppIconChoice.current(alternateIconName: application.alternateIconName)
    }

    /// True while the system is applying a change; the picker ignores taps meanwhile, because a second request
    /// made before the first one finishes fails.
    private(set) var isChanging = false

    func select(_ choice: AppIconChoice) async {
        // Compare with the system's own value, not with `current`: after an update that removed the chosen icon the
        // system still holds its name, `current` already reads as the primary, and tapping the primary must reset it.
        guard isSupported, !isChanging, choice.alternateIconName != application.alternateIconName else { return }
        isChanging = true
        defer { isChanging = false }
        do {
            try await application.setAlternateIconName(choice.alternateIconName)
        } catch {
            changeFailed = true
        }
        refresh()
    }
}
