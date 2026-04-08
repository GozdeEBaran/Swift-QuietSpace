import Foundation
import Combine

struct TopCommentPreview: Identifiable {
    let id: String
    let userName: String
    let text: String
    var likesCount: Int
    var isLikedByCurrentUser: Bool
}

struct CommunityFeedPost: Identifiable {
    var id: String { post.id ?? "" }
    var post: CommunityPost
    var isLiked: Bool
    var topComments: [TopCommentPreview]
}

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var feedPosts: [CommunityFeedPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAdmin = false
    @Published var unreadNotifications = 0

    func load(userId: String?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let uid = userId {
                isAdmin = (try? await SupabaseService.shared.isAdmin(userId: uid)) ?? false
                unreadNotifications = await SupabaseService.shared.getUnreadNotificationCount(userId: uid)
            } else {
                isAdmin = false
                unreadNotifications = 0
            }

            let posts = try await SupabaseService.shared.getApprovedCommunityPosts(limit: 20)
            var likedPostIds = Set<String>()
            var likedCommentIds = Set<String>()
            if let uid = userId {
                likedPostIds = Set(try await SupabaseService.shared.getUserLikedPostIds(userId: uid))
                likedCommentIds = Set(try await SupabaseService.shared.getUserLikedCommentIds(userId: uid))
            }

            var built: [CommunityFeedPost] = []
            for p in posts {
                guard let pid = p.id else { continue }
                let tops = try await SupabaseService.shared.getTopCommentsForPost(postId: pid, limit: 3)
                let previews: [TopCommentPreview] = tops.compactMap { c in
                    guard let cid = c.id else { return nil }
                    return TopCommentPreview(
                        id: cid,
                        userName: c.userName ?? "User",
                        text: c.comment ?? "",
                        likesCount: c.displayLikes,
                        isLikedByCurrentUser: userId != nil && likedCommentIds.contains(cid)
                    )
                }
                let liked = userId != nil && likedPostIds.contains(pid)
                built.append(CommunityFeedPost(post: p, isLiked: liked, topComments: previews))
            }
            feedPosts = built
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshUnreadCount(userId: String?) async {
        guard let uid = userId else {
            unreadNotifications = 0
            return
        }
        unreadNotifications = await SupabaseService.shared.getUnreadNotificationCount(userId: uid)
    }

    func toggleLike(post: CommunityFeedPost, userId: String) async {
        guard let pid = post.post.id else { return }
        do {
            let result = try await SupabaseService.shared.toggleLike(postId: pid, userId: userId)
            if let idx = feedPosts.firstIndex(where: { $0.post.id == post.post.id }) {
                let p = feedPosts[idx].post
                feedPosts[idx] = CommunityFeedPost(
                    post: CommunityPost(
                        id: p.id,
                        userId: p.userId,
                        userName: p.userName,
                        userAvatarUrl: p.userAvatarUrl,
                        placeName: p.placeName,
                        imageUrl: p.imageUrl,
                        caption: p.caption,
                        category: p.category,
                        likesCount: result.likesCount,
                        commentsCount: p.commentsCount,
                        status: p.status,
                        createdAt: p.createdAt
                    ),
                    isLiked: result.isLiked,
                    topComments: feedPosts[idx].topComments
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleCommentLike(postId: String, commentId: String, userId: String) async {
        do {
            let result = try await SupabaseService.shared.toggleCommentLike(commentId: commentId, userId: userId)
            guard let pIdx = feedPosts.firstIndex(where: { $0.post.id == postId }),
                  let cIdx = feedPosts[pIdx].topComments.firstIndex(where: { $0.id == commentId }) else { return }
            var fp = feedPosts[pIdx]
            fp.topComments[cIdx].likesCount = result.likesCount
            fp.topComments[cIdx].isLikedByCurrentUser = result.isLiked
            feedPosts[pIdx] = fp
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func flagPost(_ feedPost: CommunityFeedPost, userId: String?) async {
        guard userId != nil, let pid = feedPost.post.id else {
            errorMessage = "Sign in to flag posts."
            return
        }
        if feedPost.post.status == "flagged" {
            errorMessage = "This post is already flagged."
            return
        }
        do {
            try await SupabaseService.shared.flagPost(postId: pid)
            if let idx = feedPosts.firstIndex(where: { $0.post.id == feedPost.post.id }) {
                let p = feedPosts[idx].post
                feedPosts[idx] = CommunityFeedPost(
                    post: CommunityPost(
                        id: p.id,
                        userId: p.userId,
                        userName: p.userName,
                        userAvatarUrl: p.userAvatarUrl,
                        placeName: p.placeName,
                        imageUrl: p.imageUrl,
                        caption: p.caption,
                        category: p.category,
                        likesCount: p.likesCount,
                        commentsCount: p.commentsCount,
                        status: "flagged",
                        createdAt: p.createdAt
                    ),
                    isLiked: feedPosts[idx].isLiked,
                    topComments: feedPosts[idx].topComments
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func adminDeletePost(_ feedPost: CommunityFeedPost, reason: String, userId _: String) async {
        guard let pid = feedPost.post.id, let authorId = feedPost.post.userId else { return }
        do {
            try await SupabaseService.shared.deletePost(postId: pid)
            try await SupabaseService.shared.createNotification(
                userId: authorId,
                type: "post_deleted",
                title: "Your Post Was Removed",
                message: reason.isEmpty ? "Your post was removed by an admin for violating community guidelines." : reason
            )
            feedPosts.removeAll { $0.post.id == pid }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removePostFromFeed(postId: String) {
        feedPosts.removeAll { $0.post.id == postId }
    }
}
