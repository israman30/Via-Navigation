import Foundation
import SwiftUI

/// Supported push animations.
///
/// - Note: In SwiftUI (`NavigationStack`) Apple controls the actual push transition.
///   Via uses this value to choose the `withAnimation(...)` used when mutating `path`, and to
///   drive UIKit push transitions when hosted in `ViaNavigatorViewController`.
public enum ViaPushAnimation: Sendable, Equatable {
    /// Use the platform default push animation.
    case native
    /// Perform the push without animation.
    case none
    /// Cross-fade between screens (supported in UIKit hosting; approximated in SwiftUI).
    case fade

    var swiftUIAnimation: Animation? {
        switch self {
        case .native:
            return .default
        case .none:
            return nil
        case .fade:
            return .easeInOut(duration: 0.25)
        }
    }
}

