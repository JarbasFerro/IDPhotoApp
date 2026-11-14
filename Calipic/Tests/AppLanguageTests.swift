import Foundation
import Testing
@testable import Calipic

/// The in-app language choice is the app's own `AppleLanguages` default, read by iOS at launch.
@Suite(.serialized)
struct AppLanguageTests {
    @Test func aChoiceIsStoredForTheAppAndAutomaticClearsIt() {
        let before = AppLanguage.stored()
        defer { AppLanguage.store(before) }
        AppLanguage.store(.spanish)
        #expect(AppLanguage.stored() == .spanish)
        #expect(UserDefaults.standard.stringArray(forKey: "AppleLanguages")?.first == "es")
        AppLanguage.store(.portugueseBrazil)
        #expect(AppLanguage.stored() == .portugueseBrazil)
        AppLanguage.store(.automatic)
        #expect(AppLanguage.stored() == .automatic)
    }
}
