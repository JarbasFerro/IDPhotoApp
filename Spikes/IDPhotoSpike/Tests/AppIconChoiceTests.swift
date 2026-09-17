import Foundation
import Testing
import UIKit
@testable import IDPhotoSpike

@MainActor
struct AppIconChoiceTests {
    /// The tests are hosted in the app, so `Bundle.main` is the built app with its compiled Info.plist.
    private var alternatesInInfoPlist: Set<String> {
        let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any]
        let alternates = icons?["CFBundleAlternateIcons"] as? [String: Any]
        return Set((alternates ?? [:]).keys)
    }

    @Test func primaryIsFirstAndHasNoAlternateName() {
        #expect(AppIconChoice.primary == AppIconChoice.all.first)
        #expect(AppIconChoice.primary.name == "swept")
        #expect(AppIconChoice.primary.alternateIconName == nil)
        #expect(AppIconChoice.all.dropFirst().allSatisfy { $0.alternateIconName == "AppIcon-\($0.name)" })
        #expect(Set(AppIconChoice.all.map(\.name)).count == AppIconChoice.all.count)
    }

    @Test func builtAppListsExactlyTheGeneratedAlternates() {
        #expect(alternatesInInfoPlist == Set(AppIconChoice.all.compactMap(\.alternateIconName)))
        let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any]
        let primary = icons?["CFBundlePrimaryIcon"] as? [String: Any]
        #expect(primary?["CFBundleIconName"] as? String == "AppIcon")
    }

    @Test func everyChoiceHasAPreviewImage() {
        for choice in AppIconChoice.all {
            #expect(UIImage(named: choice.previewAssetName) != nil, "\(choice.previewAssetName)")
        }
    }

    @Test func everyChoiceHasALabelInEveryLanguage() throws {
        for language in ["en", "es", "pt-BR"] {
            let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"), "\(language)")
            let bundle = try #require(Bundle(path: path))
            for choice in AppIconChoice.all {
                let label = bundle.localizedString(forKey: choice.labelKey, value: "\u{0}", table: nil)
                #expect(label != "\u{0}" && label != choice.labelKey && !label.isEmpty, "\(language) \(choice.labelKey)")
            }
        }
    }

    @Test func groupsKeepTheGeneratedOrderAndCoverEveryChoice() {
        let grouped = AppIconChoice.Group.allCases.flatMap(AppIconChoice.choices(in:))
        #expect(grouped == AppIconChoice.all)
        #expect(AppIconChoice.Group.allCases.allSatisfy { !AppIconChoice.choices(in: $0).isEmpty })
    }

    @Test func unknownSystemNameReadsAsThePrimaryIcon() {
        #expect(AppIconChoice.current(alternateIconName: nil) == .primary)
        #expect(AppIconChoice.current(alternateIconName: "AppIcon-removed-in-an-update") == .primary)
        let second = AppIconChoice.all[1]
        #expect(AppIconChoice.current(alternateIconName: second.alternateIconName) == second)
    }

    @Test func controllerReadsSetsAndReportsFailure() async {
        let application = FakeApplication()
        let second = AppIconChoice.all[1]
        application.alternateIconName = second.alternateIconName
        let controller = AppIconController(application: application)
        #expect(controller.isSupported)
        #expect(controller.current == second)

        let last = AppIconChoice.all[AppIconChoice.all.count - 1]
        await controller.select(last)
        #expect(application.alternateIconName == last.alternateIconName)
        #expect(controller.current == last)
        #expect(!controller.changeFailed)

        await controller.select(.primary)
        #expect(application.alternateIconName == nil)
        #expect(controller.current == .primary)

        application.fails = true
        await controller.select(second)
        #expect(controller.changeFailed)
        #expect(controller.current == .primary)
    }

    /// After an update that removed the chosen icon the system still holds the old name.
    @Test func choosingThePrimaryResetsAnIconThatNoLongerExists() async {
        let application = FakeApplication()
        application.alternateIconName = "AppIcon-removed-in-an-update"
        let controller = AppIconController(application: application)
        #expect(controller.current == .primary)
        await controller.select(.primary)
        #expect(application.setCalls == 1)
        #expect(application.alternateIconName == nil)
    }

    @Test func controllerDoesNothingWhenUnsupportedOrUnchanged() async {
        let application = FakeApplication()
        application.supportsAlternateIcons = false
        let controller = AppIconController(application: application)
        await controller.select(AppIconChoice.all[1])
        #expect(application.setCalls == 0)

        application.supportsAlternateIcons = true
        await controller.select(.primary)
        #expect(application.setCalls == 0)
    }
}

@MainActor
private final class FakeApplication: AppIconApplication {
    struct Refused: Error {}
    var supportsAlternateIcons = true
    var alternateIconName: String?
    var fails = false
    var setCalls = 0

    func setAlternateIconName(_ alternateIconName: String?) async throws {
        setCalls += 1
        if fails { throw Refused() }
        self.alternateIconName = alternateIconName
    }
}
