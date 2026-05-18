# TabView

For tab-based apps, `ViaTabNavigator<Tab, Route>` provides **one independent navigation stack per tab** (one `[Route]` path per tab), while keeping navigation decisions centralized.

## Setup

- **Platform**: SwiftUI tab host requires **iOS 16+** (or macOS 13+).
- Define `Tab` and `Route` as `Hashable` (typically enums).
- Subclass `ViaTabNavigator<Tab, Route>` and override:
  - `rootView(for:)` (root per tab)
  - `destinationView(for:)` (pushed destinations)
  - `tabItem(for:)` (tab labels)
- Host once using `ViaTabNavigatorView(coordinator:)`.

```swift
import SwiftUI
import Via

enum AppTab: Hashable { case feed, settings }
enum AppRoute: Hashable { case details(id: String), about }

@MainActor
final class AppCoordinator: ViaTabNavigator<AppTab, AppRoute> {
    init() {
        super.init(tabs: [.feed, .settings], selectedTab: .feed)
    }

    override func rootView(for tab: AppTab) -> AnyView {
        switch tab {
        case .feed: AnyView(FeedView())
        case .settings: AnyView(SettingsView())
        }
    }

    override func destinationView(for route: AppRoute) -> AnyView {
        switch route {
        case .details(let id): AnyView(DetailsView(id: id))
        case .about: AnyView(AboutView())
        }
    }

    override func tabItem(for tab: AppTab) -> AnyView {
        switch tab {
        case .feed: AnyView(Label("Feed", systemImage: "list.bullet"))
        case .settings: AnyView(Label("Settings", systemImage: "gearshape"))
        }
    }
}

struct AppRoot: View {
    var body: some View {
        ViaTabNavigatorView(coordinator: AppCoordinator())
    }
}
```

## Implementation

Key properties (source: [`ViaTabNavigator`](../Via/Sources/Via/Via.swift#L315)):

- `selectedTab`: binds to `TabView(selection:)`
- `paths[tab]`: stores each tab’s independent navigation stack

`ViaTabNavigatorView` renders one `NavigationStack` per tab and binds each stack to `paths[tab]` (source: [`ViaTabNavigatorView`](../Via/Sources/Via/Via.swift#L549)).

## Usage

Push/pop on the currently selected tab:

```swift
coordinator.navigate(to: .details(id: "A1"))
coordinator.navigateBack()
coordinator.navigateToRoot()
```

Cross-tab navigation (optionally switching the UI to that tab):

```swift
coordinator.navigate(to: .about, in: .settings, selectTab: true)
```

## Source links

- **Tab coordinator base class**: [`ViaTabNavigator`](../Via/Sources/Via/Via.swift#L315)
- **Tab host**: [`ViaTabNavigatorView`](../Via/Sources/Via/Via.swift#L549)
- **Sample**: [`Via/Examples/TabSampleView.swift`](../Via/Examples/TabSampleView.swift)
