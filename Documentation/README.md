# Via Documentation

This folder contains topic-focused guides for using **Via** in SwiftUI and UIKit, plus common scenarios like auth flows, tab stacks, and deep linking.

<p>
  <img alt="iOS 13+" src="https://img.shields.io/badge/iOS-13%2B-0A84FF">
  <img alt="SwiftUI host iOS 16+" src="https://img.shields.io/badge/SwiftUI%20host-iOS%2016%2B-0A84FF">
  <img alt="Swift 6.3" src="https://img.shields.io/badge/Swift-6.3-F05138">
</p>

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
