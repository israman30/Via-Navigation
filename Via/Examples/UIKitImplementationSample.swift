#if canImport(UIKit)
import UIKit
import SwiftUI
import Via

// MARK: - UIKit entry point (sample)

@available(iOS 16.0, *)
/// A UIKit-first sample showing how to host Via coordinators in a `UINavigationController`.
///
/// This file intentionally demonstrates multiple patterns in one place:
/// - UIKit shell via `ViaNavigatorViewController`
/// - Auth root switching (login/signup → tab root)
/// - Tab-based navigation via `ViaTabNavigatorView`
/// - Push/pop/replace/deeplink APIs
/// - A true UIKit `present(...)` modal from within SwiftUI (via a small presenter bridge)
public enum UIKitImplementationSample {
    @MainActor
    /// Creates a ready-to-present root view controller for the sample flow.
    public static func makeRootViewController() -> UIViewController {
        ViaNavigatorViewController(coordinator: UIKitAuthCoordinator())
    }
}

// MARK: - Auth flow (UIKit shell, SwiftUI screens)

@available(iOS 16.0, *)
private enum AuthRoute: Hashable {
    case signup
    case login
}

@available(iOS 16.0, *)
@MainActor
private final class UIKitAuthCoordinator: ViaNavigator<AuthRoute> {
    @Published private(set) var isAuthenticated = false

    private let presenter = UIKitPresenterHost()
    private let tabsCoordinator = UIKitTabsCoordinator()

    override func rootView() -> AnyView {
        if isAuthenticated {
            return AnyView(
                ViaTabNavigatorView(coordinator: self.tabsCoordinator)
                    .environmentObject(presenter)
                    .overlay(alignment: .topTrailing) {
                        Button("Logout") {
                            self.isAuthenticated = false
                            self.navigateToRoot(animated: false)
                        }
                        .padding(12)
                    }
            )
        } else {
            return AnyView(
                LoginView(
                    onLogin: { [weak self] in self?.finishAuthentication() }
                )
                .environmentObject(presenter)
            )
        }
    }

    override func destinationView(for route: AuthRoute) -> AnyView {
        switch route {
        case .signup:
            AnyView(
                SignupView(
                    onSignup: { [weak self] in
                        self?.finishAuthentication()
                    }
                )
                .environmentObject(presenter)
            )
        case .login:
            AnyView(
                LoginView(
                    onLogin: { [weak self]
                        in self?.finishAuthentication()
                    }
                )
                .environmentObject(presenter)
            )
        }
    }

    private func finishAuthentication() {
        isAuthenticated = true
        navigateToRoot(animated: false)
    }
}

@available(iOS 16.0, *)
private struct LoginView: View {
    @EnvironmentObject private var coordinator: UIKitAuthCoordinator
    @EnvironmentObject private var presenter: UIKitPresenterHost

    let onLogin: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Actions") {
                    Button("Login (finish auth)") {
                        onLogin()
                    }
                    
