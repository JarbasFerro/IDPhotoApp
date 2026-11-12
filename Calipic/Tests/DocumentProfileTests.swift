import CoreGraphics
import Foundation
import Testing
@testable import Calipic

/// The bundled catalog and the document → render-target mapping (Rules/catalog/v1, ADR-047, ADR-018).
struct DocumentProfileTests {
    private let catalog = ProfileCatalog.bundled

    private func choice(_ id: String) throws -> DocumentChoice {
        .official(try #require(catalog.profile(id), "missing profile \(id)"))
    }

    @Test func bundledCatalogLoadsAllWaveAProfiles() {
        #expect(catalog.schemaVersion == 1)
        #expect(catalog.profiles.count == 22)
        #expect(Set(catalog.profiles.map(\.profileId)).count == 22)
        #expect(catalog.customSizes.options.blackAndWhite)
    }

    @Test func spainDNIKeepsThePrototypeBehaviourExactly() throws {
        let target = try choice("es.national-id.dni").renderTarget
        #expect(target.format == .spainPrototype)
        #expect(target.spec == .icaoEngineeringDefault)
        #expect(target.digital.pixels == PhotoFormat.spainPrototype.output)
        #expect(target.fileBaseName == "Foto-carnet")
        #expect(DocumentChoice.initial.id == "es.national-id.dni")
    }

    @Test func usPassportUsesTwoInchSquareAndOfficialBands() throws {
        let document = try choice("us.passport.standard")
        let target = document.renderTarget
        #expect(abs(target.format.widthMM - 50.8) < 1e-9 && abs(target.format.heightMM - 50.8) < 1e-9)
        #expect(abs(target.spec.headHeightTarget - 0.594) < 1e-9)
        // 1–1⅜ in on a 2 in photo.
        #expect(abs(target.spec.headHeightRange.lowerBound - 0.5) < 1e-9)
        #expect(abs(target.spec.headHeightRange.upperBound - 0.6875) < 1e-9)
        // Eyes 56–69 % from the bottom → 31–44 % from the top.
        #expect(abs(target.spec.eyeLineRange.lowerBound - 0.31) < 1e-9)
        #expect(abs(target.spec.eyeLineRange.upperBound - 0.44) < 1e-9)
        #expect(target.spec.headHeightRange.contains(target.spec.headHeightTarget))
        #expect(target.spec.eyeLineRange.contains(target.spec.eyeLineTarget))
        #expect(target.digital.pixels == OutputPixels(width: 1200, height: 1200))
        #expect(DocumentPresentation.size(document) == DocumentPresentation.size(widthMM: 50.8, heightMM: 50.8))
    }

    @Test func everyOfficialTargetSitsInsideItsOwnBands() {
        for profile in catalog.profiles {
            let spec = DocumentChoice.official(profile).composition
            #expect(spec.headHeightRange.contains(spec.headHeightTarget), "\(profile.profileId) head")
            #expect(spec.eyeLineRange.contains(spec.eyeLineTarget), "\(profile.profileId) eye line")
        }
    }

    @Test func everyDigitalPresetMatchesItsTrimAspect() {
        for profile in catalog.profiles {
            let target = DocumentChoice.official(profile).renderTarget
            guard !target.digital.looseFraming else { continue }
            let digital = target.digital.format(base: target.format)
            #expect(abs(digital.aspectRatio - target.format.aspectRatio) < 0.005, "\(profile.profileId)")
        }
    }

    @Test func usVisaLimitsTheFileTo240KB() throws {
        let digital = try choice("us.visa.standard").digital
        #expect(digital.pixels == OutputPixels(width: 600, height: 600))
        #expect(digital.maxBytes == 240_000)
    }

    @Test func ukDigitalIsLooseAndPrintIsShopOnly() throws {
        let document = try choice("gb.passport.standard")
        #expect(document.digital.looseFraming)
        #expect(document.digital.adjustment(for: CropAdjustment(zoom: 2)).zoom == 1.6)
        #expect(document.printIsShopOnly)
        #expect(document.printNoteKey == "output.note.uk-home-print")
        #expect(document.backgroundColor == BackgroundColor(hex: "#E6E6E6"))
    }

    @Test func saudiResidentPhotoIsDigitalOnly() throws {
        let document = try choice("sa.residence-permit.photo-update")
        #expect(!document.supportsPrint)
        #expect(document.format.output == OutputPixels(width: 800, height: 1200))
        #expect(abs(document.format.aspectRatio - 2.0 / 3.0) < 1e-9)
    }

    @Test func netherlandsRequires400ppiPrints() throws {
        let profile = try #require(catalog.profile("nl.passport.standard"))
        #expect(profile.printOutput?.minPpi == 400)
        // The app's 20 px/mm render policy is 508 ppi, above the requirement.
        #expect(DocumentChoice.official(profile).format.pixelsPerInch >= 400)
    }

    @Test func customSizeHasNoRulesAndDefaultFraming() {
        let document = DocumentChoice.custom(widthMM: 25, heightMM: 30)
        #expect(document.isCustom)
        #expect(document.composition == .icaoEngineeringDefault)
        #expect(document.supportsPrint)
        #expect(document.format.output == OutputPixels(width: 500, height: 600))
        #expect(document.backgroundColor == .white)
        #expect(document.fileBaseName == "Photo")
        #expect(!DocumentChoice.customSizeRange.contains(9.9))
        #expect(DocumentChoice.customSizeRange.contains(50.8))
    }

    @Test func shortcutsUseLocalNamesWhereTheLocaleHasThem() throws {
        let infantil = try #require(catalog.customSizes.shortcuts.first { $0.id == "25x30" })
        #expect(infantil.localeNameKeys["es-MX"] == "custom.25x30.name.es-MX")
        let brazil = try #require(catalog.customSizes.shortcuts.first { $0.id == "30x40" })
        #expect(brazil.localeNameKeys["pt-BR"] == "custom.30x40.name.pt-BR")
    }

    @Test func hexColoursParseAndRejectMalformedValues() {
        #expect(BackgroundColor(hex: "#FFFFFF") == .white)
        #expect(BackgroundColor(hex: "FFFFFF") == nil)
        #expect(BackgroundColor(hex: "#GGGGGG") == nil)
    }

    @Test func profileSourcesAreHTTPS() {
        for profile in catalog.profiles {
            #expect(!profile.sources.isEmpty, "\(profile.profileId)")
            #expect(profile.sources.allSatisfy { $0.url.hasPrefix("https://") }, "\(profile.profileId)")
        }
    }
}

/// Switching documents re-frames the session without losing people or edits.
@MainActor
struct DocumentSwitchingTests {
    @Test func switchingMovesDefaultPrintSizesAndKeepsOthers() throws {
        let model = PhotoWorkflow(pipeline: PhotoPipeline(root: FileManager.default.temporaryDirectory
            .appendingPathComponent("DocumentSwitch-" + UUID().uuidString)))
        let photoID = UUID()
        model.printJob.items = [PrintItem(photoID: photoID, trimWidthMM: 26, trimHeightMM: 32, copies: 8),
                                PrintItem(photoID: photoID, trimWidthMM: 35, trimHeightMM: 45, copies: 4)]
        let us = try #require(ProfileCatalog.bundled.profile("us.passport.standard"))
        model.setDocument(.official(us))
        #expect(model.document.id == "us.passport.standard")
        #expect(abs(model.printJob.items[0].trimWidthMM - 50.8) < 1e-9)
        #expect(model.printJob.items[1].trimWidthMM == 35)
        #expect(model.policy.background == .white)
        model.setDocument(.custom(widthMM: 30, heightMM: 40))
        #expect(model.printJob.items[0].trimWidthMM == 30 && model.printJob.items[0].trimHeightMM == 40)
    }
}

/// Which document a launch starts on (docs/04-architecture.md §6): saved choice, then the region's default, then ask once.
struct DocumentStoreTests {
    private let catalog = ProfileCatalog.bundled

