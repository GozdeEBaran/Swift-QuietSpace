import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var user: User? = User(id: "user1", name: "Felix Luu", email: "felix@example.com")
    
    struct User: Identifiable {
        let id: String
        let name: String
        let email: String
    }
}
