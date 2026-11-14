import Foundation

// First-run tutorial (ADR-052): pure step logic, no UI. The tutorial coaches the real flow on the real screens, so
// the step shown is derived from where the person is and what they have done, not stored as a cursor.

enum TutorialStep: String, Codable, Sendable, CaseIterable {
    case photo, check, sheet, unlock, finish
}

/// What the progress shows: four phases for a print, three for a digital photo (research, 2026-11-14: guided flows
/// complete best at about four steps). Unlocking belongs to the last phase.
enum TutorialPhase: String, Sendable, CaseIterable {
    case photo, check, sheet, finish
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
    /// The person confirmed (or changed) the document on Home. Kept for stored states; no longer a step of its own.
    var documentConfirmed = false
    /// A credit was spent inside the tutorial and the photo has not left the app yet.
    var creditSpent = false

    static let fresh = TutorialState(phase: .active)
    static let done = TutorialState(phase: .completed, welcomed: true, documentConfirmed: true)
}

enum TutorialFlow {
    /// The phases for a document whose main output is `output`. A digital document has no sheet to lay out.
    static func phases(for output: Output) -> [TutorialPhase] {
        output == .print ? [.photo, .check, .sheet, .finish] : [.photo, .check, .finish]
    }

    static func phase(of step: TutorialStep) -> TutorialPhase {
        switch step {
        case .photo: .photo
        case .check: .check
        case .sheet: .sheet
        case .unlock, .finish: .finish
        }
    }

    /// 1-based position of `step`'s phase and the phase count, for "2 of 4".
    static func progress(of step: TutorialStep, output: Output) -> (position: Int, count: Int) {
        let phases = phases(for: output)
        return ((phases.firstIndex(of: phase(of: step)) ?? 0) + 1, phases.count)
    }

    /// The step to coach on `screen`.
    static func step(on screen: TutorialScreen, unlocked: Bool) -> TutorialStep {
        switch screen {
        case .home: .photo
        case .check: .check
        case .sheet: .sheet
        case .print, .digital: unlocked ? .finish : .unlock
        }
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
