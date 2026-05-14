// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
import Combine

/// `ViaNavigator` is a lightweight coordinator abstraction for SwiftUI `NavigationStack`.
///
/// It lets you keep **navigation state** and **destination view construction** in one place (a
/// coordinator), while still using SwiftUI’s native navigation container.
///
/// ## Setup
/// - **1) Define routes**: create a `Route` (typically an `enum`) that conforms to `Hashable`.
/// - **2) Subclass `ViaNavigator<Route>`**:
///   - Override `rootView()` for your entry screen.
///   - Override `destinationView(for:)` and return a view for each `Route` case.
/// - **3) Host once**: embed the coordinator in `ViaNavigatorView(coordinator:)` at your app root.
///
/// ## Implementation details
/// - `ViaNavigator` stores the stack as `@Published var path: [Route]`.
/// - `ViaNavigatorView` binds `NavigationStack(path:)` to that array.
/// - `.navigationDestination(for:)` calls back into `destinationView(for:)` to build pushed screens.
/// - The coordinator is injected via `.environmentObject`, so screens can call navigation APIs.
///
/// ## Usage (views + switch cases)
/// ```swift
/// import SwiftUI
/// import Via
///
/// enum AppRoute: Hashable { case signup, details(id: String) }
///
/// @MainActor
/// final class AppCoordinator: ViaNavigator<AppRoute> {
///     override func rootView() -> AnyView { AnyView(LoginView()) }
///     override func destinationView(for route: AppRoute) -> AnyView {
///         switch route {
///         case .signup: AnyView(SignupView())
///         case .details(let id): AnyView(DetailsView(id: id))
///         }
///     }
/// }
///
/// struct AppRoot: View {
///     var body: some View { ViaNavigatorView(coordinator: AppCoordinator()) }
/// }
///
/// struct LoginView: View {
///     @EnvironmentObject private var coordinator: AppCoordinator
///     var body: some View {
///         Button("Sign up") { coordinator.navigate(to: .signup) }
///     }
/// }
/// ```
@MainActor
public protocol Coordinating: ObservableObject {
    associatedtype Route: Hashable
    var path: [Route] { get set }
    
    /// Build the root (first) screen in the `NavigationStack`.
    func rootView() -> AnyView
    
    /// Build the destination view for a pushed route.
    func destinationView(for route: Route) -> AnyView
}

/// Base coordinator class you can subclass in your app/module.
///
/// ### Implementation notes
/// - The `path` is `[Route]` (instead of `NavigationPath`) so it can be bound directly to
///   `NavigationStack(path:)` with type safety and without type erasure.
/// - View construction returns `AnyView` to keep the API surface small and easy to override

open class ViaNavigator<Route: Hashable>: ObservableObject, Coordinating {
    @Published public var path: [Route] = []
    
    public init() {}
    
    open func rootView() -> AnyView {
        AnyView(EmptyView())
    }
    
    open func destinationView(for route: Route) -> AnyView {
        AnyView(EmptyView())
    }
    
    // MARK: - Navigation APIs
    /// Push a route onto the navigation stack.
    ///
    /// Call this from any screen that has access to the coordinator, e.g.:
    /// `@EnvironmentObject private var coordinator: MyCoordinator`.
    public func navigate(to route: Route, animated: Bool = true) {
        if animated {
            let _ = withAnimation {
                path.append(route)
            }
        } else {
            path.append(route)
        }
    }
    
    /// Replace the entire navigation stack with a new ordered list of routes.
    ///
    /// - Note: This is useful for deep-linking or restoring state.
    public func setPath(_ routes: [Route], animated: Bool = true) {
        if animated {
            let _ = withAnimation {
                path = routes
            }
        } else {
            path = routes
        }
    }
    
    /// Replace the stack with a single route.
    public func replace(with route: Route, animated: Bool = true) {
        setPath([route], animated: animated)
    }
    
    /// Pop one screen.
    public func navigateBack(animated: Bool = true) {
        guard !path.isEmpty else { return }
        if animated {
            let _ = withAnimation {
                path.removeLast()
            }
        } else {
            path.removeLast()
        }
    }
    
    /// Pop multiple screens.
    public func navigateBack(steps: Int, animated: Bool = true) {
        guard steps > 0, !path.isEmpty else { return }
        let safeSteps = min(steps, path.count)
        if animated {
            let _ = withAnimation {
                path.removeLast(safeSteps)
            }
        } else {
            path.removeLast(safeSteps)
        }
    }
    
    /// Pop back to the last occurrence of `route` in the current stack.
    ///
    /// If the route is not present, this is a no-op.
    public func popTo(_ route: Route, animated: Bool = true) {
        guard let index = path.lastIndex(of: route) else { return }
        let desiredCount = index + 1
        let toRemove = path.count - desiredCount
        guard toRemove > 0 else { return }
        navigateBack(steps: toRemove, animated: animated)
    }
    
    /// Pop all screens and return to `rootView()`.
    public func navigateToRoot(animated: Bool = true) {
        if animated {
            let _ = withAnimation {
                path.removeAll()
            }
        } else {
            path.removeAll()
        }
    }
    
}

/// A reusable `NavigationStack` host for any coordinator.
///
/// ### Usage
/// Create the coordinator once at the root, and pass it here. `ViaNavigatorView` keeps it
/// alive using `@StateObject` and injects it into the environment as an `EnvironmentObject`.
///
@MainActor
public struct ViaNavigatorView<C: Coordinating>: View {
    @StateObject private var coordinator: C
    
    public init(coordinator: @autoclosure @escaping () -> C) {
        _coordinator = StateObject(wrappedValue: coordinator())
    }
    
    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.rootView()
                .navigationDestination(for: C.Route.self) { route in
                    coordinator.destinationView(for: route)
                }
        }
        .environmentObject(coordinator)
    }
}

/// Backwards-friendly alias for the coordinator-based host view.
///
/// Prefer `ViaNavigatorView` directly.
@available(*, deprecated, message: "Use ViaNavigatorView(coordinator:) instead.")
public typealias Navigation<C: Coordinating> = ViaNavigatorView<C>
