# External Navigation

Via can open a URL outside the app in the system's default browser or URL handler.

Use external navigation for websites and external actions such as email or phone links. It does not add a route or change the current `NavigationStack`.

## Supported URLs

`ViaExternalNavigation` accepts:

- `http://...`
- `https://...`
- `mailto:...`
- `tel:...`
- Bare domains such as `github.com`, which are opened as `https://github.com`

## SwiftUI usage

From a SwiftUI view:

```swift
Button("Visit Via") {
    ViaExternalNavigation.openInBrowser("https://github.com/israman30/Via-Navigation")
}
```

You can also inspect whether the URL was accepted and handed to the system:

```swift
let opened = ViaExternalNavigation.openInBrowser("swift.org")
if !opened {
    // Invalid URL, unsupported scheme, or no system handler available.
}
```

Both URL strings and `URL` values are supported:

```swift
if let url = URL(string: "https://swift.org") {
    _ = ViaExternalNavigation.open(url)
}
```

## Coordinator usage

The standard and tab coordinators provide convenience methods:

```swift
@MainActor
final class AppCoordinator: ViaNavigator<AppRoute> {
    func visitWebsite() {
        openInBrowser("github.com")
    }
}
```

Available convenience methods:

- `openExternalURL(URL)`
- `openExternalURL(String)`
- `openInBrowser(URL)`
- `openInBrowser(String)`

Prefer `openInBrowser(...)` when a website is the intended destination. Use `openExternalURL(...)` for general system URL handling.

## Platform behavior

- **iOS/iPadOS**: uses `UIApplication.open(_:options:completionHandler:)` and hands the URL to the system.
- **macOS**: uses `NSWorkspace.open(_:)` and opens the URL in the user's default application.

The operation is no-op for unsupported URL schemes. HTTP and HTTPS domains are the primary browser-navigation use case.

## Sample

The [`ExternalNavigationSampleView`](../Via/Examples/ExternalNavigationSampleView.swift) demo includes predefined browser destinations and a custom URL/domain field.

## Source

- [`ViaExternalNavigation`](../Via/Sources/Via/ViaExternalNavigation.swift)
