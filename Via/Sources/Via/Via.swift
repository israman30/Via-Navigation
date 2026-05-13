// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI
import Combine

public protocol ViaRoute: Hashable, Identifiable {
    
}

public extension ViaRoute {
    var id: Int { hashValue }
}

public protocol ViaDestination {
    associatedtype Route: ViaRoute
    associatedtype Content: View
    
    @ViewBuilder
    func destination(for route: Route) -> Content
}

// MARK: - Via Transition
public enum ViaTransition {
    case push
    case sheet
    case fullScreen
    case alert(ViaAlertConfig)
    case custom // AnyTransition
}

// MARK: - Via Alert Config
public struct ViaAlertConfig {
    public let title: String
    public let message: String?
    public let actions: [ViaAlertAction] // [HelmAlertAction]
    
    public init(title: String, message: String?, actions: [ViaAlertAction] = [ViaAlertAction(title: "OK")]) {
        self.title = title
        self.message = message
        self.actions = actions
    }
}

// MARK: - Via Alert Action
public struct ViaAlertAction {
    public let title: String
    public let role: String? // ButtonRole?
    public let handler: (()->Void)?
    
    public init(title: String, role: String? = nil, handler: (() -> Void)? = nil) {
        self.title = title
        self.role = role
        self.handler = handler
    }
}

enum ViaPresentationState<Route: ViaRoute>: Identifiable {
    case sheet(Route)
    case fullScreen(Route)
    
    var id: String {
        switch self {
        case .sheet(let route):
            return "sheet-\(route)"
        case .fullScreen(let route):
            return "fullScren-\(route)"
        }
    }
    
    var route: Route {
        switch self {
        case .sheet(let route):
            return route
        case .fullScreen(let route):
            return route
        }
    }
    
    var isSheet: Bool {
        if case .sheet = self {
            return true
        }
        return false
    }
}


// MARK: - Via Coordinator
@MainActor
public class ViaCoordinator<Route: ViaRoute>: ObservableObject {
    @Published public var path: NavigationPath = NavigationPath()
    @Published var presentedRoute: ViaPresentationState<Route>?
    @Published var activateAlert: ViaAlertConfig?
    
    private var routeHistory: [Route] = []
    private var onDismissCallbacks: [String: () -> Void] = [:]
    
    public init() {}
    
    public func push(_ route: Route) {
        path.append(route)
        routeHistory.append(route)
    }
    
    public func push(_ routes: [Route]) {
        routes.forEach { push($0) }
    }
    
    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
        routeHistory.removeLast()
    }
    
    /// Pop to a specific route in the stack
    public func pop(ro route: Route) {
        guard let index = routeHistory.firstIndex(of: route) else { return }
        let stepToRemove = routeHistory.count - index - 1
        guard stepToRemove > 0 else { return }
        path.removeLast(stepToRemove)
        routeHistory = Array(routeHistory.prefix(index + 1))
    }
    
    public func popToRoot() {
        path = NavigationPath()
        routeHistory.removeAll()
    }
    
    // MARK: - Present Sheet
    public func sheet(_ route: Route, onDismiss: (() -> Void)? = nil) {
        if let onDismiss {
            onDismissCallbacks["sheet\(route.id)"] = onDismiss
        }
        presentedRoute = .sheet(route)
    }
    
    public func fullScreen(_ route: Route, onDismiss: (() -> Void)? = nil) {
        if let onDismiss {
            onDismissCallbacks["fullscreen-\(route.id)"] = onDismiss
        }
        presentedRoute = .fullScreen(route)
    }
    
    // MARK: - Dismiss
    /// Dismiss the currently presented sheet or fullscreen
    public func dismiss() {
        if let current = presentedRoute {
            onDismissCallbacks[current.id]?()
            onDismissCallbacks.removeValue(forKey: current.id)
        }
        presentedRoute = nil
    }
    
    // MARK: - Alert
    /// Show an alert
    public func alert(_ config: ViaAlertConfig) {
        activateAlert = config
    }
    
    public func alert(title: String, message: String? = nil, actions: [ViaAlertAction] = [ViaAlertAction(title: "Ok")]) {
        activateAlert = ViaAlertConfig(title: title, message: message, actions: actions)
    }
    
    // MARK: - Navigate (combined)
    public func navigate(to route: Route, via transition: ViaTransition) {
        switch transition {
        case .push:
            push(route)
        case .sheet:
            sheet(route)
        case .fullScreen:
            fullScreen(route)
        case .alert(let config):
            alert(config)
        case .custom:
            push(route) // fallback to push for custom
        }
    }
    
    // MARK: - Deep Link
    public func deepLink(_ routes: [Route]) {
        popToRoot()
        push(routes)
    }
    
    // MARK: - Stack Info
    public var stackDepth: Int {
        routeHistory.count
    }
    
    public var canPop: Bool {
        !path.isEmpty
    }
    
    public var currentRole: Route? {
        routeHistory.last
    }
}

// MARK: - Via Environment Key
private struct ViaCoordinatorKey: EnvironmentKey {
    static var defaultValue: AnyObject? { nil }
}

fileprivate extension EnvironmentValues {
    var _viaCoordinator: AnyObject? {
        get { self[ViaCoordinatorKey.self] }
        set { self[ViaCoordinatorKey.self] = newValue }
    }
}

public extension EnvironmentValues {
    /// Access the Via coordinator from any view in the hierarchy (type-safe cast).
    func viaCoordinator<Route: ViaRoute>(for type: Route.Type) -> ViaCoordinator<Route>? {
        _viaCoordinator as? ViaCoordinator<Route>
    }
}

// MARK: - Via Environment Modifier
struct ViewEnvironmentModifier<Route: ViaRoute>: ViewModifier {
    let coordinator: ViaCoordinator<Route>
    
    func body(content: Content) -> some View {
        content
            .environment(\._viaCoordinator, coordinator as AnyObject)
            .environmentObject(coordinator)
    }
}

