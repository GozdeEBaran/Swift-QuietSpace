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

    func signUp(email: String, password: String, confirmPassword: String, fullName: String) {
        errorMessage = nil

        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.errorMessage = "Please provide your name"
            return
        }

        guard !password.isEmpty else {
            self.errorMessage = "Password is required"
            return
        }

        guard password == confirmPassword else {
            self.errorMessage = "Passwords don't match"
            return
        }

        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && email.contains("@") else {
            errorMessage = "Enter a valid email"
            return
        }

        isLoading = true

        Task {
            do {
                let res = try await SupabaseService.shared.signUp(
                    email: email,
                    password: password,
                    fullName: fullName
                )
                self.userId = res.user?.id
                self.email = res.user?.email
                self.fullName = fullName
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
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