                    Button("Go to Signup (push)") {
                        coordinator.navigate(to: .signup)
                    }
                }

                Section("Present") {
                    Button("Present Terms (modal)") {
                        presenter.present(title: "Terms") {
                            ModalSheetView(title: "Terms") {
                                Text("This is presented via UIKit `present(...)`.")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Login")
            .background(UIKitPresenterReader())
        }
    }
}

@available(iOS 16.0, *)
private struct SignupView: View {
    @EnvironmentObject private var coordinator: UIKitAuthCoordinator
    @EnvironmentObject private var presenter: UIKitPresenterHost

    let onSignup: () -> Void

    var body: some View {
        List {
            Section("Actions") {
                Button("Signup (finish auth)") {
                    onSignup()
                }
                
                Button("Back (pop)") {
                    coordinator.navigateBack()
                }
                
                Button("Back to root") {
                    coordinator.navigateToRoot()
                }
            }

            Section("Present") {
                Button("Present Privacy (modal)") {
                    presenter.present(title: "Privacy") {
                        ModalSheetView(title: "Privacy") {
                            Text("Presented modally from SwiftUI through UIKit.")
                        }
                    }
                }
            }
        }
        .navigationTitle("Signup")
        .background(UIKitPresenterReader())
    }
}

// MARK: - TabView flow (SwiftUI TabView, ViaTabNavigator APIs)

@available(iOS 16.0, *)
private enum SampleTab: Hashable {
    case feed
    case settings
}

@available(iOS 16.0, *)
private enum TabsRoute: Hashable {
    case details(id: Int)
    case about
    case editProfile
}

@available(iOS 16.0, *)
@MainActor
private final class UIKitTabsCoordinator: ViaTabNavigator<SampleTab, TabsRoute> {
    init() {
        super.init(tabs: [.feed, .settings], selectedTab: .feed)
    }

    override func rootView(for tab: SampleTab) -> AnyView {
        switch tab {
        case .feed:
            AnyView(FeedView())
        case .settings:
            AnyView(SettingsView())
        }
    }

    override func destinationView(for route: TabsRoute) -> AnyView {
        switch route {
        case .details(let id):
            AnyView(DetailsView(id: id))
        case .about:
            AnyView(AboutView())
        case .editProfile:
            AnyView(EditProfileView())
        }
    }

    override func tabItem(for tab: SampleTab) -> AnyView {
        switch tab {
        case .feed:
            AnyView(Label("Feed", systemImage: "list.bullet"))
        case .settings:
            AnyView(Label("Settings", systemImage: "gearshape"))
        }
    }
}

@available(iOS 16.0, *)
private struct FeedView: View {
    @EnvironmentObject private var coordinator: UIKitTabsCoordinator
    @EnvironmentObject private var presenter: UIKitPresenterHost

    var body: some View {
        List {
            Section("Push / pop (selected tab)") {
                Button("Push Details 1") {
                    coordinator.navigate(to: .details(id: 1))
                }
                Button("Push Details 2") {
                    coordinator.navigate(to: .details(id: 2))
                }
                Button("Pop 1") {
                    coordinator.navigateBack()
                }
                Button("Pop to root") {
                    coordinator.navigateToRoot()
                }
            }

            Section("Replace / deep link") {
                Button("Replace with About") {
                    coordinator.replace(with: .about)
                }
                Button("Set path: Details 42 → About") {
                    coordinator.setPath([.details(id: 42), .about])
                }
            }

            Section("Cross-tab navigation") {
                Button("Go to Settings + push Edit Profile") {
                    coordinator.navigate(to: .editProfile, in: .settings, animated: true, selectTab: true)
                }
            }

            Section("Present (modal)") {
                Button("Present About (modal)") {
                    presenter.present(title: "About (Modal)") {
                        ModalSheetView(title: "About") {
                            AboutView()
                        }
                    }
                }
            }
        }
        .navigationTitle("Feed")
        .background(UIKitPresenterReader())
    }
}

@available(iOS 16.0, *)
private struct SettingsView: View {
    @EnvironmentObject private var coordinator: UIKitTabsCoordinator
    @EnvironmentObject private var presenter: UIKitPresenterHost

    var body: some View {
        List {
            Section("Push / pop") {
                Button("Push Edit Profile") {
                    coordinator.navigate(to: .editProfile)
                }
                Button("Push About") {
                    coordinator.navigate(to: .about)
                }
                Button("Pop 1") {
                    coordinator.navigateBack()
                }
            }

            Section("Present (modal)") {
                Button("Present Edit Profile (modal)") {
                    presenter.present(title: "Edit Profile (Modal)") {
                        ModalSheetView(title: "Edit Profile") {
                            EditProfileView()
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .background(UIKitPresenterReader())
    }
}

@available(iOS 16.0, *)
private struct DetailsView: View {
    @EnvironmentObject private var coordinator: UIKitTabsCoordinator
    let id: Int

    var body: some View {
        List {
            Text("Details id = \(id)")
            Button("Push About") {
                coordinator.navigate(to: .about)
            }
            Button("Pop") {
                coordinator.navigateBack()
            }
            Button("Pop to root") {
                coordinator.navigateToRoot()
            }
        }
        .navigationTitle("Details")
    }
}

@available(iOS 16.0, *)
private struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Via Demo")
                .font(.title2)
            Text("This screen can be pushed or presented modally.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("About")
    }
}

@available(iOS 16.0, *)
private struct EditProfileView: View {
    var body: some View {
        List {
            Text("Edit Profile")
            Text("Pretend there are fields here.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Edit Profile")
    }
}

// MARK: - UIKit modal presenter bridge (sample-only)

@available(iOS 16.0, *)
@MainActor
/// Captures a UIKit `UIViewController` so SwiftUI can present UIKit modals.
///
/// In real apps you might replace this with your own presentation layer (router, coordinator, etc.).
private final class UIKitPresenterHost: ObservableObject {
    weak var viewController: UIViewController?

    /// Presents a SwiftUI view using UIKit's `present(...)` API.
    func present<Content: View>(title: String, @ViewBuilder content: () -> Content) {
        guard let viewController else { return }
        let hosting = UIHostingController(rootView: AnyView(content().environmentObject(self)))
        hosting.title = title
        hosting.modalPresentationStyle = .pageSheet
        viewController.present(hosting, animated: true)
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }
}

@available(iOS 16.0, *)
/// A hidden UIKit controller that allows the sample to resolve a presentation anchor.
private struct UIKitPresenterReader: UIViewControllerRepresentable {
    @EnvironmentObject private var presenter: UIKitPresenterHost

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = PresenterCaptureViewController()
        vc.onResolve = { [weak presenter] resolved in
            presenter?.viewController = resolved
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private final class PresenterCaptureViewController: UIViewController {
        var onResolve: ((UIViewController) -> Void)?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onResolve?(self)
        }
    }
}

@available(iOS 16.0, *)
private struct ModalSheetView<Content: View>: View {
    @EnvironmentObject private var presenter: UIKitPresenterHost
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                content()
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { presenter.dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

@available(iOS 16.0, *)
private struct UIKitSamplePreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIKitImplementationSample.makeRootViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

@available(iOS 16.0, *)
struct UIKitImplementationSample_Previews: PreviewProvider {
    static var previews: some View {
        UIKitSamplePreview()
    }
}
#endif
