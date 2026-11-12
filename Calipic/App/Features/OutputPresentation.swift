import Foundation

/// The two things a finished photo can become.
enum Output: Sendable, Hashable {
    case print, digital
}

extension DocumentChoice {
    /// Outputs offered on Photo Check, main one first.
    ///
    /// Rule (founder decision D-1):
    /// - no print route (`supportsPrint == false`, e.g. Saudi Absher): Digital Photo only;
    /// - custom sizes: Print is main, Digital Photo second;
    /// - otherwise both are offered (the app always can render a digital file, falling back to the document's
    ///   print pixels when the profile has no `digitalOutput`). Print is main, unless printing is shop-only
    ///   (`printIsShopOnly`: UK, Australia) AND the profile has a digital output (`digitalOutput != nil`):
    ///   then the digital file is the faster route and is main.
    var availableOutputs: [Output] {
        guard let profile else { return [.print, .digital] }
        guard supportsPrint else { return [.digital] }
        return printIsShopOnly && profile.digitalOutput != nil ? [.digital, .print] : [.print, .digital]
    }

    var primaryOutput: Output { availableOutputs[0] }
}
