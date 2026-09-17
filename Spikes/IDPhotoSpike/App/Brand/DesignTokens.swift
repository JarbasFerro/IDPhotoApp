import SwiftUI

/// Calipic's executable design tokens (docs/brand/11-design-tokens.md).
///
/// A small semantic layer over SwiftUI, named by role and not by value. Every value was taken from what the screens
/// already used, so adopting a token changes nothing on screen. Colours are not here: the accent roles live in
/// `Brand` (BrandRoles.swift) and the status colours in `StatusStyle`. Type is system fonts and Dynamic Type only.
enum Design {
    /// Distances between things, in points. They do not scale with Dynamic Type; text does.
    enum Spacing {
        /// A title and the detail line directly under it.
        static let titlePair: CGFloat = 2
        /// A control and its own label (slider title, page caption).
        static let tight: CGFloat = 4
        /// A picture and its caption; lines of a note.
        static let caption: CGFloat = 6
        /// A heading and the paragraph or control that belongs to it.
        static let text: CGFloat = 8
        /// A status glyph and its text; items in a quiet row.
        static let row: CGFloat = 10
        /// Neighbouring buttons, stacked or side by side.
        static let control: CGFloat = 12
        /// Content inside a card: thumbnail to text, line to line.
        static let cardContent: CGFloat = 14
        /// Blocks that belong to one step; the grid of the icon picker.
        static let group: CGFloat = 16
        /// Blocks inside a sheet or a scrolling accessibility layout.
        static let block: CGFloat = 20
        /// Sections of a short, finished screen (Share).
        static let sectionTight: CGFloat = 24
        /// Sections of a screen (Home, the icon picker).
        static let section: CGFloat = 28
    }

    /// Corner radii, in points.
    enum Radius {
        /// A photo shown as an object: just enough to read as paper, never a rounded avatar.
        static let photo: CGFloat = 6
        /// A symbol tile inside a card.
        static let tile: CGFloat = 10
        /// A card: a tappable or grouped surface on a screen.
        static let card: CGFloat = 16
    }

    /// Line widths, in points.
    enum Stroke {
        /// Edges of photos, pages and crop previews; cut marks on the sheet preview.
        static let hairline: CGFloat = 1
        /// A ring that separates an overlapping element from what is behind it (faces, badges).
        static let separation: CGFloat = 2
        /// Guides drawn over a photo or the camera (the Calipic frame, the head oval).
        static let guide: CGFloat = 2
        /// The same guides under Increase Contrast.
        static let guideHighContrast: CGFloat = 3

        static func guide(for contrast: ColorSchemeContrast) -> CGFloat {
            contrast == .increased ? guideHighContrast : guide
        }
    }

    /// Sizes of glyphs, thumbnails and targets, in points.
    enum Size {
        /// Smallest interactive target (HIG). Only ever a minimum width or height, never a visual size.
        static let minimumTarget: CGFloat = 44
        /// A small square picture in a card or row: session faces, symbol tiles.
        static let thumbnail: CGFloat = 44
        /// Base side of the app-icon thumbnail in the Home row; scaled with `.footnote`.
        static let settingsIcon: CGFloat = 29
        /// Base side of an app-icon preview in the picker; scaled with `.body`.
        static let pickerIcon: CGFloat = 76
        /// The completion seal on Share.
        static let completionSeal: CGFloat = 56
    }

    /// Type roles. System text styles only, so Dynamic Type, Bold Text and localisation keep working.
    enum Typography {
        /// The one sentence that names a screen's promise or result.
        static let screenTitle = Font.title2.weight(.semibold)
        /// The check headline.
        static let statusTitle = Font.title3.weight(.semibold)
        /// Large status or card glyph next to a title.
        static let titleGlyph = Font.title2
        /// Card and section titles.
        static let cardTitle = Font.headline
        /// The line under a card title; summaries.
        static let cardDetail = Font.subheadline
        /// A row's name, next to its detail.
        static let rowTitle = Font.subheadline.weight(.semibold)
        /// Explanations, privacy and compliance notes.
        static let note = Font.footnote
        /// Version and measurements that must not jitter.
        static let noteDigits = Font.footnote.monospacedDigit()
        /// Captions under pictures.
        static let caption = Font.caption
    }

    /// Motion. The animation is private: a view can only reach it through `resolved`, which has to be told about
    /// Reduce Motion, so the setting cannot be forgotten.
    struct Motion: Equatable, Sendable {
        private let animation: Animation

        /// `nil` under Reduce Motion: the change still happens, without movement.
        func resolved(reduceMotion: Bool) -> Animation? { reduceMotion ? nil : animation }
        /// For views that receive the decision from their parent as `animated` (already false under Reduce Motion).
        func resolved(animated: Bool) -> Animation? { animated ? animation : nil }

        /// The portrait settles into its official frame (Photo Check).
        static let landing = Motion(animation: .spring(duration: 0.8, bounce: 0.12))
        /// A crop moves to a new position.
        static let reframe = Motion(animation: .spring(duration: 0.7, bounce: 0.1))
        /// Press and hold to compare with the original.
        static let compare = Motion(animation: .spring(duration: 0.5, bounce: 0.1))
        /// Photos move to new places on the sheet.
        static let rearrange = Motion(animation: .spring(duration: 0.55, bounce: 0.12))
        /// The processed background fades over the original.
        static let backgroundFade = Motion(animation: .easeInOut(duration: 0.45))
        /// A camera guide changes state (colour, not position).
        static let guideState = Motion(animation: .easeInOut(duration: 0.2))

        /// How long Photo Check shows the uncropped photo before framing it, so the push transition has settled.
        static func landingDelay(reduceMotion: Bool) -> Duration { .milliseconds(reduceMotion ? 50 : 650) }
    }
}