    @Test func savedChoiceWinsOverRegion() {
        let start = DocumentStore.start(stored: "jp.passport.standard", regionCode: "US", catalog: catalog)
        #expect(start.choice.id == "jp.passport.standard")
        #expect(!start.needsPrompt)
    }

    @Test(arguments: [("US", "us.passport.standard"), ("GB", "gb.passport.standard"), ("ES", "es.national-id.dni"),
                      ("de", "de.driving-licence.standard")])
    func regionDefaultIsUsedWithoutASavedChoice(region: String, expected: String) {
        let start = DocumentStore.start(stored: nil, regionCode: region, catalog: catalog)
        #expect(start.choice.id == expected)
        #expect(!start.needsPrompt)
    }

    @Test(arguments: ["BR", "CA", "FR", nil] as [String?])
    func regionsWithoutAProfileAreAskedOnce(region: String?) {
        let start = DocumentStore.start(stored: nil, regionCode: region, catalog: catalog)
        #expect(start.needsPrompt)
        #expect(start.choice == .initial)
    }

    @Test func regionDefaultsNeverPointAtAnotherCountry() {
        for (region, id) in catalog.regionDefaults {
            #expect(catalog.profile(id)?.jurisdiction.countryCode == region, "\(region) → \(id)")
        }
        // Visa profiles serve people outside the issuing country.
        #expect(catalog.regionDefaults["CA"] == nil)
    }

