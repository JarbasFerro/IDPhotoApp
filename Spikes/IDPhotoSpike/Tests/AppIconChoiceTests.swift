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

    /// BD-038: every icon ships a default, a dark and a tinted 1024 image, so iOS never invents an appearance.
    /// The compiled catalog cannot be read with public API, so this reads the source catalog next to this file.
    /// The simulator sees the Mac's file system, so there a missing catalog is a failure; on a device the sources
    /// are out of reach and the python `--check` remains the gate.
    @Test func everyAppIconSetHasDefaultDarkAndTintedImages() throws {
        let catalog = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/Resources/Assets.xcassets")
        #if targetEnvironment(simulator)
        try #require(FileManager.default.fileExists(atPath: catalog.path), "asset catalog not found at \(catalog.path)")
        #else
        guard FileManager.default.fileExists(atPath: catalog.path) else { return }
        #endif
        struct Contents: Decodable {
            struct Image: Decodable {
                struct Appearance: Decodable { let appearance: String; let value: String }
                let filename: String
                let idiom: String
                let platform: String?
                let size: String
                let appearances: [Appearance]?
            }
            let images: [Image]
        }
        for choice in AppIconChoice.all {
            let set = catalog.appendingPathComponent("\(choice.alternateIconName ?? "AppIcon").appiconset")
            let data = try Data(contentsOf: set.appendingPathComponent("Contents.json"))
            let images = try JSONDecoder().decode(Contents.self, from: data).images
            let appearances = images.map { image in
                (image.appearances ?? []).map { "\($0.appearance)=\($0.value)" }.joined(separator: ",")
            }
            #expect(appearances == ["", "luminosity=dark", "luminosity=tinted"], "\(choice.name)")
            for image in images {
                #expect(image.idiom == "universal" && image.platform == "ios" && image.size == "1024x1024", "\(choice.name)")
                #expect(FileManager.default.fileExists(atPath: set.appendingPathComponent(image.filename).path),
                        "\(choice.name) \(image.filename)")
            }
            #expect(Set(images.map(\.filename)).count == 3, "\(choice.name)")
        }
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
