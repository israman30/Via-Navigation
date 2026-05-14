#if canImport(UIKit)
import UIKit
import SwiftUI
import Combine

@available(iOS 16.0, *)
@MainActor
/// A UIKit host for `ViaNavigator` that drives a `UINavigationController`.
///
/// This is useful for UIKit-first apps (or incremental migrations) that still want to keep
/// navigation decisions in a `ViaNavigator` coordinator.
///
/// ## How it works
/// - **Coordinator → UIKit**: changes to `coordinator.path` push/pop view controllers.
/// - **UIKit → Coordinator**: interactive pops (back button / swipe-back) are observed via
///   `UINavigationControllerDelegate` and mirrored back into `coordinator.path`.
///
/// ## Limitations
/// UIKit does not expose a reliable way to recover the original `Route` value from an arbitrary
/// view controller. This implementation therefore syncs pops by stack *depth* and assumes the
/// visible controller stack corresponds to the prefix of `path`.
public final class ViaNavigatorViewController<Route: Hashable, C: ViaNavigator<Route>>: UIViewController, UINavigationControllerDelegate {
    public let coordinator: C

    private let navController = UINavigationController()
    private var cancellable: AnyCancellable?

    private var rootViewController: UIViewController?
    private var currentPath: [Route] = []
    private var isSyncing = false

    /// Creates the host controller and instantiates the coordinator once.
    ///
    /// Pass the same concrete coordinator type your SwiftUI screens expect via `@EnvironmentObject`.
    public init(coordinator: @autoclosure @escaping () -> C) {
        self.coordinator = coordinator()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        navController.delegate = self
        embed(navigationController: navController)

        let root = makeRootViewController()
        rootViewController = root
        navController.setViewControllers([root], animated: false)

        currentPath = coordinator.path
        apply(path: coordinator.path, animated: false)

        cancellable = coordinator.$path
            .removeDuplicates()
            .sink { [weak self] newPath in
                guard let self else { return }
                guard !self.isSyncing else {
                    self.currentPath = newPath
                    return
                }
                self.apply(path: newPath, animated: true)
            }
    }

    private func makeRootViewController() -> UIViewController {
        let view = ViaUIKitRootView(coordinator: coordinator)
            .environmentObject(coordinator)
        return UIHostingController(rootView: AnyView(view))
    }

    private func makeDestinationViewController(for route: Route) -> UIViewController {
        let view = ViaUIKitDestinationView(coordinator: coordinator, route: route)
            .environmentObject(coordinator)
        return UIHostingController(rootView: AnyView(view))
    }

    private func apply(path newPath: [Route], animated: Bool) {
        guard let rootViewController else { return }

        isSyncing = true
        defer { isSyncing = false }

        let oldPath = currentPath

        if newPath.count >= oldPath.count, Array(newPath.prefix(oldPath.count)) == oldPath {
            let toPush = newPath.dropFirst(oldPath.count)
            for route in toPush {
                navController.pushViewController(makeDestinationViewController(for: route), animated: animated)
            }
        } else if oldPath.count >= newPath.count, Array(oldPath.prefix(newPath.count)) == newPath {
            let targetIndex = newPath.count
            if navController.viewControllers.indices.contains(targetIndex) {
                let target = navController.viewControllers[targetIndex]
                navController.popToViewController(target, animated: animated)
            } else {
                navController.setViewControllers([rootViewController] + newPath.map(makeDestinationViewController(for:)), animated: false)
            }
        } else {
            navController.setViewControllers([rootViewController] + newPath.map(makeDestinationViewController(for:)), animated: false)
        }

        currentPath = newPath
    }

    private func embed(navigationController: UINavigationController) {
        addChild(navigationController)
        view.addSubview(navigationController.view)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationController.view.topAnchor.constraint(equalTo: view.topAnchor),
            navigationController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        navigationController.didMove(toParent: self)
    }

    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard navigationController === navController else { return }
        guard !isSyncing else { return }

        // We can’t reliably recover `Route` values from view controllers, but we *can* detect pops
        // (including interactive back-swipe) by comparing the visible stack depth to `path.count`.
        let shownRouteCount = max(0, navController.viewControllers.count - 1)
        let desired = Array(coordinator.path.prefix(shownRouteCount))

        guard desired != coordinator.path else { return }

        isSyncing = true
        currentPath = desired
        coordinator.path = desired
        isSyncing = false
    }
}

@available(iOS 16.0, *)
private struct ViaUIKitRootView<C: Coordinating>: View {
    @ObservedObject var coordinator: C

    var body: some View {
        coordinator.rootView()
    }
}

@available(iOS 16.0, *)
private struct ViaUIKitDestinationView<C: Coordinating>: View {
    @ObservedObject var coordinator: C
    let route: C.Route

    var body: some View {
        coordinator.destinationView(for: route)
    }
}
#endif
