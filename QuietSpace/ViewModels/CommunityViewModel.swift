import Foundation
import Combine

class CommunityViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var posts: [Post] = []
    @Published var showCreatePost = false
    
    struct Post: Identifiable {
        let id: String
        let userName: String
        let userAvatar: String?
        let placeName: String
        let content: String
        let likes: Int
        let comments: Int
        let timeAgo: String
    }
    
    init() {
        fetchPosts(userId: nil)
    }
    
    func fetchPosts(userId: String?) {
        isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.posts = [
                Post(id: "1", userName: "Sarah J.", userAvatar: nil, placeName: "Central Library", content: "Found a super quiet corner on the 3rd floor. Perfect for deep work!", likes: 12, comments: 4, timeAgo: "2h ago"),
                Post(id: "2", userName: "Mike T.", userAvatar: nil, placeName: "Sunrise Park", content: "Beautiful morning at the park. Not too crowded.", likes: 8, comments: 1, timeAgo: "5h ago")
            ]
        }
    }
    
    func likePost(_ post: Post) {
        // Dummy implementation
    }
    
    func commentOnPost(_ post: Post) {
        // Dummy implementation
    }
}
