import SwiftUI
import Via

#if DEBUG
/// A SwiftUI demo that fetches users from JSONPlaceholder and pushes user details.
@available(iOS 16.0, macOS 13.0, *)
public struct JSONPlaceholderSampleView: View {
    public init() {}

    public var body: some View {
        ViaNavigatorView(coordinator: JSONPlaceholderCoordinator())
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct JSONPlaceholderUser: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let phone: String
    let website: String
    let address: JSONPlaceholderAddress
    let company: JSONPlaceholderCompany
}

@available(iOS 16.0, macOS 13.0, *)
private struct JSONPlaceholderAddress: Codable, Hashable {
    let street: String
    let suite: String
    let city: String
    let zipcode: String
}

@available(iOS 16.0, macOS 13.0, *)
private struct JSONPlaceholderCompany: Codable, Hashable {
    let name: String
    let catchPhrase: String
    let bs: String
}

@available(iOS 16.0, macOS 13.0, *)
private enum JSONPlaceholderRoute: Hashable {
    case user(JSONPlaceholderUser)
}

@available(iOS 16.0, macOS 13.0, *)
@MainActor
private final class JSONPlaceholderCoordinator: ViaNavigator<JSONPlaceholderRoute> {
    override func rootView() -> AnyView {
        AnyView(JSONPlaceholderUsersView())
    }

    override func destinationView(for route: JSONPlaceholderRoute) -> AnyView {
        switch route {
        case .user(let user):
            AnyView(JSONPlaceholderUserDetailView(user: user))
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct JSONPlaceholderUsersView: View {
    @EnvironmentObject private var coordinator: JSONPlaceholderCoordinator
    @State private var users: [JSONPlaceholderUser] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && users.isEmpty {
                ProgressView("Loading users…")
            } else if let errorMessage, users.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("Unable to Load Users")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List(users) { user in
                    Button {
                        coordinator.navigate(to: .user(user))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.headline)
                                Text("@\(user.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .refreshable {
                    await fetchUsers()
                }
            }
        }
        .navigationTitle("Users")
        .task {
            await fetchUsers()
        }
        .toolbar {
            Button("Reload") {
                Task { await fetchUsers() }
            }
            .disabled(isLoading)
        }
    }

    private func fetchUsers() async {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/users") else { return }

        isLoading = true
        errorMessage = nil

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            users = try JSONDecoder().decode([JSONPlaceholderUser].self, from: data)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct JSONPlaceholderUserDetailView: View {
    let user: JSONPlaceholderUser
    @EnvironmentObject private var coordinator: JSONPlaceholderCoordinator

    var body: some View {
        List {
            Section("Contact") {
                Label(user.email, systemImage: "envelope")
                Label(user.phone, systemImage: "phone")
                Label(user.website, systemImage: "globe")
            }

            Section("Address") {
                Text("\(user.address.suite) \(user.address.street)")
                Text("\(user.address.city) \(user.address.zipcode)")
            }

            Section("Company") {
                Text(user.company.name)
                    .font(.headline)
                Text("\"\(user.company.catchPhrase)\"")
                Text(user.company.bs)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Push this user again") {
                    coordinator.navigate(to: .user(user))
                }

                Button("Back") {
                    coordinator.navigateBack()
                }

                Button("Pop to users") {
                    coordinator.navigateToRoot()
                }
            }
        }
        .navigationTitle(user.name)
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct JSONPlaceholderSampleView_Previews: PreviewProvider {
    static var previews: some View {
        JSONPlaceholderSampleView()
    }
}
#endif
