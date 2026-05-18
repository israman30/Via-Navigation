# URLRouting

This guide describes Via’s URL routing primitives: how patterns match, what request data you get, and how navigation is represented for both single-stack and tab-based coordinators.

## Setup

- **Single stack** (`ViaNavigator`): use `ViaURLRouter<Route>` via `coordinator.urlRouter` and return `ViaURLNavigation<Route>`.
- **Tabs** (`ViaTabNavigator`): use `ViaTabURLRouter<Tab, Route>` via `coordinator.urlRouter` and return `ViaTabURLNavigation<Tab, Route>`.

Register patterns in your coordinator’s initializer:

```swift
urlRouter.register("myapp://details/:id") { req in
    guard let id = req.pathParameters["id"] else { return nil }
    return .replace(with: .details(id: id))
}
```

## Implementation

### Pattern format

Patterns are matched in **registration order** (first match wins).

Supported formats (source: [`ViaURLRouter.register`](../Via/Sources/Via/ViaURLRouting.swift#L83)):

- `myapp://profile/settings`
- `myapp:///profile/:section`
- `https://example.com/profile/:id`
- `/profile/:id` (path-only; matches any scheme/host)

Rules (source: [`ViaURLPattern`](../Via/Sources/Via/ViaURLRouting.swift#L258)):

- `:param` captures a single path segment into `req.pathParameters["param"]`
- `*` matches the remainder of the path (no parameters captured from it)
- For non-HTTP schemes (`myapp://...`), the **host is treated as the first path segment**
  (e.g. `myapp://profile/settings` → segments `["profile", "settings"]`)

### Request data available to handlers

Handlers receive a `ViaURLRequest` (source: [`ViaURLRequest`](../Via/Sources/Via/ViaURLRouting.swift#L35)):

- `pathParameters`: captures from `:param` segments
- `queryParameters`: parsed from `?key=value`
- `fragment`: parsed from `#fragment`
- `parameters`: merged view of query + path params (path params win on collisions)

### Navigation representations

Single-stack navigation type: `ViaURLNavigation<Route>` (source: [`ViaURLNavigation`](../Via/Sources/Via/ViaURLRouting.swift#L7)):

- `.setPath([Route])`: replace the entire stack
- `.push([Route])`: append routes to the existing stack
- `.replace(with: Route)`: replace with a single route

Tab-aware navigation type: `ViaTabURLNavigation<Tab, Route>` (source: [`ViaTabURLNavigation`](../Via/Sources/Via/ViaURLRouting.swift#L133)):

- `tab`: target tab (or `nil` to use current `selectedTab`)
- `selectTab`: whether to switch UI to `tab` before applying navigation
- `mode`: `.setPath` / `.push` / `.replace`
- `routes`: ordered route list to apply

## Usage

### Single stack

Call `handle(url:)` (source: [`ViaNavigator.handle(url:)`](../Via/Sources/Via/Via.swift#L171)):

```swift
let handled = coordinator.handle(url: URL(string: "myapp://details/A1")!)
```

### Tabs

Register tab-aware routes (choose a tab and whether to switch to it):

```swift
urlRouter.register("myapp://settings/about") { _ in
    .push(tab: .settings, [.about], selectTab: true)
}
```

Then call `handle(url:)` on your `ViaTabNavigator` (source: [`ViaTabNavigator.handle(url:)`](../Via/Sources/Via/Via.swift#L363)):

```swift
_ = tabsCoordinator.handle(url: "myapp://settings/about")
```

## Source links

- **Router implementation + patterns**: [`Via/Sources/Via/ViaURLRouting.swift`](../Via/Sources/Via/ViaURLRouting.swift)
- **Single-stack application**: [`ViaNavigator.handle(url:)`](../Via/Sources/Via/Via.swift#L171)
- **Tab application**: [`ViaTabNavigator.handle(url:)`](../Via/Sources/Via/Via.swift#L363)
- **Deep link sample**: [`Via/Examples/DeepLinkSampleView.swift`](../Via/Examples/DeepLinkSampleView.swift)
