// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI
import Combine

private extension ToolbarItemPlacement {
    static var viaLeading: ToolbarItemPlacement {
#if os(macOS)
        return .navigation
#else
        if #available(iOS 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            return .topBarLeading
        } else {
            return .navigationBarLeading
        }
#endif
    }
    
    static var viaTrailing: ToolbarItemPlacement {
#if os(macOS)
        return .primaryAction
#else
        if #available(iOS 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            return .topBarTrailing
        } else {
            return .navigationBarTrailing
        }
#endif
    }
}

private extension View {
    @ViewBuilder
    func viaFullScreenCoverCompat<Item: Identifiable, Cover: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Cover
    ) -> some View {
#if os(macOS)
        self
#else
        self.fullScreenCover(item: item, onDismiss: onDismiss, content: content)
#endif
    }
}

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
    public let role: ButtonRole?
    public let handler: (()->Void)?
    
    public init(title: String, role: ButtonRole? = nil, handler: (() -> Void)? = nil) {
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
    @Published var activeAlert: ViaAlertConfig?
    
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
        activeAlert = config
    }
    
    public func alert(title: String, message: String? = nil, actions: [ViaAlertAction] = [ViaAlertAction(title: "Ok")]) {
        activeAlert = ViaAlertConfig(title: title, message: message, actions: actions)
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

// MARK: - Via Stack
// The root view that wraps NavigationStack and wires everything together
public struct ViaStack<Route: ViaRoute, Content: View, Destination: View>: View {
    @StateObject private var coordinator: ViaCoordinator<Route>
    private let root: Content
    private let destination: (Route) -> Destination
    
    init(
        coordinator: ViaCoordinator<Route> = ViaCoordinator(),
        @ViewBuilder root: () -> Content,
        @ViewBuilder destination: @escaping (Route) -> Destination
    ) {
        _coordinator = StateObject(wrappedValue: coordinator)
        self.root = root()
        self.destination = destination
    }
    
    /// Init with an externally owned coordinator (injected)
    init(
        with coordinator: ViaCoordinator<Route>,
        @ViewBuilder root: () -> Content,
        @ViewBuilder destination: @escaping (Route) -> Destination
    ) {
        _coordinator = StateObject(wrappedValue: coordinator)
        self.root = root()
        self.destination = destination
    }
    
    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            root
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                        .environmentObject(coordinator)
                }
        }
        .environmentObject(coordinator)
        .sheet(item: Binding<ViaPresentationState<Route>?>(
            get: {
                guard let state = coordinator.presentedRoute, state.isSheet else { return nil }
                return state
            },
            set: { _, _ in
                coordinator.dismiss()
            }
        )) { state in
            destination(state.route)
                .environmentObject(coordinator)
        }
        .viaFullScreenCoverCompat(
            item: Binding<ViaPresentationState<Route>?>(
                get: {
                    guard let state = coordinator.presentedRoute else { return nil }
                    switch state {
                    case .fullScreen:
                        return state
                    case .sheet:
                        return nil
                    }
                },
                set: { _, _ in coordinator.dismiss() }
            )
        ) { state in
            destination(state.route)
                .environmentObject(coordinator)
        }
        alert(
            coordinator.activeAlert?.title ?? "",
            isPresented: Binding(
                get: { coordinator.activeAlert != nil },
                set: { newValue, _ in
                    if !newValue { coordinator.activeAlert = nil }
                }
            )
        ) {
            if let actions = coordinator.activeAlert?.actions {
                ForEach(actions.indices, id: \.self) { index in
                    let action = actions[index]
                    Button(action.title, role: action.role) {
                        action.handler?()
                        coordinator.activeAlert = nil
                    }
                }
            }
        } message: {
            if let message = coordinator.activeAlert?.message {
                Text(message)
            }
        }
    }
}

// // MARK: - View Extensions for View
public extension View {
    /// Inject a Via coordinator into the view hierarchy
    func viaCoordinator<Route: ViaRoute>(_ coordinator: ViaCoordinator<Route>) -> some View {
        self.environmentObject(coordinator)
    }
    
    /// Convenience: push a route
    func viaPush<Route: ViaRoute>(_ route: Route, using coordinator: ViaCoordinator<Route>) -> some View {
        self.onAppear {
            coordinator.push(route)
        }
    }
}

// // MARK: - View Property Wrapper
// Access coordinator from any view without @EnvironmentObject boilerplate
@propertyWrapper
@MainActor
public struct ViewNavigator<Route: ViaRoute>: DynamicProperty {
    @EnvironmentObject private var coordinator: ViaCoordinator<Route>
    
    public init() {}
    
    public var wrappedValue: ViaCoordinator<Route> {
        coordinator
    }
}

// MARK: - Via Deep Link Handler
public struct ViaDeeplinkHandler<Route: ViaRoute> {
    private let coordinator: ViaCoordinator<Route>
    private let parser: (URL) -> [Route]?
    
    public init(coordinator: ViaCoordinator<Route>, parser: @escaping (URL) -> [Route]?) {
        self.coordinator = coordinator
        self.parser = parser
    }
    
    // Handle an incoming URL and navigate to the resolved routes
    @MainActor
    public func handle(_ url: URL) {
        guard let routes = parser(url) else { return }
        coordinator.deepLink(routes)
    }
}

// MARK: - View Modifier for Deep Link
public extension View {

    /// Handle deep links using Helm
    func viaOnOpenURL<Route: ViaRoute>(
        coordinator: ViaCoordinator<Route>,
        parser: @escaping (URL) -> [Route]?
    ) -> some View {
        self.onOpenURL { url in
            let handler = ViaDeeplinkHandler(coordinator: coordinator, parser: parser)
            Task { handler.handle(url) }
        }
    }
}

// MARK: - View Modifier for Deep Link
public extension View {
    /// Handle deep links using Helm
    func viaBackButton<Route: ViaRoute>(coordinator: ViaCoordinator<Route>, label: String = "Back") -> some View {
        self.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    coordinator.pop()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(label)
                    }
                }
                .opacity(coordinator.canPop ? 1 : 0)
            }
        }
        .navigationBarBackButtonHidden(coordinator.canPop)
    }

    /// Add a dismiss button for sheets / full screen covers
    func viaDismissButton<Route: ViaRoute>(
        coordinator: ViaCoordinator<Route>,
        placement: ToolbarItemPlacement
    ) -> some View {
        self.toolbar {
            ToolbarItem(placement: placement) {
                Button {
                    coordinator.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
