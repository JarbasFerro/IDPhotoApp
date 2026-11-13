import Foundation
import Testing
@testable import Calipic

/// First-run tutorial (ADR-052).
struct TutorialTests {
    @Test func stepsFollowTheMainOutput() {
        #expect(TutorialFlow.steps(for: .print) == [.document, .photo, .check, .sheet, .unlock, .finish])
        #expect(TutorialFlow.steps(for: .digital) == [.document, .photo, .check, .unlock, .finish])
        #expect(TutorialFlow.position(of: .unlock, in: TutorialFlow.steps(for: .print)) == 5)
        #expect(TutorialFlow.position(of: .unlock, in: TutorialFlow.steps(for: .digital)) == 4)
    }

    @Test func stepComesFromTheScreenAndProgress() {
        #expect(TutorialFlow.step(on: .home, documentConfirmed: false, hasPhoto: false, unlocked: false) == .document)
        #expect(TutorialFlow.step(on: .home, documentConfirmed: true, hasPhoto: false, unlocked: false) == .photo)
        #expect(TutorialFlow.step(on: .check, documentConfirmed: true, hasPhoto: true, unlocked: false) == .check)
        #expect(TutorialFlow.step(on: .sheet, documentConfirmed: true, hasPhoto: true, unlocked: false) == .sheet)
        #expect(TutorialFlow.step(on: .print, documentConfirmed: true, hasPhoto: true, unlocked: false) == .unlock)
        #expect(TutorialFlow.step(on: .print, documentConfirmed: true, hasPhoto: true, unlocked: true) == .finish)
        #expect(TutorialFlow.step(on: .digital, documentConfirmed: true, hasPhoto: true, unlocked: true) == .finish)
    }

    @Test func newInstallsStartAndExistingPeopleDoNot() {
        #expect(TutorialFlow.initial(stored: nil, hasCreditHistory: false) == .fresh)
        #expect(TutorialFlow.initial(stored: nil, hasCreditHistory: true) == .done)
        var midway = TutorialState.fresh
        midway.welcomed = true
        #expect(TutorialFlow.initial(stored: midway, hasCreditHistory: true) == midway)
        #expect(CreditLedger.startingBalance == 2)
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
        #expect(credits.balance == 2)
        let coach = TutorialCoach.load(defaults: defaults, credits: credits)
        #expect(coach.isActive && coach.needsWelcome)
        coach.welcomed()
        coach.creditSpent()
        #expect(credits.spend(1))
        // Relaunch before the photo left the app: the credit comes back and the tutorial continues.
        let relaunched = TutorialCoach.load(defaults: defaults, credits: credits)
        #expect(credits.balance == 2 && relaunched.isActive && !relaunched.needsWelcome)
        relaunched.creditSpent()
        relaunched.complete()
        #expect(!relaunched.isActive)
        #expect(!TutorialCoach.load(defaults: defaults, credits: credits).isActive)
        #expect(credits.balance == 2)
    }
}
