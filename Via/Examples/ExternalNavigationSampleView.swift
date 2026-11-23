import SwiftUI
import Via

#if DEBUG
/// A SwiftUI sample showing how to open destinations outside the app.
@available(iOS 16.0, macOS 13.0, *)
public struct ExternalNavigationSampleView: View {
    public init() {}

    @State private var urlString = "https://github.com"
    @State private var lastResult: String?

    public var body: some View {
        List {
            Section("Open in the default browser") {
                Button("Open Via on GitHub") {
                    open("https://github.com")
                }

                Button("Open Apple") {
                    open("https://www.apple.com")
                }

                Button("Open Swift.org") {
                    open("https://swift.org")
                }
            }

            Section("Custom address") {
                TextField("URL or domain", text: $urlString)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif

                Button("Open address") {
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
        .navigationTitle("External Navigation")
    }

    private func open(_ value: String) {
        let opened = ViaExternalNavigation.openInBrowser(value)
        lastResult = opened ? "Opened: \(value)" : "Could not open: \(value)"
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct ExternalNavigationSampleView_Previews: PreviewProvider {
    static var previews: some View {
        ExternalNavigationSampleView()
    }
}
#endif
