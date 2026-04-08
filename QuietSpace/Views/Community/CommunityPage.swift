import SwiftUI

struct CommunityPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var auth: AuthStore

    @StateObject private var communityVM = CommunityViewModel()

    @State private var showCreatePost = false
    @State private var pendingFlag: CommunityFeedPost?
    @State private var pendingDelete: CommunityFeedPost?
    @State private var adminDeleteReason = ""

    private var colors: AppColors {
        AppColors(colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            ScrollView {
                if communityVM.isLoading {
                    loadingView
                } else if communityVM.feedPosts.isEmpty {
                    emptyState
                } else {
                    postsSection
                }
            }
            .refreshable {
                await communityVM.load(userId: auth.userId)
            }
        }
        .background(colors.background)
        .task {
            await communityVM.load(userId: auth.userId)
        }
        .onAppear {
            Task { await communityVM.refreshUnreadCount(userId: auth.userId) }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(onPosted: {
                Task {
                    await communityVM.load(userId: auth.userId)
                    await communityVM.refreshUnreadCount(userId: auth.userId)
                }
            })
            .environmentObject(auth)
        }
        .alert("Error", isPresented: Binding(
            get: { communityVM.errorMessage != nil },
            set: { if !$0 { communityVM.errorMessage = nil } }
        )) {
            Button("OK") { communityVM.errorMessage = nil }
        } message: {
            Text(communityVM.errorMessage ?? "")
        }
        .alert("Flag this post?", isPresented: Binding(
            get: { pendingFlag != nil },
            set: { if !$0 { pendingFlag = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingFlag = nil }
            Button("Flag", role: .destructive) {
                Task {
                    if let p = pendingFlag {
                        await communityVM.flagPost(p, userId: auth.userId)
                    }
                    pendingFlag = nil
                }
            }
        } message: {
            Text("Our team will review this content.")
        }
        .alert("Remove post", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil; adminDeleteReason = "" } }
        )) {
            TextField("Reason (shown to author)", text: $adminDeleteReason)
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
                adminDeleteReason = ""
            }
            Button("Delete", role: .destructive) {
                Task {
                    if let p = pendingDelete, let uid = auth.userId {
                        await communityVM.adminDeletePost(p, reason: adminDeleteReason, userId: uid)
                    }
                    pendingDelete = nil
                    adminDeleteReason = ""
                }
            }
        } message: {
            Text("The author will receive a notification with your reason.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Community")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colors.textPrimary)

                Text("Reviews from quiet seekers")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
            }

            Spacer(minLength: 8)

            if communityVM.isAdmin {
                NavigationLink {
                    AdminDashboard()
                } label: {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.title3)
                        .foregroundColor(colors.primary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }

            if auth.userId != nil {
                NavigationLink {
                    NotificationsListView()
                        .environmentObject(auth)
                        .onDisappear {
                            Task { await communityVM.refreshUnreadCount(userId: auth.userId) }
                        }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.title3)
                            .foregroundColor(colors.textPrimary)
                            .frame(width: 44, height: 44)
                        if communityVM.unreadNotifications > 0 {
                            Text(unreadBadgeText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(colors.error)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Button {
                showCreatePost = true
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

    private var unreadBadgeText: String {
        let n = communityVM.unreadNotifications
        return n > 99 ? "99+" : "\(n)"
    }

    // MARK: - Posts

    private var postsSection: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(communityVM.feedPosts) { fp in
                PostCard(
                    feedPost: fp,
                    currentUserId: auth.userId,
                    isAdmin: communityVM.isAdmin,
                    onLike: {
                        guard let uid = auth.userId else { return }
                        Task { await communityVM.toggleLike(post: fp, userId: uid) }
                    },
                    onFlag: {
                        pendingFlag = fp
                    },
                    onAdminDelete: {
                        pendingDelete = fp
                    },
                    onCommentLike: { commentId in
                        guard let uid = auth.userId, let pid = fp.post.id else { return }
                        Task {
                            await communityVM.toggleCommentLike(postId: pid, commentId: commentId, userId: uid)
                        }
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
            .environmentObject(AuthStore())
    }
}
