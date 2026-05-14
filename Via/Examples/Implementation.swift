import SwiftUI
import Via

// MARK: - Login / Signup flow (Debug-only demo)

#if DEBUG

/// A small auth flow demo:
/// - Root: `LoginView`
/// - Push: `SignupView`
/// - After success: `HomeView` replaces the root
public struct AuthFlowRootView: View {
    public init() {}

    public var body: some View {
        ViaNavigatorView(coordinator: AuthCoordinator())
    }
}

private enum AuthRoute: Hashable {
    case signup
}

@MainActor
private final class AuthCoordinator: ViaNavigator<AuthRoute> {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentEmail: String?

    override func rootView() -> AnyView {
        if isAuthenticated {
            AnyView(HomeView(email: currentEmail ?? "user@example.com"))
        } else {
            AnyView(LoginView())
        }
    }

    override func destinationView(for route: AuthRoute) -> AnyView {
        switch route {
        case .signup:
            AnyView(SignupView())
        }
    }

    func finishAuthentication(email: String) {
        currentEmail = email
        isAuthenticated = true
        navigateToRoot(animated: false)
    }

    func logout() {
        isAuthenticated = false
        currentEmail = nil
        navigateToRoot(animated: false)
    }
}

private struct LoginView: View {
    @EnvironmentObject private var coordinator: AuthCoordinator

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Account") {
                emailField
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Log in") {
                    attemptLogin()
                }
                .buttonStyle(.borderedProminent)

                Button("Create an account") {
                    errorMessage = nil
                    coordinator.navigate(to: .signup)
                }
            }
        }
        .navigationTitle("Login")
    }

    @ViewBuilder
    private var emailField: some View {
        #if os(iOS)
        TextField("Email", text: $email)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
        #else
        TextField("Email", text: $email)
        #endif
    }

    private func attemptLogin() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Enter an email and password."
            return
        }

        // Demo-only: treat any non-empty credentials as success.
        errorMessage = nil
        coordinator.finishAuthentication(email: trimmedEmail)
    }
}

private struct SignupView: View {
    @EnvironmentObject private var coordinator: AuthCoordinator

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Create account") {
                emailField
                    .autocorrectionDisabled()

                SecureField("Password", text: $password)
                SecureField("Confirm password", text: $confirmPassword)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Sign up") {
                    attemptSignup()
                }
                .buttonStyle(.borderedProminent)

                Button("Back to login") {
                    errorMessage = nil
                    coordinator.navigateBack()
                }
            }
        }
        .navigationTitle("Sign up")
    }

    @ViewBuilder
    private var emailField: some View {
        #if os(iOS)
        TextField("Email", text: $email)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
        #else
        TextField("Email", text: $email)
        #endif
    }

    private func attemptSignup() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Enter an email."
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Enter a password."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        // Demo-only: treat a valid form as success.
        errorMessage = nil
        coordinator.finishAuthentication(email: trimmedEmail)
    }
}

private struct HomeView: View {
    @EnvironmentObject private var coordinator: AuthCoordinator
    let email: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome")
                .font(.title)
                .fontWeight(.semibold)

            Text(email)
                .font(.headline)
                .foregroundStyle(.secondary)

            Button("Log out") {
                coordinator.logout()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Home")
    }
}

#Preview {
    AuthFlowRootView()
}

#endif
