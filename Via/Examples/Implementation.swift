import SwiftUI
import Via

// MARK: - Coordinator Sample (Debug-only)

#if DEBUG
/// A small demo that showcases the coordinator pattern end-to-end.
///
/// - **Root**: the entry point. It creates the coordinator and hosts `CoordinatorView`.
/// - **Main**: the coordinator’s `rootView()`.
/// - **Details / Settings**: destination screens pushed via `Route`.
///
/// This is compiled only in Debug builds to avoid shipping demo types in Release.
///
/// ### Run it
/// - Open `CoordinatorSampleRootView` in the preview at the bottom of this file, or
/// - Drop `CoordinatorSampleRootView()` into any SwiftUI hierarchy in a Debug build.

public struct CoordinatorSampleRootView: View {
    public init() {}

    public var body: some View {
        CoordinatorView(coordinator: RootCoordinator())
    }
}

@MainActor
private final class RootCoordinator: Coordinator<Route> {
    override func rootView() -> AnyView {
        AnyView(Main())
    }

    override func destinationView(for route: Route) -> AnyView {
        switch route {
        case .details(let id):
            AnyView(Details(id: id))
        case .settings:
            AnyView(Settings())
        }
    }
}

/// Routes that can be pushed onto the navigation stack.
private enum Route: Hashable {
    case details(id: String)
    case settings
}

/// Main screen for the sample (this is the coordinator’s `rootView()`).
private struct Main: View {
    @EnvironmentObject private var coordinator: RootCoordinator

    var body: some View {
        List {
            Section("Navigation") {
                Button("Push details") {
                    coordinator.navigate(to: .details(id: UUID().uuidString.prefix(6).description))
                }

                Button("Push settings") {
                    coordinator.navigate(to: .settings)
                }

                Button("Replace stack with 3 details") {
                    coordinator.setPath([
                        .details(id: "A1"),
                        .details(id: "B2"),
                        .details(id: "C3")
                    ])
                }
            }
        }
        .navigationTitle("Main")
    }
}

/// Destination screen for `.details`.
private struct Details: View {
    let id: String
    @EnvironmentObject private var coordinator: RootCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("Details")
                .font(.title)
                .fontWeight(.semibold)

            Text("ID: \(id)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button("Push another details") {
                coordinator.navigate(to: .details(id: UUID().uuidString.prefix(6).description))
            }
            .buttonStyle(.borderedProminent)

            Button("Back") {
                coordinator.navigateBack()
            }
            .buttonStyle(.bordered)

            Button("Pop to root") {
                coordinator.navigateToRoot()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("Details")
    }
}

/// Destination screen for `.settings`.
private struct Settings: View {
    @EnvironmentObject private var coordinator: RootCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.title)
                .fontWeight(.semibold)

            Button("Back") {
                coordinator.navigateBack()
            }
            .buttonStyle(.bordered)

            Button("Pop to root") {
                coordinator.navigateToRoot()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Settings")
    }
}

struct CoordinatorSampleRootView_Previews: PreviewProvider {
    static var previews: some View {
        CoordinatorSampleRootView()
    }
}
#endif
