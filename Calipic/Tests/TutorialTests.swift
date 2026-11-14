import Foundation
import Testing
@testable import Calipic

/// First-run tutorial (ADR-052).
struct TutorialTests {
    @Test func phasesFollowTheMainOutput() {
        #expect(TutorialFlow.phases(for: .print) == [.photo, .check, .sheet, .finish])
        #expect(TutorialFlow.phases(for: .digital) == [.photo, .check, .finish])
        #expect(TutorialFlow.progress(of: .unlock, output: .print) == (4, 4))
        #expect(TutorialFlow.progress(of: .finish, output: .print) == (4, 4))
        #expect(TutorialFlow.progress(of: .unlock, output: .digital) == (3, 3))
        #expect(TutorialFlow.progress(of: .check, output: .digital) == (2, 3))
    }

    @Test func stepComesFromTheScreen() {
        #expect(TutorialFlow.step(on: .home, unlocked: false) == .photo)
        #expect(TutorialFlow.step(on: .check, unlocked: false) == .check)
        #expect(TutorialFlow.step(on: .sheet, unlocked: false) == .sheet)
        #expect(TutorialFlow.step(on: .print, unlocked: false) == .unlock)
        #expect(TutorialFlow.step(on: .print, unlocked: true) == .finish)
        #expect(TutorialFlow.step(on: .digital, unlocked: true) == .finish)
    }

    @Test func newInstallsStartAndExistingPeopleDoNot() {
        #expect(TutorialFlow.initial(stored: nil, hasCreditHistory: false) == .fresh)
        #expect(TutorialFlow.initial(stored: nil, hasCreditHistory: true) == .done)
        var midway = TutorialState.fresh
        midway.welcomed = true
        #expect(TutorialFlow.initial(stored: midway, hasCreditHistory: true) == midway)
        #expect(CreditLedger.startingBalance == 1)
    }

    /// The photo is not kept between launches, so a credit spent on it before it left the app comes back once.
    @Test func aLostTutorialPhotoGivesItsCreditBack() {
        var spent = TutorialState.fresh
        spent.creditSpent = true
        let resumed = TutorialFlow.resumed(spent)
        #expect(resumed.refund == 1 && !resumed.state.creditSpent)
        #expect(TutorialFlow.resumed(resumed.state).refund == 0)
        var finished = TutorialState.done
        finished.creditSpent = true
        #expect(TutorialFlow.resumed(finished).refund == 0)
    }

    @MainActor @Test func unlockingInTheTutorialMarksTheCreditAndCompletingEndsIt() throws {
        let defaults = try #require(UserDefaults(suiteName: "TutorialTests-" + UUID().uuidString))
        let credits = CreditStore(defaults: defaults)
        #expect(credits.balance == 1)
        let coach = TutorialCoach.load(defaults: defaults, credits: credits)
        #expect(coach.isActive && coach.needsWelcome)
        coach.welcomed()
        coach.creditSpent()
        #expect(credits.spend(1))
        // Relaunch before the photo left the app: the credit comes back and the tutorial continues.
        let relaunched = TutorialCoach.load(defaults: defaults, credits: credits)
        #expect(credits.balance == 1 && relaunched.isActive && !relaunched.needsWelcome)
        relaunched.creditSpent()
        relaunched.complete()
        #expect(!relaunched.isActive)
        #expect(!TutorialCoach.load(defaults: defaults, credits: credits).isActive)
        #expect(credits.balance == 1)
    }
}
