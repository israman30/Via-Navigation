#if canImport(UIKit)
import UIKit
import SwiftUI

// MARK: - Minimal UIKit setup sample

@available(iOS 16.0, *)
/// A minimal UIKit-first sample showing the smallest possible setup:
/// `UIWindow(windowScene:)` → `UINavigationController` → `SomeViewController`.
public enum UIKitSetupSample {
    @MainActor
    public static func makeRootViewController() -> UIViewController {
        UINavigationController(rootViewController: SomeViewController())
    }
}

// MARK: - SceneDelegate (copy/paste sample)

@available(iOS 16.0, *)
/// Copy/paste sample for UIKit apps that use a scene-based lifecycle.
///
/// Note: It’s named `UIKitSetupSceneDelegate` to avoid colliding with your app’s own `SceneDelegate`.
public final class UIKitSetupSceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?

    public func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIKitSetupSample.makeRootViewController()
        self.window = window
        window.makeKeyAndVisible()
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
private struct UIKitSetupSamplePreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIKitSetupSample.makeRootViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

public final class SomeViewController: UIViewController {
    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = "This is SomeViewController"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Some"
        view.backgroundColor = .systemBackground

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])
    }
}

@available(iOS 16.0, *)
#Preview("UIKit Setup Sample") {
    UIKitSetupSamplePreview()
}
#endif

