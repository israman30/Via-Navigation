import SwiftUI

public enum ViaNavigationTitleDisplayMode: Sendable {
    case automatic
    case inline
    case large
}

public struct ViaNavigationTitleModifier: ViewModifier {
    public let title: String
    public let displayMode: ViaNavigationTitleDisplayMode

    public init(title: String, displayMode: ViaNavigationTitleDisplayMode = .automatic) {
        self.title = title
        self.displayMode = displayMode
    }

    public func body(content: Content) -> some View {
#if os(iOS)
        if #available(iOS 14.0, *) {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(displayMode._toSwiftUITitleDisplayMode)
        } else {
            content.navigationBarTitle(title, displayMode: displayMode._toSwiftUITitleDisplayMode)
        }
#else
        // macOS doesn't support iOS-style large/inline navigation bar titles.
        content.navigationTitle(title)
#endif
    }
}

#if os(iOS)
private extension ViaNavigationTitleDisplayMode {
    var _toSwiftUITitleDisplayMode: NavigationBarItem.TitleDisplayMode {
        switch self {
        case .automatic: .automatic
        case .inline: .inline
        case .large: .large
        }
    }
}
#endif

public extension View {
    /// Set a navigation title and optionally override its display mode.
    ///
    /// - Parameters:
    ///   - title: Navigation title text.
    ///   - displayMode: Title display mode (`.inline`, `.large`, or `.automatic`).
    func viaNavigationTitle(
        _ title: String,
        displayMode: ViaNavigationTitleDisplayMode = .automatic
    ) -> some View {
        modifier(ViaNavigationTitleModifier(title: title, displayMode: displayMode))
    }
}

