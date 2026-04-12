// Daniil Orlov - 101500729
// implemented user registration and login;
// added restore session to sign in user automatically
// if didn't manually logout

import Foundation
import Combine

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var userId: String?
    @Published private(set) var email: String?
    @Published private(set) var fullName: String?
    @Published var errorMessage: String?

    var isLoggedIn: Bool { userId != nil }

    init() {
        Task {
            await restoreSession()
        }
    }

    func restoreSession() async {
        errorMessage = nil
        isLoading = true

        do {
            if let restored = try await SupabaseService.shared.restoreSession() {
                self.userId = restored.userId
                self.email = restored.email
                self.fullName = restored.fullName
            } else {
                self.userId = nil
                self.email = nil
                self.fullName = nil
            }
        } catch {
            self.userId = nil
            self.email = nil
            self.fullName = nil
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signIn(email: String, password: String) {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                let res = try await SupabaseService.shared.signIn(email: email, password: password)
                self.userId = res.user?.id
                self.email = res.user?.email

                if let uid = res.user?.id {
                    let profile = try? await SupabaseService.shared.getUserProfile(userId: uid)
                    self.fullName = profile?.fullName
                } else {
                    self.fullName = nil
                }

                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func signUp(email: String, password: String, confirmPassword: String, fullName: String) async throws {
        errorMessage = nil

        let cleanedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !cleanedName.isEmpty else {
            errorMessage = "Please provide your name"
            throw AuthError.validation("Please provide your name")
        }

        guard !cleanedEmail.isEmpty,
              cleanedEmail.range(
                of: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#,
                options: [.regularExpression, .caseInsensitive]
              ) != nil else {
            errorMessage = "Enter a valid email address"
            throw AuthError.validation("Enter a valid email address")
        }

        guard !password.isEmpty else {
            errorMessage = "Password is required"
            throw AuthError.validation("Password is required")
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            throw AuthError.validation("Passwords don't match")
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await SupabaseService.shared.signUp(
                email: cleanedEmail,
                password: password,
                fullName: cleanedName
            )

            // Do not mark user as logged in here.
            // Email confirmation flow should send them to Login.
            self.userId = nil
            self.email = nil
            self.fullName = nil
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    enum AuthError: LocalizedError {
        case validation(String)

        var errorDescription: String? {
            switch self {
            case .validation(let message):
                return message
            }
        }
    }

    func signOut() {
        SupabaseService.shared.signOut()
        userId = nil
        email = nil
        fullName = nil
    }

    func updateCachedProfile(fullName: String?) {
        self.fullName = fullName
    }
}
