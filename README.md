<p align="center">
  <img src="assets/via.svg" alt="Via Icon" width="200">
</p>

<p align="center">
  <strong>Via</strong> is a lightweight coordinator abstraction for iOS navigation in <code>UIKit</code> (<code>UINavigationController</code>, iOS 13+) and <code>SwiftUI</code> (<code>NavigationStack</code>, iOS 16+).
  <br>
  <em>Simplify your navigation flow by separating state from view construction.</em>
</p>

<p align="center">
  <a href="https://github.com/israman30/Via-Navigation/actions/workflows/build.yml">
    <img alt="Build" src="https://github.com/israman30/Via-Navigation/actions/workflows/build.yml/badge.svg?branch=main">
  </a>
  <img alt="iOS 13+" src="https://img.shields.io/badge/iOS-13%2B-0A84FF">
  <img alt="SwiftUI host iOS 16+" src="https://img.shields.io/badge/SwiftUI%20host-iOS%2016%2B-0A84FF">
  <img alt="Swift 6.3" src="https://img.shields.io/badge/Swift-6.3-F05138">
</p>

# ViaNavigation

## Features

- **SwiftUI NavigationStack coordinator**: typed routes + centralized destination building (iOS 16+ host)
- **UIKit hosting**: drive a `UINavigationController` from the same coordinator model (iOS 13+)
- **TabView support**: one independent navigation stack per tab (iOS 16+ host)
- **Deep links / URL routing**: pattern matching with path/query params (single-stack + tab-aware)
- **Modal presentation**: sheet detents + full screen presentation via coordinator state
- **Transition customization**: push with `.native` / `.none` / `.fade` (UIKit host supports real fade)
- **Navigation title helper**: `viaNavigationTitle(..., displayMode:)` (bridged to UIKit hosting)

## Requirements

- **iOS**: 13+ (core + UIKit host), 16+ for SwiftUI hosts (`NavigationStack` / `TabView` hosts)
- **macOS**: 13+ (SwiftUI hosts)
- **Swift tools**: 6.3 (Swift 6 toolchain)

## Installation (Swift Package Manager)

- **Package URL**: `https://github.com/israman30/Via-Navigation.git`
- **Product**: `Via`
- **Xcode**: `File → Add Package Dependencies…` → paste the URL → select product `Via`.

## Documentation

Detailed setup, implementation, and usage live in [`Documentation/`](Documentation/README.md):

- **SwiftUI**: [`Documentation/SwiftUI.md`](Documentation/SwiftUI.md)
- **UIKit**: [`Documentation/UIKit.md`](Documentation/UIKit.md)
- **Authentication**: [`Documentation/Authentication.md`](Documentation/Authentication.md)
- **TabView**: [`Documentation/TabView.md`](Documentation/TabView.md)
- **DeepLink**: [`Documentation/DeepLink.md`](Documentation/DeepLink.md)
- **URLRouting**: [`Documentation/URLRouting.md`](Documentation/URLRouting.md)

## Examples / Preview

This repo includes a demo target you can run in Xcode:

- **Scheme/target**: `ViaDemoUI`
- **Screens**:
  - [`Via/Examples/SampleView.swift`](Via/Examples/SampleView.swift)
  - [`Via/Examples/AuthImplementation.swift`](Via/Examples/AuthImplementation.swift)
  - [`Via/Examples/TabSampleView.swift`](Via/Examples/TabSampleView.swift)
  - [`Via/Examples/DeepLinkSampleView.swift`](Via/Examples/DeepLinkSampleView.swift)
  - [`Via/Examples/UIKitSetupSample.swift`](Via/Examples/UIKitSetupSample.swift)
  - [`Via/Examples/UIKitImplementationSample.swift`](Via/Examples/UIKitImplementationSample.swift)

## Debugging / Troubleshooting

If you hit errors like **"No such module ..."** (or the package builds in isolation but fails in your app), try these in order.

### 1) The "Magic" reset

Before diving into settings, clear cached build data which can get corrupted:

- **Clean Build Folder**: press Command + Shift + K.
- **Nuke Derived Data**: go to Xcode Settings → Locations, click the small arrow next to the Derived Data path, and delete the contents of that folder.
- **Restart Xcode**: sometimes the IDE just needs a fresh start to re-index modules.

### 2) Verify target membership

The library might be added to the project but not assigned to the target you’re building (App, Unit Tests, etc.):

- Select your project in the Project Navigator.
- Select your Target (e.g., your app name).
- Go to the General tab.
- Scroll to **Frameworks, Libraries, and Embedded Content**.
- If your module isn’t listed, click **+** and add it.

### 3) Dependency-specific fixes

- **Swift Package Manager (SPM)**: go to File → Packages → Update to Latest Package Versions. If you’re on Xcode 16+, try disabling **Explicitly Built Modules** in Build Settings if errors persist.
- **CocoaPods**: ensure you’re opening the `.xcworkspace` file (not the `.xcodeproj`). Run `pod install` if you recently changed your `Podfile`.
- **Unit tests**: if the error is in a test file, ensure your main app target has **Enable Testability** set to **Yes** in Build Settings.

### 4) Check for naming conflicts

Ensure your project name is not identical to the module you’re trying to import (for example, naming your project “Firebase” and then trying to `import Firebase`). This can create a circular dependency that confuses the compiler.

## Contribution policy

Contributions are welcome.

- **Before you start**: open an issue describing the bug/feature and the intended approach.
- **Branching**: create a feature branch from `main` (or the default branch).
- **Code style**: keep changes small and focused; prefer clarity over cleverness.
- **Examples**: if you change the navigation API, update the demos in [`Via/Examples/`](Via/Examples/).
- **Verification**: ensure the package builds and the previews in `ViaDemoUI` still work.
- **PRs**: include a short summary and a minimal test plan (even if it’s “Run Preview X”).

## License

There is currently **no license file** in this repository. Until a license is added, reuse and redistribution are not granted by default (see copyright below).

## Copyright

Copyright (c) 2026 Israel Manzo and contributors. All rights reserved.