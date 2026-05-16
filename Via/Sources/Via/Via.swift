// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
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
    /// URL router for deep links/app links.
    ///
    /// Register patterns in your coordinator’s initializer and then call `handle(url:)` when your
    /// app receives a URL (e.g. `scene(_:openURLContexts:)` in UIKit or `onOpenURL` in SwiftUI).
    public let urlRouter = ViaURLRouter<Route>()
    
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

    /// Handle a deep link URL by resolving it through `urlRouter`.
    ///
    /// Returns `true` if a registered pattern matched and produced navigation.
    ///
    /// Navigation behavior:
    /// - `.setPath`: replaces the entire stack.
    /// - `.push`: appends routes in order.
    /// - `.replace`: replaces with a single route. If the handler returns multiple routes with
    ///   `.replace`, Via will fall back to `.setPath` (so deep links can still drive a flow).
    @discardableResult
    public func handle(url: URL, animated: Bool = true) -> Bool {
        guard let match = urlRouter.resolve(url) else { return false }

        switch match.navigation.mode {
        case .setPath:
            setPath(match.navigation.routes, animated: animated)
        case .push:
            for route in match.navigation.routes {
                navigate(to: route, animated: animated)
            }
        case .replace:
            if let first = match.navigation.routes.first, match.navigation.routes.count == 1 {
                replace(with: first, animated: animated)
            } else {
                setPath(match.navigation.routes, animated: animated)
            }
        }
        return true
    }

    /// Convenience overload for `handle(url:)`.
    @discardableResult
    public func handle(url: String, animated: Bool = true) -> Bool {
        guard let u = URL(string: url) else { return false }
        return handle(url: u, animated: animated)
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
@available(iOS 16.0, macOS 13.0, *)
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

// MARK: - TabView support

/// A coordinator protocol for tab-based apps where each tab maintains its own navigation stack.
@MainActor
public protocol TabCoordinating: ObservableObject {
    associatedtype Tab: Hashable
    associatedtype Route: Hashable

    /// Tabs that should be rendered in the `TabView`, in order.
    var tabs: [Tab] { get }

    /// The currently selected tab.
    var selectedTab: Tab { get set }

    /// Per-tab navigation stacks (one `[Route]` per tab).
    var paths: [Tab: [Route]] { get set }

    /// Build the root (first) screen for a given tab.
    func rootView(for tab: Tab) -> AnyView

    /// Build the destination view for a pushed route.
    func destinationView(for route: Route) -> AnyView

    /// Build the tab item label for a given tab.
    ///
    /// This is used inside `.tabItem { ... }`.
    func tabItem(for tab: Tab) -> AnyView
}

/// Base coordinator class for apps using `TabView` + one `NavigationStack` per tab.
///
/// Each tab has its own independent `[Route]` path, so switching tabs preserves each tab’s stack.
open class ViaTabNavigator<Tab: Hashable, Route: Hashable>: ObservableObject, TabCoordinating {
    public let tabs: [Tab]
    @Published public var selectedTab: Tab
    @Published public var paths: [Tab: [Route]]
    /// URL router for tab-aware deep links/app links.
    ///
    /// Register patterns in your coordinator’s initializer and return `ViaTabURLNavigation` to
    /// choose the target tab and how routes should be applied.
    public let urlRouter = ViaTabURLRouter<Tab, Route>()

    public init(tabs: [Tab], selectedTab: Tab) {
        self.tabs = tabs
        self.selectedTab = selectedTab

        var initial: [Tab: [Route]] = [:]
        for tab in tabs {
            initial[tab] = []
        }
        self.paths = initial
    }

    open func rootView(for tab: Tab) -> AnyView {
        AnyView(EmptyView())
    }

    open func destinationView(for route: Route) -> AnyView {
        AnyView(EmptyView())
    }

    open func tabItem(for tab: Tab) -> AnyView {
        AnyView(EmptyView())
    }

    // MARK: - Tab APIs

    public func select(tab: Tab, animated: Bool = true) {
        if animated {
            let _ = withAnimation { selectedTab = tab }
        } else {
            selectedTab = tab
        }
    }

    /// Handle a deep link URL by resolving it through `urlRouter`.
    ///
    /// Returns `true` if a registered pattern matched and produced navigation.
    ///
    /// Tab behavior:
    /// - If the navigation specifies a `tab` and `selectTab == true`, Via will switch to that tab
    ///   before applying navigation.
    /// - If `tab` is `nil`, the current `selectedTab` is used.
    @discardableResult
    public func handle(url: URL, animated: Bool = true) -> Bool {
        guard let match = urlRouter.resolve(url) else { return false }
        let nav = match.navigation

        let targetTab = nav.tab ?? selectedTab
        if nav.tab != nil, nav.selectTab {
            select(tab: targetTab, animated: animated)
        }

        switch nav.mode {
        case .setPath:
            setPath(nav.routes, in: targetTab, animated: animated, selectTab: false)
        case .push:
            for route in nav.routes {
                navigate(to: route, in: targetTab, animated: animated, selectTab: false)
            }
        case .replace:
            if let first = nav.routes.first, nav.routes.count == 1 {
                replace(with: first, in: targetTab, animated: animated, selectTab: false)
            } else {
                setPath(nav.routes, in: targetTab, animated: animated, selectTab: false)
            }
        }
        return true
    }

    /// Convenience overload for `handle(url:)`.
    @discardableResult
    public func handle(url: String, animated: Bool = true) -> Bool {
        guard let u = URL(string: url) else { return false }
        return handle(url: u, animated: animated)
    }

    // MARK: - Navigation APIs (selected tab)

    public func navigate(to route: Route, animated: Bool = true) {
        navigate(to: route, in: selectedTab, animated: animated, selectTab: false)
    }

    public func setPath(_ routes: [Route], animated: Bool = true) {
        setPath(routes, in: selectedTab, animated: animated, selectTab: false)
    }

    public func replace(with route: Route, animated: Bool = true) {
        replace(with: route, in: selectedTab, animated: animated, selectTab: false)
    }

    public func navigateBack(animated: Bool = true) {
        navigateBack(in: selectedTab, animated: animated, selectTab: false)
    }

    public func navigateBack(steps: Int, animated: Bool = true) {
        navigateBack(in: selectedTab, steps: steps, animated: animated, selectTab: false)
    }

    public func popTo(_ route: Route, animated: Bool = true) {
        popTo(route, in: selectedTab, animated: animated, selectTab: false)
    }

    public func navigateToRoot(animated: Bool = true) {
        navigateToRoot(in: selectedTab, animated: animated, selectTab: false)
    }

    // MARK: - Navigation APIs (specific tab)

    /// Push a route onto a specific tab’s navigation stack.
    ///
    /// - Parameters:
    ///   - selectTab: If `true`, this will switch the UI to the target tab before pushing.
    public func navigate(to route: Route, in tab: Tab, animated: Bool = true, selectTab: Bool = true) {
        if selectTab { select(tab: tab, animated: animated) }
        if animated {
            let _ = withAnimation {
                paths[tab, default: []].append(route)
            }
        } else {
            paths[tab, default: []].append(route)
        }
    }

    /// Replace a tab’s entire navigation stack with a new ordered list of routes.
    public func setPath(_ routes: [Route], in tab: Tab, animated: Bool = true, selectTab: Bool = true) {
        if selectTab { select(tab: tab, animated: animated) }
        if animated {
            let _ = withAnimation {
                paths[tab] = routes
            }
        } else {
            paths[tab] = routes
        }
    }

    public func replace(with route: Route, in tab: Tab, animated: Bool = true, selectTab: Bool = true) {
        setPath([route], in: tab, animated: animated, selectTab: selectTab)
    }

    public func navigateBack(in tab: Tab, animated: Bool = true, selectTab: Bool = true) {
        if selectTab { select(tab: tab, animated: animated) }
        guard let current = paths[tab], !current.isEmpty else { return }
        if animated {
            let _ = withAnimation {
                paths[tab]?.removeLast()
            }
        } else {
            paths[tab]?.removeLast()
        }
    }

    public func navigateBack(in tab: Tab, steps: Int, animated: Bool = true, selectTab: Bool = true) {
        if selectTab { select(tab: tab, animated: animated) }
        guard steps > 0, let current = paths[tab], !current.isEmpty else { return }
        let safeSteps = min(steps, current.count)
        if animated {
            let _ = withAnimation {
                paths[tab]?.removeLast(safeSteps)
            }
        } else {
            paths[tab]?.removeLast(safeSteps)
        }
    }

    public func popTo(_ route: Route, in tab: Tab, animated: Bool = true, selectTab: Bool = true) {
        if selectTab { select(tab: tab, animated: animated) }
        guard let current = paths[tab], let index = current.lastIndex(of: route) else { return }
        let desiredCount = index + 1
        let toRemove = current.count - desiredCount
        guard toRemove > 0 else { return }
        navigateBack(in: tab, steps: toRemove, animated: animated, selectTab: false)
    }

    public func navigateToRoot(in tab: Tab, animated: Bool = true, selectTab: Bool = true) {
        if selectTab { select(tab: tab, animated: animated) }
        if animated {
            let _ = withAnimation {
                paths[tab]?.removeAll()
            }
        } else {
            paths[tab]?.removeAll()
        }
    }
}

/// A `TabView` host for any tab-based coordinator.
///
/// It renders one `NavigationStack` per tab and binds each stack to its tab-specific `[Route]` path.
@available(iOS 16.0, macOS 13.0, *)
@MainActor
public struct ViaTabNavigatorView<C: TabCoordinating>: View {
    @StateObject private var coordinator: C

    public init(coordinator: @autoclosure @escaping () -> C) {
        _coordinator = StateObject(wrappedValue: coordinator())
    }

    public var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ForEach(coordinator.tabs, id: \.self) { tab in
                NavigationStack(path: pathBinding(for: tab)) {
                    coordinator.rootView(for: tab)
                        .navigationDestination(for: C.Route.self) { route in
                            coordinator.destinationView(for: route)
                        }
                }
                .tag(tab)
                .tabItem { coordinator.tabItem(for: tab) }
            }
        }
        .environmentObject(coordinator)
    }

    private func pathBinding(for tab: C.Tab) -> Binding<[C.Route]> {
        Binding(
            get: { coordinator.paths[tab] ?? [] },
            set: { coordinator.paths[tab] = $0 }
        )
    }
}

/// Backwards-friendly alias for the coordinator-based host view.
///
/// Prefer `ViaNavigatorView` directly.
@available(iOS 16.0, macOS 13.0, *)
@available(*, deprecated, message: "Use ViaNavigatorView(coordinator:) instead.")
public typealias Navigation<C: Coordinating> = ViaNavigatorView<C>
