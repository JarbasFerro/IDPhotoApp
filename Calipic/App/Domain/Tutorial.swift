import Foundation

// First-run tutorial (ADR-052): pure step logic, no UI. The tutorial coaches the real flow on the real screens, so
// the step shown is derived from where the person is and what they have done, not stored as a cursor.

enum TutorialStep: String, Codable, Sendable, CaseIterable {
    case document, photo, check, sheet, unlock, finish
}

/// The screens that show a coach card.
enum TutorialScreen: Sendable, Hashable {
    case home, check, sheet, print, digital
}

/// What is persisted between launches.
struct TutorialState: Codable, Equatable, Sendable {
    enum Phase: String, Codable, Sendable { case active, completed }
    var phase: Phase
    /// The welcome page was shown.
    var welcomed = false
    /// The person confirmed (or changed) the document on Home.
    var documentConfirmed = false
    /// A credit was spent inside the tutorial and the photo has not left the app yet.
    var creditSpent = false

    static let fresh = TutorialState(phase: .active)
    static let done = TutorialState(phase: .completed, welcomed: true, documentConfirmed: true)
}

enum TutorialFlow {
    /// The steps for a document whose main output is `output`. A digital document has no sheet to lay out.
    static func steps(for output: Output) -> [TutorialStep] {
        output == .print ? [.document, .photo, .check, .sheet, .unlock, .finish]
                         : [.document, .photo, .check, .unlock, .finish]
    }

    /// The step to coach on `screen`.
    static func step(on screen: TutorialScreen, documentConfirmed: Bool, hasPhoto: Bool, unlocked: Bool) -> TutorialStep {
        switch screen {
        case .home: !documentConfirmed ? .document : .photo
        case .check: .check
        case .sheet: .sheet
        case .print, .digital: unlocked ? .finish : .unlock
        }
    }

    /// 1-based position of `step` among `steps`, for "3 of 6".
    static func position(of step: TutorialStep, in steps: [TutorialStep]) -> Int {
        (steps.firstIndex(of: step) ?? 0) + 1
    }

    /// At launch: photos are not kept between launches yet (ADR-049 drafts are not built), so a credit spent on a
    /// tutorial photo that never left the app is given back, and the person never pays twice for the tutorial.
    static func resumed(_ state: TutorialState) -> (state: TutorialState, refund: Int) {
        guard state.phase == .active, state.creditSpent else { return (state, 0) }
        var next = state
        next.creditSpent = false
        return (next, 1)
    }

    /// A new install starts the tutorial; an install that already has a credit balance (an existing person) does not.
    static func initial(stored: TutorialState?, hasCreditHistory: Bool) -> TutorialState {
        if let stored { return stored }
        return hasCreditHistory ? .done : .fresh
    }
}
