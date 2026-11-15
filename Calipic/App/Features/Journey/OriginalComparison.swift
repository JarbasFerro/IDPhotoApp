import Foundation

/// Holds take precedence over a timed tap; an expired tap cannot end a newer comparison.
struct OriginalComparison {
    private(set) var photoHeld = false
    private(set) var controlHeld = false
    private var latched = false
    private(set) var pulse: UUID?

    var isComparing: Bool { photoHeld || controlHeld || latched || pulse != nil }

    mutating func holdPhoto(_ held: Bool) {
        photoHeld = held
        if held { pulse = nil; latched = false }
    }

    mutating func holdControl(_ held: Bool) {
        controlHeld = held
        if held { pulse = nil; latched = false }
    }

    mutating func showBriefly() { latched = false; pulse = UUID() }
    mutating func finishPulse(_ id: UUID) { if pulse == id { pulse = nil } }
    mutating func toggle() {
        let wasComparing = isComparing
        pulse = nil
        latched = !wasComparing
    }
}
