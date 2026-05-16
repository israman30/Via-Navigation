#if canImport(UIKit)
import UIKit
import SwiftUI
import Via

// MARK: - Minimal UIKit setup sample

@available(iOS 16.0, *)
/// A minimal UIKit-first sample showing the smallest possible setup:
/// `UIWindow(windowScene:)` → `UINavigationController` → `SomeViewController`.
public enum UIKitSetupSample {
    @MainActor
    public static func makeRootViewController() -> UIViewController {
        UINavigationController(rootViewController: SomeViewController())
    }
}

// MARK: - SceneDelegate (copy/paste sample)

@available(iOS 16.0, *)
/// Copy/paste sample for UIKit apps that use a scene-based lifecycle.
///
/// Note: It’s named `UIKitSetupSceneDelegate` to avoid colliding with your app’s own `SceneDelegate`.
public final class UIKitSetupSceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?

    public func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIKitSetupSample.makeRootViewController()
        self.window = window
        window.makeKeyAndVisible()
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
private struct UIKitSetupSamplePreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIKitSetupSample.makeRootViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Via coordinator (sample embedded in UIKit)

@available(iOS 16.0, *)
private enum SomeRoute: Hashable {
    case detail(id: Int)
}

@available(iOS 16.0, *)
@MainActor
private final class SomeCoordinator: ViaNavigator<SomeRoute> {
    override func rootView() -> AnyView {
        AnyView(SomeRootView())
    }

    override func destinationView(for route: SomeRoute) -> AnyView {
        switch route {
        case .detail(let id):
            AnyView(SomeDetailView(id: id))
        }
    }
}

@available(iOS 16.0, *)
private struct SomeRootView: View {
    @EnvironmentObject private var coordinator: SomeCoordinator

    var body: some View {
        SomeTableViewControllerHost(coordinator: coordinator)
            .navigationTitle("Items")
    }
}

@available(iOS 16.0, *)
private struct SomeDetailView: View {
    @EnvironmentObject private var coordinator: SomeCoordinator
    let id: Int

    var body: some View {
        List {
            Text("Detail id = \(id)")
            Button("Pop") {
                coordinator.navigateBack()
            }
            Button("Pop to root") {
                coordinator.navigateToRoot()
            }
        }
        .navigationTitle("Detail")
    }
}

@available(iOS 16.0, *)
private struct SomeTableViewControllerHost: UIViewControllerRepresentable {
    @ObservedObject var coordinator: SomeCoordinator

    func makeUIViewController(context: Context) -> UITableViewController {
        SomeItemsTableViewController(coordinator: coordinator)
    }

    func updateUIViewController(_ uiViewController: UITableViewController, context: Context) {}
}

@available(iOS 16.0, *)
@MainActor
private final class SomeItemsTableViewController: UITableViewController {
    private let coordinator: SomeCoordinator
    private let items: [Int] = Array(1...20)

    init(coordinator: SomeCoordinator) {
        self.coordinator = coordinator
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.allowsSelection = true
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let id = items[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = "Item \(id)"
        config.secondaryText = "Tap to navigate via Via"
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = items[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        coordinator.navigate(to: .detail(id: id))
    }
}

@available(iOS 16.0, *)
public final class SomeViewController: UIViewController {
    private let coordinator = SomeCoordinator()
    private var hostingController: UIViewController?

    public override func viewDidLoad() {
        super.viewDidLoad()

        title = "Some"
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)

        let root = ViaNavigatorView(coordinator: self.coordinator)
        let hosting = UIHostingController(rootView: AnyView(root.environmentObject(coordinator)))

        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting
    }
}

@available(iOS 16.0, *)
#Preview("UIKit Setup Sample") {
    UIKitSetupSamplePreview()
}
#endif

