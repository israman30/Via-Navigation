import SwiftUI
import Via

#if DEBUG

// MARK: - Transition customization sample (Debug-only)
//
// This sample exists to demonstrate the new APIs added to Via:
// - `present(_:style:)` for modal presentation with configurable sheet detents
// - `push(_:animation:)` for transition-aware pushes (real fade in UIKit hosting)

@available(iOS 16.0, *)
public struct TransitionCustomizationSampleRootView: View {
    public init() {}

    public var body: some View {
        ViaNavigatorView(coordinator: TransitionSampleCoordinator())
    }
}

@available(iOS 16.0, *)
private enum TransitionRoute: Hashable {
    case details(index: Int)
}

@available(iOS 16.0, *)
@MainActor
private final class TransitionSampleCoordinator: ViaNavigator<TransitionRoute> {
    override func rootView() -> AnyView {
        AnyView(TransitionSampleHomeView())
    }

    override func destinationView(for route: TransitionRoute) -> AnyView {
        switch route {
        case .details(let index):
            AnyView(TransitionSampleDetailsView(index: index))
        }
    }
}

@available(iOS 16.0, *)
private struct TransitionSampleHomeView: View {
    @EnvironmentObject private var router: TransitionSampleCoordinator
    @State private var nextIndex = 1

    var body: some View {
        List {
            Section("Present") {
                Button("Present sheet (medium + large)") {
                    // Presents via the coordinator (not per-view @State).
                    // Detents are normalized internally to avoid runtime assertions.
                    router.present(
                        TransitionSampleSheetView(),
                        style: .sheet(detents: [.medium(), .large()])
                    )
                }
            }

            Section("Push") {
                Button("Push details (native)") {
                    router.push(.details(index: next()), animation: .native)
                }
                Button("Push details (fade)") {
                    // UIKit hosting (`ViaNavigatorViewController`) performs a real cross-fade push.
                    // SwiftUI hosting approximates this by animating the `path` mutation; the
                    // underlying NavigationStack transition is still controlled by the system.
                    router.push(.details(index: next()), animation: .fade)
                }
                Button("Push details (no animation)") {
                    router.push(.details(index: next()), animation: .none)
                }
            }
        }
        .navigationTitle("Transitions")
    }

    private func next() -> Int {
        defer { nextIndex += 1 }
        return nextIndex
    }
}

@available(iOS 16.0, *)
private struct TransitionSampleDetailsView: View {
    @EnvironmentObject private var router: TransitionSampleCoordinator
    let index: Int

    var body: some View {
        List {
            Text("Details \(index)")
            Button("Push next (fade)") {
                router.push(.details(index: index + 1), animation: .fade)
            }
            Button("Back") {
                router.navigateBack()
            }
        }
        .navigationTitle("Details")
    }
}

@available(iOS 16.0, *)
private struct TransitionSampleSheetView: View {
    @EnvironmentObject private var router: TransitionSampleCoordinator

    var body: some View {
        NavigationStack {
            List {
                Text("This sheet is presented via `router.present(...)`.")
                    .foregroundStyle(.secondary)
                Button("Dismiss") {
                    // Dismiss through the coordinator so both SwiftUI + UIKit hosts stay in sync.
                    router.dismissPresented()
                }
            }
            .navigationTitle("Sheet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { router.dismissPresented() }
                }
            }
        }
    }
}

// MARK: - Previews

@available(iOS 16.0, *)
struct TransitionCustomizationSampleRootView_Previews: PreviewProvider {
    static var previews: some View {
        TransitionCustomizationSampleRootView()
    }
}

#if canImport(UIKit)
import UIKit

@available(iOS 16.0, *)
private struct TransitionCustomizationUIKitHostPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        ViaNavigatorViewController(coordinator: TransitionSampleCoordinator())
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

@available(iOS 16.0, *)
struct TransitionCustomizationUIKitHostPreview_Previews: PreviewProvider {
    static var previews: some View {
        TransitionCustomizationUIKitHostPreview()
            .ignoresSafeArea()
    }
}
#endif

#endif

