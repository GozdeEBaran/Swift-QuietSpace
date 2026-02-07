import SwiftUI

struct CommunityPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var authVM = AuthViewModel() // Local instance for dummy view
    @StateObject private var communityVM = CommunityViewModel()

    private var colors: AppColors {
        AppColors(colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            ScrollView {
                if communityVM.isLoading {
                    loadingView
                } else if communityVM.posts.isEmpty {
                    emptyState
                } else {
                    postsSection
                }
            }
            .refreshable {
                communityVM.fetchPosts(userId: authVM.user?.id)
            }
        }
        .background(colors.background)
        .onAppear {
            communityVM.fetchPosts(userId: authVM.user?.id)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Community")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colors.textPrimary)

                Text("Reviews from quiet seekers")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
            }

            Spacer()

            Button {
                communityVM.showCreatePost = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.textOnPrimary)
                    .frame(width: 44, height: 44)
                    .background(colors.primary)
                    .clipShape(Circle())
                    .shadow(color: colors.primary.opacity(0.3), radius: 6, y: 3)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Posts

    private var postsSection: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(communityVM.posts) { post in
                PostCard(
                    post: post,
                    onLike: {
                        communityVM.likePost(post)
                    },
                    onComment: {
                        communityVM.commentOnPost(post)
                    }
                )
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading posts...")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(colors.textMuted)

            Text("No posts yet")
                .font(.headline)
                .foregroundColor(colors.textPrimary)

            Text("Be the first to share your experience!")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(Spacing.lg)
    }
}

#Preview {
    NavigationStack {
        CommunityPage()
    }
}
