import SwiftUI

/// U4, one continuous object: a screen opens by zooming out of the thing that was tapped. It uses the system zoom
/// transition, which a back swipe can interrupt and which the system calms under Reduce Motion.
enum ZoomSource {
    /// The source of the screen pushed at `index` in the navigation path. The index keeps two sources of one route
    /// apart (the sheet card on Home and the photo on Photo Check both open Your sheet).
    static func id(_ route: Route, at index: Int) -> String {
        switch route {
        case .check: "check-\(index)"
        case .digital: "digital-\(index)"
        case .sheet: "sheet-\(index)"
        case .share: "share-\(index)"
        }
    }

    /// Routes that always open from a visible source. Photo Check also opens after the camera or the picker,
    /// where nothing on screen is its source, so it keeps the standard push.
    static func zooms(_ route: Route) -> Bool {
        if case .check = route { return false }
        return true
    }
}

extension EnvironmentValues {
    /// The namespace the navigation stack's zoom transitions share; nil outside `RootView` (previews, tests).
    @Entry var zoomNamespace: Namespace.ID?
}

extension View {
    /// Marks this view as where `route`, pushed at `index`, zooms out of.
    @ViewBuilder func zoomSource(_ route: Route, at index: Int, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            matchedTransitionSource(id: ZoomSource.id(route, at: index), in: namespace)
        } else {
            self
        }
    }

    /// The destination half: zooms out of the source registered for `route` at `index`.
    @ViewBuilder func zoomDestination(_ route: Route, at index: Int, in namespace: Namespace.ID?) -> some View {
        if let namespace, ZoomSource.zooms(route) {
            navigationTransition(.zoom(sourceID: ZoomSource.id(route, at: index), in: namespace))
        } else {
            self
        }
    }
}

extension PrintPage {
    /// Placement indexes grouped into the rows seen on screen, top to bottom (after any quarter turn), so copies can
    /// appear one row after another.
    var displayRows: [[Int]] {
        let turned = displaysTurned
        let keyed = placements.enumerated().map { index, placement in
            let midX = placement.trim.x + placement.trim.width / 2, midY = placement.trim.y + placement.trim.height / 2
            let x = turned ? midY : midX
            let y = turned ? widthMM - midX : midY
            return (index: index, x: x, y: y)
        }
        var rows: [[(index: Int, x: Double, y: Double)]] = []
        for item in keyed.sorted(by: { $0.y < $1.y }) {
            if let last = rows.last?.first, abs(last.y - item.y) < 1 { rows[rows.count - 1].append(item) } else { rows.append([item]) }
        }
        return rows.map { $0.sorted { $0.x < $1.x }.map(\.index) }
    }
}
