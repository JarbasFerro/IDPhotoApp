import Foundation
import Observation
import UIKit

/// The first-run tutorial's state on this device (ADR-052). Pass no defaults for an in-memory state (tests).
@MainActor
@Observable
final class TutorialCoach {
    static let key = "tutorialState"
    private(set) var state: TutorialState
    @ObservationIgnored private let defaults: UserDefaults?

    init(state: TutorialState = .done, defaults: UserDefaults? = nil) {
        self.state = state
        self.defaults = defaults
    }

    /// Reads the stored state; a new install (no credit balance stored yet) starts the tutorial. A credit spent on a
    /// tutorial photo that was lost with the last session is given back.
    static func load(defaults: UserDefaults, credits: CreditStore) -> TutorialCoach {
        let stored = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(TutorialState.self, from: $0) }
        // Any trace of an earlier session (a balance, a chosen document, a "Before your photo" seen) is an existing person.
        let used = [CreditStore.key, DocumentStore.key, "preflightSeenDocuments"].contains { defaults.object(forKey: $0) != nil }
        let initial = TutorialFlow.initial(stored: stored, hasCreditHistory: used)
        let resumed = TutorialFlow.resumed(initial)
        if resumed.refund > 0 { credits.grant(resumed.refund) }
        let coach = TutorialCoach(state: resumed.state, defaults: defaults)
        coach.save()
        return coach
    }

    var isActive: Bool { state.phase == .active }
    var needsWelcome: Bool { isActive && !state.welcomed }

    func welcomed() { update { $0.welcomed = true } }
    func confirmDocument() { update { $0.documentConfirmed = true } }
    func creditSpent() { if isActive { update { $0.creditSpent = true } } }

    /// Developer details: start over on a device that already finished it. Credits are left alone.
    func restart() { update { $0 = .fresh } }

    /// The photo has left the app (printed, shared, or saved): the tutorial is over.
    func complete() {
        guard isActive else { return }
        update { $0 = .done }
    }

    private func update(_ change: (inout TutorialState) -> Void) {
        change(&state)
        save()
    }

    private func save() {
        guard let defaults, let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Self.key)
    }
}

/// The system share sheet with a completion, which `ShareLink` does not offer: the tutorial ends only once the
/// print image was actually shared or saved. UIKit only because SwiftUI has no share-completion callback.
@MainActor
enum ShareController {
    static func present(_ items: [Any], onFinish: @escaping @MainActor (Bool) -> Void = { _ in }) {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            MainActor.assumeIsolated { onFinish(completed) }
        }
        controller.popoverPresentationController?.sourceView = top.view
        top.present(controller, animated: true)
    }
}
