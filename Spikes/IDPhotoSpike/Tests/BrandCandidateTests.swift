import Testing
import UIKit
@testable import IDPhotoSpike

struct BrandCandidateTests {
    @Test func parsesLaunchArgumentValues() {
        #expect(BrandCandidate.parse("A") == .a)
        #expect(BrandCandidate.parse("b") == .b)
        #expect(BrandCandidate.parse("Z") == nil)
        #expect(BrandCandidate.parse("") == nil)
        #expect(BrandCandidate.parse(nil) == nil)
    }

    @Test func everyCandidateHasItsColourInTheAssetCatalog() {
        for candidate in BrandCandidate.allCases {
            #expect(UIColor(named: candidate.assetName) != nil, "\(candidate.assetName)")
        }
    }

    /// Round 1 found every Dark accent failing as a fill (1.4–2.7:1 under a white label); the fill role must not.
    @Test func whiteLabelReachesAAOnEveryFillInEveryAppearance() throws {
        for candidate in BrandCandidate.allCases {
            let fill = try #require(UIColor(named: candidate.fillAssetName), "\(candidate.fillAssetName)")
            for style in [UIUserInterfaceStyle.light, .dark] {
                for accessibilityContrast in [UIAccessibilityContrast.normal, .high] {
                    let traits = UITraitCollection { $0.userInterfaceStyle = style; $0.accessibilityContrast = accessibilityContrast }
                    let ratio = 1.05 / (Self.relativeLuminance(fill.resolvedColor(with: traits)) + 0.05)
                    #expect(ratio >= (accessibilityContrast == .high ? 7 : 4.5),
                            "\(candidate.fillAssetName) style \(style.rawValue) contrast \(accessibilityContrast.rawValue): \(ratio)")
                }
            }
        }
    }

    /// The fill differs from the accent exactly where the accent is too light for a white label: in Dark.
    @Test func darkFillIsDeeperThanTheDarkAccent() throws {
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        for candidate in BrandCandidate.allCases {
            let accent = try #require(UIColor(named: candidate.assetName)).resolvedColor(with: dark)
            let fill = try #require(UIColor(named: candidate.fillAssetName)).resolvedColor(with: dark)
            #expect(Self.relativeLuminance(fill) < Self.relativeLuminance(accent), "\(candidate.rawValue)")
        }
    }

    /// WCAG 2 relative luminance of an sRGB colour.
    private static func relativeLuminance(_ color: UIColor) -> Double {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let linear = [red, green, blue].map { $0 <= 0.04045 ? Double($0) / 12.92 : pow((Double($0) + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    }

    /// The test host is launched without `-brandCandidate`, so the app wears the brand teal and no test system.
    @Test func nothingIsSelectedByDefault() {
        #expect(BrandCandidate.current == nil)
    }
}
