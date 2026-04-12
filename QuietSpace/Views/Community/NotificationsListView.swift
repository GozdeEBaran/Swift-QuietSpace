// Nguyen Minh Triet Luu — Student ID: 101542519

import SwiftUI

struct NotificationsListView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var auth: AuthStore

    @State private var items: [AppNotification] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var colors: AppColors { AppColors(colorScheme) }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 44))
                        .foregroundColor(colors.textMuted)
                    Text("No notifications yet")
                        .font(.headline)
                        .foregroundColor(colors.textPrimary)
                    Text("Likes, comments, and updates will show up here.")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(items, id: \.rowKey) { n in
                        Button {
                            Task { await openNotification(n) }
                        } label: {
                            notificationRow(n)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(colors.background)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if auth.userId != nil, !items.isEmpty {
                    Button("Mark all read") {
                        Task { await markAllRead() }
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
        }
        .task { await load() }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func notificationRow(_ n: AppNotification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill((n.isRead == false) ? colors.primary : colors.border)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(n.title ?? "Notification")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(colors.textPrimary)
                if let m = n.message, !m.isEmpty {
                    Text(m)
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let raw = n.createdAt {
                    Text(CommunityHelpers.timeAgo(from: raw))
                        .font(.caption2)
                        .foregroundColor(colors.textMuted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .opacity(n.isRead == false ? 1 : 0.75)
    }

    private func load() async {
        guard let uid = auth.userId else {
            items = []
            isLoading = false
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await SupabaseService.shared.getNotifications(userId: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openNotification(_ n: AppNotification) async {
        guard let nid = n.id else { return }
        do {
            try await SupabaseService.shared.markNotificationAsRead(notificationId: nid)
            if let idx = items.firstIndex(where: { $0.id == nid }) {
                items[idx] = AppNotification(
                    id: n.id,
                    userId: n.userId,
                    type: n.type,
                    title: n.title,
                    message: n.message,
                    metadata: n.metadata,
                    isRead: true,
                    createdAt: n.createdAt
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markAllRead() async {
        guard let uid = auth.userId else { return }
        do {
            try await SupabaseService.shared.markAllNotificationsAsRead(userId: uid)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsListView()
            .environmentObject(AuthStore())
    }
}
