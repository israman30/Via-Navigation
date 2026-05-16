import SwiftUI
import Via

// MARK: - Deep link / URL routing sample (Debug-only)

#if DEBUG
/// A small demo showing how to register URL patterns and drive navigation via `handle(url:)`.
///
/// - Register routes in your coordinator’s initializer using `urlRouter.register(...)`.
/// - Apply navigation by calling `coordinator.handle(url:)` (e.g. from `onOpenURL`).
///
/// Tip:
/// - In real apps, you’d typically call `handle(url:)` from `scene(_:openURLContexts:)` (UIKit) or
///   `onOpenURL` (SwiftUI). This sample also includes buttons to simulate incoming URLs.
@available(iOS 16.0, *)
public struct DeepLinkSampleRootView: View {
    public init() {}

    public var body: some View {
        ViaNavigatorView(coordinator: DeepLinkCoordinator())
    }
}

@available(iOS 16.0, *)
private enum DeepLinkRoute: Hashable {
    case profile
    case profileSettings
    case details(id: String)
}

@available(iOS 16.0, *)
@MainActor
private final class DeepLinkCoordinator: ViaNavigator<DeepLinkRoute> {
    override init() {
        super.init()

        // Deep link into a flow by setting a multi-screen stack.
        urlRouter.register("myapp://profile/settings") { _ in
            .setPath([.profile, .profileSettings])
        }

        // Path parameters: `:id` is available in `req.pathParameters`.
        urlRouter.register("myapp://details/:id") { req in
            guard let id = req.pathParameters["id"] else { return nil }
            return .replace(with: .details(id: id))
        }

        // You can also choose to "push" without resetting the stack.
        urlRouter.register("myapp://push/details/:id") { req in
            guard let id = req.pathParameters["id"] else { return nil }
            return .push([.details(id: id)])
        }
    }

    override func rootView() -> AnyView {
        AnyView(DeepLinkHome())
    }

    override func destinationView(for route: DeepLinkRoute) -> AnyView {
        switch route {
        case .profile:
            AnyView(ProfileView())
        case .profileSettings:
            AnyView(ProfileSettingsView())
        case .details(let id):
            AnyView(DetailsView(id: id))
        }
    }
}

@available(iOS 16.0, *)
private struct DeepLinkHome: View {
    @EnvironmentObject private var coordinator: DeepLinkCoordinator
    @State private var urlString: String = "myapp://profile/settings"
    @State private var lastResult: String?

    var body: some View {
        List {
            Section("Simulate incoming deep links") {
                Button("Open profile settings (setPath)") {
                    open("myapp://profile/settings")
                }

                Button("Open details A1 (replace)") {
                    open("myapp://details/A1")
                }

                Button("Push details B2 (push)") {
                    open("myapp://push/details/B2")
                }
            }

            Section("Try a URL") {
                TextField("myapp://…", text: $urlString)
                #if os(iOS)
                    // These input modifiers aren’t available on macOS in this toolchain,
                    // but the sample builds for macOS as well (package platform support).
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                #endif

                Button("Handle URL") {
                    open(urlString)
                }
            }

            if let lastResult {
                Section("Last result") {
                    Text(lastResult)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Deep links")
        .onOpenURL { url in
            // Typical SwiftUI integration: receive an incoming URL and route it.
            let handled = coordinator.handle(url: url)
            lastResult = handled ? "Handled: \(url.absoluteString)" : "Not handled: \(url.absoluteString)"
        }
    }

    private func open(_ url: String) {
        let handled = coordinator.handle(url: url)
        lastResult = handled ? "Handled: \(url)" : "Not handled: \(url)"
    }
}

@available(iOS 16.0, *)
private struct ProfileView: View {
    @EnvironmentObject private var coordinator: DeepLinkCoordinator

    var body: some View {
        List {
            Section("Profile") {
                Button("Settings") { coordinator.navigate(to: .profileSettings) }
                Button("Details random") { coordinator.navigate(to: .details(id: UUID().uuidString.prefix(6).description)) }
            }
        }
        .navigationTitle("Profile")
    }
}

@available(iOS 16.0, *)
private struct ProfileSettingsView: View {
    @EnvironmentObject private var coordinator: DeepLinkCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("Profile Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Button("Back") { coordinator.navigateBack() }
                .buttonStyle(.bordered)

            Button("Pop to root") { coordinator.navigateToRoot() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Settings")
    }
}

@available(iOS 16.0, *)
private struct DetailsView: View {
    @EnvironmentObject private var coordinator: DeepLinkCoordinator
    let id: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Details \(id)")
                .font(.title2)
                .fontWeight(.semibold)

            Button("Push another details") {
                coordinator.navigate(to: .details(id: UUID().uuidString.prefix(6).description))
            }
            .buttonStyle(.borderedProminent)

            Button("Back") { coordinator.navigateBack() }
                .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("Details")
    }
}

@available(iOS 16.0, *)
struct DeepLinkSampleRootView_Previews: PreviewProvider {
    static var previews: some View {
        DeepLinkSampleRootView()
    }
}
#endif

