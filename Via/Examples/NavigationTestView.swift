import SwiftUI
import Via

#if DEBUG
/// A SwiftUI test screen for exercising all core navigation operations.
///
/// Open `NavigationTestView` in an Xcode preview to try pushes, replacement, stack
/// replacement, and back/root navigation.
@available(iOS 16.0, macOS 13.0, *)
public struct NavigationTestView: View {
    public init() {}

    public var body: some View {
        ViaNavigatorView(coordinator: NavigationTestCoordinator())
    }
}

@available(iOS 16.0, macOS 13.0, *)
private enum NavigationTestRoute: Hashable {
    case details(id: String)
    case settings
}

@available(iOS 16.0, macOS 13.0, *)
@MainActor
private final class NavigationTestCoordinator: ViaNavigator<NavigationTestRoute> {
    override func rootView() -> AnyView {
        AnyView(NavigationTestHome())
    }

    override func destinationView(for route: NavigationTestRoute) -> AnyView {
        switch route {
        case .details(let id):
            AnyView(NavigationTestDetails(id: id))
        case .settings:
            AnyView(NavigationTestSettings())
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct NavigationTestHome: View {
    @EnvironmentObject private var coordinator: NavigationTestCoordinator

    var body: some View {
        List {
            Section("Push") {
                Button("Push details") {
                    coordinator.navigate(to: .details(id: "A1"))
                }

                Button("Push settings") {
                    coordinator.navigate(to: .settings)
                }
            }

            Section("Replace") {
                Button("Replace with details") {
                    coordinator.replace(with: .details(id: "B2"))
                }

                Button("Set path to details + settings") {
                    coordinator.setPath([
                        .details(id: "C3"),
                        .settings
                    ])
                }

                Button("Set path without animation") {
                    coordinator.setPath([.details(id: "D4")], animated: false)
                }
            }

            Section("Reset") {
                Button("Pop to root") {
                    coordinator.navigateToRoot()
                }

                Button("Clear stack") {
                    coordinator.setPath([])
                }
            }
        }
        .navigationTitle("Navigation Test")
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct NavigationTestDetails: View {
    let id: String
    @EnvironmentObject private var coordinator: NavigationTestCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("Details")
                .font(.title)
                .fontWeight(.semibold)

            Text("ID: \(id)")
                .foregroundStyle(.secondary)

            Button("Push details") {
                coordinator.navigate(to: .details(id: UUID().uuidString.prefix(6).description))
            }
            .buttonStyle(.borderedProminent)

            Button("Replace with settings") {
                coordinator.replace(with: .settings)
            }

            Button("Back") {
                coordinator.navigateBack()
            }

            Button("Pop to root") {
                coordinator.navigateToRoot()
            }
        }
        .padding()
        .navigationTitle("Details")
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct NavigationTestSettings: View {
    @EnvironmentObject private var coordinator: NavigationTestCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.title)
                .fontWeight(.semibold)

            Button("Push details") {
                coordinator.navigate(to: .details(id: "E5"))
            }
            .buttonStyle(.borderedProminent)

            Button("Back") {
                coordinator.navigateBack()
            }

            Button("Pop to root") {
                coordinator.navigateToRoot()
            }
        }
        .padding()
        .navigationTitle("Settings")
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct NavigationTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationTestView()
    }
}
#endif
