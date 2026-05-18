# UIKit

Use `ViaNavigatorViewController` to host a `ViaNavigator<Route>` inside a UIKit `UINavigationController` (**iOS 13+**). Your screens can still be SwiftUI (hosted via `UIHostingController`) while UIKit owns the shell.

## Setup

- **Platform**: UIKit hosting supports **iOS 13+**.
- **Create a coordinator**: same as SwiftUI—subclass `ViaNavigator<Route>`.
- **Create the root controller**: `ViaNavigatorViewController(coordinator:)`.
- **Install at the app root**: set `window.rootViewController = ...`.

```swift
import UIKit
import Via

@MainActor
func makeRootViewController() -> UIViewController {
    ViaNavigatorViewController(coordinator: AppCoordinator())
}
```

SceneDelegate integration:

```swift
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeRootViewController()
        self.window = window
        window.makeKeyAndVisible()
    }
}
```

## Implementation

How UIKit hosting syncs state (source: [`ViaNavigatorViewController`](../Via/Sources/Via/ViaNavigatorViewController.swift)):

- **Coordinator → UIKit**: changes to `coordinator.path` push/pop view controllers.
- **UIKit → Coordinator**: interactive pops (back button / swipe-back) are detected and mirrored back into `coordinator.path`.
- **Limitations**: UIKit can’t reliably recover the original `Route` value from a view controller, so pop syncing is done by *stack depth* (see file header notes).

## Usage

Navigation calls are the same as SwiftUI hosting because your SwiftUI screens receive the coordinator via `@EnvironmentObject`:

```swift
struct SomeView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        Button("Push details") {
            coordinator.navigate(to: .details(id: "A1"))
        }
    }
}
```

### Custom push animations (UIKit host)

In UIKit hosting, `push(_:animation:)` can drive real custom transitions (source: [`ViaPushAnimation`](../Via/Sources/Via/ViaPushAnimation.swift), UIKit usage in [`ViaNavigatorViewController`](../Via/Sources/Via/ViaNavigatorViewController.swift#L125)):

```swift
coordinator.push(.details(id: "A1"), animation: .fade)
```

### Embed a Via flow inside an existing UIKit controller

If you already have a UIKit screen and want to embed a Via navigation flow as a child controller, create and add a `ViaNavigatorViewController` as a child:

```swift
final class ContainerViewController: UIViewController {
    private let via = ViaNavigatorViewController(coordinator: AppCoordinator())

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(via)
        view.addSubview(via.view)
        via.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            via.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            via.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            via.view.topAnchor.constraint(equalTo: view.topAnchor),
            via.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        via.didMove(toParent: self)
    }
}
```

## Source links

- **UIKit host**: [`ViaNavigatorViewController`](../Via/Sources/Via/ViaNavigatorViewController.swift)
- **Coordinator base class**: [`ViaNavigator`](../Via/Sources/Via/Via.swift#L74)
- **UIKit setup sample**: [`Via/Examples/UIKitSetupSample.swift`](../Via/Examples/UIKitSetupSample.swift)
- **UIKit full sample**: [`Via/Examples/UIKitImplementationSample.swift`](../Via/Examples/UIKitImplementationSample.swift)
