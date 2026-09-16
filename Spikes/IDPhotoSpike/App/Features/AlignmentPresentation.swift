import Foundation
import SwiftUI

/// User-facing wording for alignment checks. Status is conveyed by symbol and text, never colour alone.
enum AlignmentPresentation {
    static func symbol(for state: CheckState) -> String {
        switch state {
        case .pass: "checkmark.circle"
        case .warn: "exclamationmark.triangle"
        case .fail: "xmark.octagon"
        case .manualCheck: "eye"
        }
    }

    static func title(for state: CheckState) -> LocalizedStringResource {
        switch state {
        case .pass: "Aligned automatically"
        case .warn: "Aligned, please review"
        case .fail: "Automatic alignment needs a better photo"
        case .manualCheck: "Aligned, one item needs your judgement"
        }
    }

    static func message(for check: AlignmentCheck) -> LocalizedStringResource {
        let value = check.measured ?? 0
        switch (check.kind, check.state) {
        case (.faceCount, .fail):
            return value == 0 ? "No face was found. Choose a front-facing portrait." : "More than one face was found. Use a photo with one person."
        case (.faceCount, _): return "One face found"
        case (.resolution, .pass): return "Enough detail for printing"
        case (.resolution, .warn): return "Face detail is limited; a closer photo prints sharper"
        case (.resolution, _): return "The face is too small in this photo. Move closer or choose a higher-resolution photo."
        case (.roll, .pass): return abs(value) > 0.5 ? "Eyes levelled (\(Int(abs(value).rounded()))° tilt corrected)" : "Eyes level"
        case (.roll, _): return "Head is tilted \(Int(abs(value).rounded()))°. Keep your head straight and retake."
        case (.yaw, .pass): return "Facing the camera"
        case (.yaw, _): return "Head is turned sideways. Face the camera directly."
        case (.pitch, .pass): return "Camera at eye level"
        case (.pitch, _): return "Camera is above or below eye level. Hold it at eye height."
        case (.headHeight, .pass): return "Head fills \(Int((value * 100).rounded()))% of the photo"
        case (.headHeight, .warn): return "Head fills \(Int((value * 100).rounded()))% of the photo, near the limit"
        case (.headHeight, _): return "Head fills \(Int((value * 100).rounded()))% of the photo; adjust zoom or retake"
        case (.eyeLine, .pass): return "Eyes at \(Int((value * 100).rounded()))% from the top"
        case (.eyeLine, _): return "Eye position is \(Int((value * 100).rounded()))% from the top, outside the usual range"
        case (.centering, .pass): return "Face centred"
        case (.centering, _): return "Face is off-centre"
        case (.crown, .pass): return "Top of head found"
        case (.crown, .manualCheck): return "Hair or headwear rises above the head. Check the crop by eye."
        case (.crown, _): return "Top of head estimated from face proportions"
        case (.headroom, .fail): return "The top of the head is cut off in this photo. Retake with space above the head."
        case (.headroom, .pass): return "Space above the head"
        case (.headroom, _): return "Little space above the head"
        case (.zoomRange, .pass): return "Crop within zoom range"
        case (.zoomRange, _): return "The photo would need more zoom than the editor allows"
        }
    }
}
