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

    /// The test host is launched without `-brandCandidate`, which must leave the app untinted.
    @Test func nothingIsSelectedByDefault() {
        #expect(BrandCandidate.current == nil)
    }
}
