# SwiftUI

Use `ViaNavigator<Route>` to keep navigation state and route-to-view mapping in a single coordinator, while still using SwiftUI’s native `NavigationStack`.

## Setup

- **Platform**: SwiftUI host requires **iOS 16+** (or macOS 13+).
- **Define routes**: create a `Route` type (usually an `enum`) that conforms to `Hashable`.
- **Create a coordinator**: subclass `ViaNavigator<Route>` and override `rootView()` and `destinationView(for:)`.
- **Host once**: wrap your app root in `ViaNavigatorView(coordinator:)`.

```swift
import SwiftUI
import Via

enum AppRoute: Hashable {
    case details(id: String)
    case settings
}

@MainActor
final class AppCoordinator: ViaNavigator<AppRoute> {
    override func rootView() -> AnyView {
        AnyView(HomeView())
    }

    override func destinationView(for route: AppRoute) -> AnyView {
        switch route {
        case .details(let id):
            AnyView(DetailsView(id: id))
        case .settings:
            AnyView(SettingsView())
        }
    }
}

struct AppRoot: View {
    var body: some View {
        ViaNavigatorView(coordinator: AppCoordinator())
    }
}
```

## Implementation

- **Navigation state**: `ViaNavigator` owns `@Published var path: [Route]` (source: [`ViaNavigator`](../Via/Sources/Via/Via.swift#L74)).
- **Navigation host**: `ViaNavigatorView` binds `NavigationStack(path:)` to the coordinator’s `path` (source: [`ViaNavigatorView`](../Via/Sources/Via/Via.swift#L259)).
- **Dependency injection**: the coordinator is injected as an `EnvironmentObject`, so screens can call navigation APIs.

## Usage

From any screen:

```swift
struct HomeView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        List {
            Button("Open details") {
                coordinator.navigate(to: .details(id: "A1"))
            }
            Button("Settings") {
                coordinator.navigate(to: .settings)
            }
        }
        .viaNavigationTitle("Home", displayMode: .large)
    }
}
```

Common navigation APIs (source: [`ViaNavigator` APIs](../Via/Sources/Via/Via.swift#L97)):

- `navigate(to:animated:)`
- `navigateBack(animated:)` / `navigateBack(steps:animated:)`
- `navigateToRoot(animated:)`
- Deep-link helpers: `setPath(_:animated:)`, `replace(with:animated:)`, `handle(url:animated:)`

## Source links

- **SwiftUI host**: [`ViaNavigatorView`](../Via/Sources/Via/Via.swift#L259)
- **Coordinator base class**: [`ViaNavigator`](../Via/Sources/Via/Via.swift#L74)
- **Navigation title helper**: [`viaNavigationTitle`](../Via/Sources/Via/ViaNavigationTitleModifier.swift#L55)
- **Sample**: [`Via/Examples/SampleView.swift`](../Via/Examples/SampleView.swift)
