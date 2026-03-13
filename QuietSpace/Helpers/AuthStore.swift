import Foundation
import Combine

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var userId: String?
    @Published private(set) var email: String?
    @Published var errorMessage: String?

    var isLoggedIn: Bool { userId != nil }

    func signIn(email: String, password: String) {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                let res = try await SupabaseService.shared.signIn(email: email, password: password)
                self.userId = res.user?.id
                self.email = res.user?.email
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func signUp(email: String, password: String, fullName: String) {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                let res = try await SupabaseService.shared.signUp(email: email, password: password, fullName: fullName)
                self.userId = res.user?.id
                self.email = res.user?.email
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
    }
}