    @Test func choicesRoundTripThroughStorage() throws {
        let custom = DocumentChoice.custom(widthMM: 25, heightMM: 30.5)
        #expect(DocumentStore.decode(DocumentStore.encode(custom), catalog: catalog) == custom)
        let official = DocumentChoice.official(try #require(catalog.profile("kr.passport.standard")))
        #expect(DocumentStore.decode(DocumentStore.encode(official), catalog: catalog) == official)
    }

    @Test(arguments: ["custom:5x30", "custom:abc", "custom:30", "zz.unknown.profile", ""])
    func unusableSavedValuesFallBack(stored: String) {
        #expect(DocumentStore.decode(stored, catalog: catalog) == nil)
        #expect(DocumentStore.start(stored: stored, regionCode: "US", catalog: catalog).choice.id == "us.passport.standard")
    }
}

/// Honest editing and by-eye checks on Photo Check (ADR-051).
struct PhotoCheckHonestyTests {
    private func entry(background: BackgroundChoice, tone: Bool) throws -> PhotoEntry {
        let context = try #require(CGContext(data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 0,
                                             space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                             bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        var entry = PhotoEntry(photo: PreparedPhoto(id: UUID(), pixels: SourcePixels(width: 4, height: 4),
                                                    preview: try #require(context.makeImage())))
        entry.adjustment.background = background
        entry.adjustment.tone = tone ? ToneSettings() : .off
        return entry
    }

    @Test func noteAppearsOnlyWhereRulesForbidEditingAndSomethingChanged() throws {
        let us = DocumentChoice.official(try #require(ProfileCatalog.bundled.profile("us.passport.standard")))
        let spain = DocumentChoice.official(try #require(ProfileCatalog.bundled.profile("es.national-id.dni")))
        #expect(us.officialRulesForbidEditing)
        #expect(!spain.officialRulesForbidEditing)
        #expect(CheckPresentation.editingNote(for: try entry(background: .color(.white), tone: true), document: us) != nil)
        #expect(CheckPresentation.editingNote(for: try entry(background: .original, tone: true), document: us) != nil)
        #expect(CheckPresentation.editingNote(for: try entry(background: .original, tone: false), document: us) == nil)
        #expect(CheckPresentation.editingNote(for: try entry(background: .color(.white), tone: true), document: spain) == nil)
        #expect(CheckPresentation.editingNote(for: try entry(background: .color(.white), tone: true),
                                              document: .custom(widthMM: 30, heightMM: 40)) == nil)
    }

    @Test func byEyeChecksComeFromTheProfileAndSkipPrintInstructions() throws {
        let australia = DocumentChoice.official(try #require(ProfileCatalog.bundled.profile("au.passport.standard")))
        #expect(australia.byEyeChecks == ["neutral-expression"])
        let us = DocumentChoice.official(try #require(ProfileCatalog.bundled.profile("us.passport.standard")))
        #expect(us.byEyeChecks.contains("no-glasses"))
        #expect(DocumentChoice.custom(widthMM: 30, heightMM: 40).byEyeChecks.isEmpty)
    }

    @Test func worstStateOrdersFailWarnManualPass() {
        func summary(_ states: [CheckState]) -> PhotoCheckSummary {
            let topics: [PhotoCheckSummary.Row.Topic] = [.face, .framing, .background, .light, .detail]
            return PhotoCheckSummary(headline: .review, rows: zip(topics, states).map {
                .init(topic: $0, state: $1, title: "t", detail: "d")
            })
        }
        #expect(summary([.pass, .manualCheck, .warn, .fail]).worstState == .fail)
        #expect(summary([.pass, .manualCheck, .warn]).worstState == .warn)
        #expect(summary([.pass, .manualCheck]).worstState == .manualCheck)
        #expect(summary([.pass, .pass]).worstState == .pass)
        #expect(summary([.pass, .warn, .manualCheck]).attention.count == 2)
    }
}

/// Every catalog key the app shows must resolve to words, never to the raw key.
struct CatalogStringsTests {
    @Test func checkLabelsAndProfileNamesAreWords() {
        for profile in ProfileCatalog.bundled.profiles {
            let name = DocumentPresentation.name(.official(profile))
            #expect(!name.hasPrefix("profile."), "\(profile.profileId)")
            for check in profile.checks {
                let label = DocumentPresentation.check(check.id)
                #expect(!label.hasPrefix("check."), "\(profile.profileId): \(check.id)")
            }
            if let note = DocumentChoice.official(profile).printNoteKey {
                #expect(!String(localized: String.LocalizationValue(note)).hasPrefix("output."), "\(profile.profileId)")
            }
        }
        #expect(DocumentPresentation.check("eyes-open") == "Eyes open" || Locale.current.language.languageCode != "en")
    }
}
