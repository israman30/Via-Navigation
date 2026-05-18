# Via Documentation

This folder contains topic-focused guides for using **Via** in SwiftUI and UIKit, plus common scenarios like auth flows, tab stacks, and deep linking.

## Guides

- [SwiftUI](SwiftUI.md)
- [UIKit](UIKit.md)
- [Authentication](Authentication.md)
- [TabView](TabView.md)
- [DeepLink](DeepLink.md)
- [URLRouting](URLRouting.md)

## Source entry points

- **Core coordinators + hosts**: [`ViaNavigator` / `ViaNavigatorView` / `ViaTabNavigator` / `ViaTabNavigatorView`](../Via/Sources/Via/Via.swift)
- **UIKit host**: [`ViaNavigatorViewController`](../Via/Sources/Via/ViaNavigatorViewController.swift)
- **URL routing**: [`ViaURLRouter` / `ViaTabURLRouter`](../Via/Sources/Via/ViaURLRouting.swift)
- **Modal presentation**: [`ViaPresentation`](../Via/Sources/Via/ViaPresentation.swift)

## Samples in this repo

- **Auth flow**: [`Via/Examples/AuthImplementation.swift`](../Via/Examples/AuthImplementation.swift)
- **TabView flow**: [`Via/Examples/TabSampleView.swift`](../Via/Examples/TabSampleView.swift)
- **Deep linking**: [`Via/Examples/DeepLinkSampleView.swift`](../Via/Examples/DeepLinkSampleView.swift)
- **UIKit setup**: [`Via/Examples/UIKitSetupSample.swift`](../Via/Examples/UIKitSetupSample.swift)
- **UIKit full sample**: [`Via/Examples/UIKitImplementationSample.swift`](../Via/Examples/UIKitImplementationSample.swift)
