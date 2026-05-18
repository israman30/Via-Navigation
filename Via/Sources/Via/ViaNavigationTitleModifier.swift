import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

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
                .background(ViaUIKitNavigationTitleBridge(title: title, displayMode: displayMode))
        } else {
            // iOS 13 SwiftUI can't control inline/large title mode reliably.
            // We still set the title so UIKit-hosted flows (and SwiftUI) show it.
            content
                .navigationBarTitle(title)
                .background(ViaUIKitNavigationTitleBridge(title: title, displayMode: displayMode))
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

#if canImport(UIKit)
/// Bridges `viaNavigationTitle` into UIKit-driven navigation stacks.
///
/// In UIKit hosts (e.g. `ViaNavigatorViewController`), screens are pushed as `UIHostingController`s
/// without a SwiftUI `NavigationStack`, so SwiftUI's `.navigationTitle(...)` does not reliably
/// populate the UIKit navigation bar title. This bridge sets `navigationItem.title` directly.
@MainActor
private struct ViaUIKitNavigationTitleBridge: UIViewControllerRepresentable {
    let title: String
    let displayMode: ViaNavigationTitleDisplayMode

    func makeUIViewController(context: Context) -> UIViewController {
        ViaNavigationTitleBridgeViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let bridge = uiViewController as? ViaNavigationTitleBridgeViewController else { return }
        bridge.titleText = title
        bridge.displayMode = displayMode
        bridge.applyIfPossible()
    }
}

@MainActor
private final class ViaNavigationTitleBridgeViewController: UIViewController {
    var titleText: String = ""
    var displayMode: ViaNavigationTitleDisplayMode = .automatic

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyIfPossible()
    }

    func applyIfPossible() {
        guard let target = _viaNearestNavigationItemHost() else { return }
        if target.navigationItem.title != titleText {
            target.navigationItem.title = titleText
        }
        target.navigationItem.largeTitleDisplayMode = displayMode._toUIKitLargeTitleDisplayMode
    }

    private func _viaNearestNavigationItemHost() -> UIViewController? {
        // The representable's controller is inserted as a child of the actual hosting controller.
        // We walk up until we find a controller that participates in a UINavigationController stack.
        var current: UIViewController? = self
        while let vc = current {
            if vc.navigationController != nil {
                return vc
            }
            current = vc.parent
        }
        return nil
    }
}

private extension ViaNavigationTitleDisplayMode {
    var _toUIKitLargeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        switch self {
        case .automatic: .automatic
        case .inline: .never
        case .large: .always
        }
    }
}
#endif
