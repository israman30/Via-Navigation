# Authentication

Via works well for auth flows when you treat authentication as **root selection** (login vs authenticated home), and keep `Route` for screens pushed on top of that root.

## Setup

- Define an auth route enum for pushed screens (e.g. `.signup`).
- Store auth state in the coordinator (e.g. `@Published private(set) var isAuthenticated = false`).
- In `rootView()`, return either the unauthenticated root or the authenticated root based on state.

## Implementation

Minimal pattern:

```swift
import SwiftUI
import Via

private enum AuthRoute: Hashable { case signup }

@MainActor
final class AuthCoordinator: ViaNavigator<AuthRoute> {
    @Published private(set) var isAuthenticated = false

    override func rootView() -> AnyView {
        isAuthenticated ? AnyView(HomeView()) : AnyView(LoginView())
    }

    override func destinationView(for route: AuthRoute) -> AnyView {
        switch route {
        case .signup:
            AnyView(SignupView())
        }
    }

    func finishAuthentication() {
        isAuthenticated = true
        // Clear the stack so the new root appears immediately (no pop animation fighting the swap).
        navigateToRoot(animated: false)
    }

    func logout() {
        isAuthenticated = false
        navigateToRoot(animated: false)
    }
}
```

## Usage

From your screens (provided the coordinator via `@EnvironmentObject`):

```swift
struct LoginView: View {
    @EnvironmentObject private var coordinator: AuthCoordinator

    var body: some View {
        List {
            Button("Create account") { coordinator.navigate(to: .signup) }
            Button("Login (success)") { coordinator.finishAuthentication() }
        }
        .navigationTitle("Login")
    }
}
```

## Source links

- **Auth sample (SwiftUI host)**: [`Via/Examples/AuthImplementation.swift`](../Via/Examples/AuthImplementation.swift)
- **Auth sample (UIKit host + tabs + modals)**: [`Via/Examples/UIKitImplementationSample.swift`](../Via/Examples/UIKitImplementationSample.swift#L25)
- **Coordinator base class + APIs**: [`ViaNavigator`](../Via/Sources/Via/Via.swift#L74)
