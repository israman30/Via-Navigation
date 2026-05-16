import Foundation
import SwiftUI

/// A type-erased presentation request driven by a coordinator.
///
/// `ViaNavigatorView` and `ViaNavigatorViewController` observe this value to present/dismiss
/// SwiftUI views modally (sheet or full screen).
public struct ViaPresentation: Identifiable {
    public let id: UUID
    public var style: ViaPresentationStyle
    public var content: AnyView
    public var animated: Bool

    public init(id: UUID = UUID(), style: ViaPresentationStyle, content: AnyView, animated: Bool = true) {
        self.id = id
        self.style = style
        self.content = content
        self.animated = animated
    }
}

/// Supported modal presentation styles.
public enum ViaPresentationStyle: Sendable, Equatable {
    case sheet(detents: [ViaSheetDetent] = [.large])
    case fullScreen
}

/// A cross-platform representation of SwiftUI `PresentationDetent` / UIKit sheet detents.
public enum ViaSheetDetent: Sendable, Equatable {
    case medium
    case large
    case fraction(Double)
    case height(Double)

    // Convenience constructors to match SwiftUI’s call sites (e.g. `.medium()` / `.large()`).
    public static func medium() -> Self { .medium }
    public static func large() -> Self { .large }
}

@MainActor
public protocol ViaPresentationCoordinating: AnyObject {
    var presented: ViaPresentation? { get set }
}

// MARK: - Mapping helpers

extension ViaSheetDetent {
    /// Returns a normalized detent list safe to feed into SwiftUI/UIKit APIs.
    ///
    /// - Important: Both SwiftUI and UIKit sheet APIs may assert/crash if you provide an empty
    ///   detents list or invalid values (NaN/∞/out-of-range).
    static func _normalized(_ detents: [ViaSheetDetent]) -> [ViaSheetDetent] {
        let cleaned = detents.map { $0._sanitized() }
        return cleaned.isEmpty ? [.large] : cleaned
    }

    fileprivate func _sanitized() -> ViaSheetDetent {
        switch self {
        case .medium, .large:
            return self
        case .fraction(let raw):
            guard raw.isFinite else { return .large }
            // SwiftUI expects 0...1. Avoid 0 which can trigger assertions.
            let clamped = max(0.01, min(1.0, raw))
            return .fraction(clamped)
        case .height(let raw):
            guard raw.isFinite else { return .large }
            // Avoid non-positive heights which can trigger assertions.
            return .height(max(1.0, raw))
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
extension ViaSheetDetent {
    func toSwiftUIDetent() -> PresentationDetent {
        switch self {
        case .medium:
            return .medium
        case .large:
            return .large
        case .fraction(let value):
            return .fraction(value)
        case .height(let value):
            return .height(value)
        }
    }
}

#if canImport(UIKit)
import UIKit

extension ViaSheetDetent {
    @MainActor
    @available(iOS 15.0, *)
    func toUIKitDetent() -> UISheetPresentationController.Detent {
        switch self._sanitized() {
        case .medium:
            return .medium()
        case .large:
            return .large()
        case .fraction(let value):
            if #available(iOS 16.0, *) {
                return .custom(identifier: .init("via.fraction.\(value)")) { @MainActor context in
                    // Avoid 0 which can lead to assertions/odd behavior.
                    max(0.01, min(1, value)) * context.maximumDetentValue
                }
            } else {
                // Custom detents are not available until iOS 16.
                return .large()
            }
        case .height(let value):
            if #available(iOS 16.0, *) {
                return .custom(identifier: .init("via.height.\(value)")) { @MainActor _ in
                    max(1, value)
                }
            } else {
                // Custom detents are not available until iOS 16.
                return .large()
            }
        }
    }
}
#endif

