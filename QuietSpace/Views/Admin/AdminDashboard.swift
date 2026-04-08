//
//  AdminDashboard.swift
//  QuietSpace
//

import SwiftUI

struct AdminDashboard: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var auth: AuthStore
    @StateObject private var vm = AdminDashboardViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var pollTimer: Timer?

    @State private var postToReject: CommunityPost?
    @State private var rejectPostReason = ""

    @State private var locationToReject: LocationSubmissionAdmin?
    @State private var rejectLocationReason = ""

    @State private var userToBan: UserProfile?
    @State private var banReason = ""

    @State private var userToDelete: UserProfile?

    private var colors: AppColors { AppColors(colorScheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                statsRow

                tabPicker

                if vm.isLoading && vm.pendingPosts.isEmpty && vm.locationRows.isEmpty && vm.users.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    tabContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(colors.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
            }
        }
        .refreshable {
            await vm.load()
        }
        .task {
            await vm.load()
            startPolling()
        }
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .alert("Reject post", isPresented: Binding(
            get: { postToReject != nil },
            set: { if !$0 { postToReject = nil } }
        )) {
            TextField("Reason (user will be notified)", text: $rejectPostReason)
            Button("Cancel", role: .cancel) {
                postToReject = nil
            }
            Button("Reject & notify") {
                if let p = postToReject {
                    let r = rejectPostReason
                    rejectPostReason = ""
                    postToReject = nil
                    Task { await vm.rejectPost(p, reason: r) }
                }
            }
        } message: {
            Text("Enter a reason for rejection.")
        }
        .alert("Reject location", isPresented: Binding(
            get: { locationToReject != nil },
            set: { if !$0 { locationToReject = nil } }
        )) {
            TextField("Reason (user will be notified)", text: $rejectLocationReason)
            Button("Cancel", role: .cancel) {
                locationToReject = nil
            }
            Button("Reject & notify") {
                if let row = locationToReject {
                    let r = rejectLocationReason
                    rejectLocationReason = ""
                    locationToReject = nil
                    Task { await vm.rejectLocation(row, reason: r) }
                }
            }
        } message: {
            Text("Enter a reason for rejection.")
        }
        .alert("Ban user", isPresented: Binding(
            get: { userToBan != nil },
            set: { if !$0 { userToBan = nil } }
        )) {
            TextField("Reason", text: $banReason)
            Button("Cancel", role: .cancel) {
                userToBan = nil
            }
            Button("Ban & notify", role: .destructive) {
                if let u = userToBan {
                    let r = banReason
                    banReason = ""
                    userToBan = nil
                    Task { await vm.banUser(u, reason: r) }
                }
            }
        } message: {
            Text("The user will be notified.")
        }
        .alert("Delete user permanently?", isPresented: Binding(
            get: { userToDelete != nil },
            set: { if !$0 { userToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { userToDelete = nil }
            Button("Delete", role: .destructive) {
                if let u = userToDelete {
                    userToDelete = nil
                    Task { await vm.deleteUser(u) }
                }
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var header: some View {
        Text("Admin Dashboard")
            .font(.title2.weight(.bold))
            .foregroundColor(colors.textPrimary)
            .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(title: "Posts", value: vm.pendingPosts.count, accent: colors.warning)
            statCard(title: "Locations", value: vm.pendingLocationCount, accent: colors.primary)
            statCard(title: "Users", value: vm.users.count, accent: colors.accent)
        }
    }

    private func statCard(title: String, value: Int, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title2.weight(.bold))
                .foregroundColor(accent)
            Text(title)
                .font(.caption)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accent)
                .frame(width: 4)
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                let titles = ["Posts", "Locations", "Users"]
                Button {
                    vm.selectedTab = i
                } label: {
                    Text(titles[i])
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(vm.selectedTab == i ? colors.primary : colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(vm.selectedTab == i ? colors.surface : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(colors.surfaceVariant)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var tabContent: some View {
        switch vm.selectedTab {
        case 0:
            postsTab
        case 1:
            locationsTab
        default:
            usersTab
        }
    }

    private var postsTab: some View {
        Group {
            if vm.pendingPosts.isEmpty {
                emptyState(icon: "checkmark.circle", text: "No pending posts")
            } else {
                ForEach(Array(vm.pendingPosts.enumerated()), id: \.offset) { _, post in
                    postCard(post)
                }
            }
        }
    }

    private func postCard(_ post: CommunityPost) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: post.userAvatarUrl ?? "")) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(colors.textMuted)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.userName ?? "User")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(colors.textPrimary)
                    Text(relativeTime(from: post.createdAt))
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
                Spacer()
                Text(post.status ?? "")
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((post.status == "pending" ? colors.warningLight : colors.errorLight))
                    .foregroundColor(post.status == "pending" ? colors.warning : colors.error)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Text(post.caption ?? "")
                .font(.subheadline)
                .foregroundColor(colors.textPrimary)
                .lineLimit(4)

            if let urlStr = post.imageUrl, let u = URL(string: urlStr) {
                AsyncImage(url: u) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            HStack(spacing: 10) {
                Button {
                    postToReject = post
                    rejectPostReason = "Your post did not meet our community guidelines."
                } label: {
                    Label("Reject", systemImage: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(colors.error)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    Task { await vm.approvePost(post) }
                } label: {
                    Label("Approve", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(colors.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var locationsTab: some View {
        Group {
            if vm.locationRows.isEmpty {
                emptyState(icon: "mappin.and.ellipse", text: "No location submissions")
            } else {
                ForEach(vm.locationRows) { row in
                    locationCard(row)
                }
            }
        }
    }

    private func locationCard(_ row: LocationSubmissionAdmin) -> some View {
        let sub = row.submission
        let status = sub.status ?? "pending"
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(colors.primary)
                    .frame(width: 40, height: 40)
                    .background(colors.primaryLight)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(sub.name ?? "Untitled")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(colors.textPrimary)
                    Text(sub.type ?? "")
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
                Spacer()
                Text(status.capitalized)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusBadgeColor(status))
                    .foregroundColor(colors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Text(sub.address ?? "")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .lineLimit(2)

            if let name = row.submitterName, !name.isEmpty {
                Text("Submitted by \(name)")
                    .font(.caption)
                    .foregroundColor(colors.primary)
            }

            if status == "pending" {
                HStack(spacing: 10) {
                    Button {
                        locationToReject = row
                        rejectLocationReason = "Your location \"\(sub.name ?? "")\" did not meet our criteria."
                    } label: {
                        Label("Reject", systemImage: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(colors.error)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await vm.approveLocation(row) }
                    } label: {
                        Label("Approve", systemImage: "checkmark")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(colors.primary)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    ReviewLocation(submission: sub)
                } label: {
                    Text("Open review")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(colors.surfaceVariant)
                        .foregroundColor(colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink {
                    ReviewLocation(submission: sub)
                } label: {
                    Text("View")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(colors.surfaceVariant)
                        .foregroundColor(colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statusBadgeColor(_ status: String) -> Color {
        switch status {
        case "pending": return colors.warningLight
        case "approved": return colors.primaryLight
        case "rejected": return colors.errorLight
        default: return colors.surfaceVariant
        }
    }

    private var usersTab: some View {
        Group {
            if vm.users.isEmpty {
                emptyState(icon: "person.2", text: "No users found")
            } else {
                ForEach(vm.users) { u in
                    userCard(u)
                }
            }
        }
    }

    private func userCard(_ user: UserProfile) -> some View {
        let isBanned = user.displayRole == "banned"
        let isAdminUser = user.displayRole == "admin"
        let isSelf = user.id == auth.userId

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: user.avatarUrl ?? "")) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(colors.textMuted)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(colors.textPrimary)
                    Text(user.email ?? "")
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
                Spacer()
                Text(isAdminUser ? "Admin" : (isBanned ? "Banned" : "User"))
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isAdminUser ? colors.primaryLight : (isBanned ? colors.errorLight : colors.surfaceVariant))
                    .foregroundColor(isAdminUser ? colors.primary : (isBanned ? colors.error : colors.textSecondary))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if !isSelf && !isAdminUser {
                HStack(spacing: 10) {
                    if isBanned {
                        Button {
                            Task { await vm.unbanUser(user) }
                        } label: {
                            Label("Unban", systemImage: "checkmark.circle")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(colors.primary)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            userToBan = user
                            banReason = "Violation of community guidelines"
                        } label: {
                            Label("Ban", systemImage: "nosign")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        userToDelete = user
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(colors.error)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(colors.textMuted)
            Text(text)
                .font(.body)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                await vm.load()
            }
        }
        if let t = pollTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    private func relativeTime(from raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "recently" }
        if let ms = Int64(raw) {
            let d = Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
            return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: Date())
        }
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: raw) {
            return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: Date())
        }
        return "recently"
    }
}

#Preview {
    NavigationStack {
        AdminDashboard()
            .environmentObject(AuthStore())
    }
}
