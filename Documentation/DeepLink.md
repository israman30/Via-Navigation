# DeepLink

Via includes a small URL router you can register patterns against and then call `handle(url:)` to apply navigation.

## Setup

1) Register patterns in your coordinator’s initializer using `urlRouter.register(...)`.
2) Call `handle(url:)` when your app receives a URL (UIKit: scene openURL; SwiftUI: `onOpenURL`).

## Implementation

Registering patterns (source: [`ViaURLRouter`](../Via/Sources/Via/ViaURLRouting.swift#L72), applying navigation in [`ViaNavigator.handle(url:)`](../Via/Sources/Via/Via.swift#L171)):

```swift
import Via

enum AppRoute: Hashable {
    case profile
    case settings
    case details(id: String)
}

@MainActor
final class AppCoordinator: ViaNavigator<AppRoute> {
    override init() {
        super.init()

        // Deep link into a multi-screen stack.
        urlRouter.register("myapp://profile/settings") { _ in
            .setPath([.profile, .settings])
        }

        // Path parameter `:id` captured into `req.pathParameters`.
        urlRouter.register("myapp://details/:id") { req in
            guard let id = req.pathParameters["id"] else { return nil }
            return .replace(with: .details(id: id))
        }
    }
}
```

### Handling incoming URLs

UIKit (SceneDelegate):

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    coordinator.handle(url: url)
}
```

SwiftUI:

```swift
SomeRootView()
    .onOpenURL { url in
        _ = coordinator.handle(url: url)
    }
```

## Usage

From anywhere you can call into your coordinator:

```swift
_ = coordinator.handle(url: "myapp://details/A1")
```

The return value is `true` if a registered pattern matched and produced navigation.

## Source links

- **URL routing types**: [`Via/Sources/Via/ViaURLRouting.swift`](../Via/Sources/Via/ViaURLRouting.swift)
- **Apply navigation**: [`ViaNavigator.handle(url:)`](../Via/Sources/Via/Via.swift#L171)
- **Sample**: [`Via/Examples/DeepLinkSampleView.swift`](../Via/Examples/DeepLinkSampleView.swift)
