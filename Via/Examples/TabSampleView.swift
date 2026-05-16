import SwiftUI
import Via

// MARK: - TabView + NavigationStack sample (Debug-only)
//
// This file demonstrates the "tab flow" API:
// - A `TabView` where **each tab owns its own NavigationStack** (and therefore its own back stack).
// - A single coordinator that centralizes:
//   - tab selection (`selectedTab`)
//   - per-tab navigation state (`paths[tab]`)
//   - view construction (root + destinations)
//
// Setup overview:
// - Define `AppTab` and `AppRoute` as `Hashable` enums.
// - Subclass `ViaTabNavigator<AppTab, AppRoute>` and override:
//   - `rootView(for:)` (root per tab)
//   - `destinationView(for:)` (pushed screens)
//   - `tabItem(for:)` (tab labels)
// - Host the flow once using `ViaTabNavigatorView(coordinator:)`.

#if DEBUG
/// Entry point for the demo.
///
/// Usage:
/// - Run the `#Preview` at the bottom of the file, or
/// - Drop `TabSampleRootView()` into any SwiftUI hierarchy in a Debug build.
@available(iOS 16.0, *)
public struct TabSampleRootView: View {
    public init() {}

    public var body: some View {
        ViaTabNavigatorView(coordinator: TabCoordinator())
    }
}

/// Tabs that appear in the `TabView`.
///
/// Each tab gets its own independent navigation stack.
@available(iOS 16.0, *)
private enum AppTab: Hashable {
    case feed
    case settings
}

/// Routes that can be pushed onto a tab’s `NavigationStack`.
///
/// Routes are shared across tabs in this sample, but they don't have to be—your coordinator can
/// choose which routes are reachable from which tab.
@available(iOS 16.0, *)
private enum AppRoute: Hashable {
    case details(id: String)
    case about
}

/// Tab-based coordinator.
///
/// Implementation details:
/// - `ViaTabNavigator` maintains a separate `[Route]` per tab in `paths`.
/// - `ViaTabNavigatorView` binds each tab’s `NavigationStack(path:)` to `paths[tab]`.
/// - Switching tabs preserves each tab’s stack automatically because each tab is backed by a
///   different path array.
@available(iOS 16.0, *)
@MainActor
private final class TabCoordinator: ViaTabNavigator<AppTab, AppRoute> {
    init() {
        super.init(tabs: [.feed, .settings], selectedTab: .feed)
    }

    override func rootView(for tab: AppTab) -> AnyView {
        switch tab {
        case .feed:
            AnyView(FeedRoot())
        case .settings:
            AnyView(SettingsRoot())
        }
    }

    override func destinationView(for route: AppRoute) -> AnyView {
        switch route {
        case .details(let id):
            AnyView(DetailsView(id: id))
        case .about:
            AnyView(AboutView())
        }
    }

    override func tabItem(for tab: AppTab) -> AnyView {
        switch tab {
        case .feed:
            AnyView(Label("Feed", systemImage: "list.bullet"))
        case .settings:
            AnyView(Label("Settings", systemImage: "gearshape"))
        }
    }
}

@available(iOS 16.0, *)
private struct FeedRoot: View {
    @EnvironmentObject private var coordinator: TabCoordinator

    var body: some View {
        List {
            Section("Feed tab") {
                Button("Push details") {
                    // Push on the *current* tab's stack.
                    coordinator.navigate(to: .details(id: UUID().uuidString.prefix(6).description))
                }
            }

            Section("Cross-tab navigation") {
                Button("Open About in Settings tab") {
                    // Push on another tab’s stack and switch to it (handy for deep links).
                    coordinator.navigate(to: .about, in: .settings, selectTab: true)
                }
            }
        }
        .navigationTitle("Feed")
    }
}

@available(iOS 16.0, *)
private struct SettingsRoot: View {
    @EnvironmentObject private var coordinator: TabCoordinator

    var body: some View {
        List {
            Section("Settings tab") {
                Button("About") {
                    // Push on the *current* tab's stack.
                    coordinator.navigate(to: .about)
                }

                Button("Pop to root") {
                    // Clears only the current tab’s stack; other tabs keep their stacks intact.
                    coordinator.navigateToRoot()
                }
            }
        }
        .navigationTitle("Settings")
    }
}

@available(iOS 16.0, *)
private struct DetailsView: View {
    let id: String
    @EnvironmentObject private var coordinator: TabCoordinator

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
        }
        .padding()
        .navigationTitle("Details")
    }
}

@available(iOS 16.0, *)
private struct AboutView: View {
    @EnvironmentObject private var coordinator: TabCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("About")
                .font(.title)
                .fontWeight(.semibold)

            Text("This tab keeps its own stack.")
                .foregroundStyle(.secondary)

            Button("Back") {
                coordinator.navigateBack()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("About")
    }
}

@available(iOS 16.0, *)
struct TabSampleRootView_Previews: PreviewProvider {
    static var previews: some View {
        TabSampleRootView()
    }
}
#endif

