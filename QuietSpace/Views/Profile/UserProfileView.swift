// Name: Gozde Baran
// Student ID: 101515982
// Contribution:
// - Added location submission history to the activity feed
// - Fetches user's submissions from Supabase and displays status (pending/approved/rejected)

import SwiftUI
import CoreLocation

private struct AddLocationProfileItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct UserProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var placesStore: UserAddedPlacesStore

    @StateObject private var locationManager = LocationManager()
    @State private var addLocationItem: AddLocationProfileItem?
    @State private var showLocationUnavailableAlert = false

    @State private var profile: UserProfile?
    @State private var isAdmin = false
    @State private var postCount = 0
    @State private var recentActivities: [ProfileActivity] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var colors: AppColors { AppColors(colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection
                    statsRow
                    quickActions
                    recentActivitySection
                }
                .padding(.bottom, 24)
            }

            NavBar()
        }
        .navigationBarHidden(true)
        .background(colors.background)
        .task {
            locationManager.startIfNeeded()
            await load()
        }
        .sheet(item: $addLocationItem) { item in
            AddLocationView(coordinate: item.coordinate) { place in
                placesStore.add(place)
            }
        }
        .alert("Location unavailable", isPresented: $showLocationUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable Location Services for QuietSpace in Settings to add locations.")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomLeading) {
                    coverView
                        .frame(height: 176)
                        .clipped()

                    LinearGradient(
                        colors: [
                            Color.black.opacity(colorScheme == .dark ? 0.35 : 0.10),
                            colors.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 176)
                }

                NavigationLink {
                    ProfileSettingsView()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
                .padding(.top, 12)
            }

            HStack(alignment: .bottom, spacing: 12) {
                avatarView
                    .offset(y: -34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile?.fullName ?? auth.fullName ?? "Guest")
                        .font(.title2.weight(.bold))
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(2)
                    Text(profile?.email ?? auth.email ?? "Not signed in")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(1)
                    if let created = profile?.createdAt {
                        Text("Member since \(memberSince(created))")
                            .font(.caption)
                            .foregroundColor(colors.textMuted)
                    }
                    if isAdmin {
                        Text("Admin")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(colors.primaryLight)
                            .foregroundColor(colors.primary)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)

            NavigationLink {
                EditProfileView()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                    Text("Edit profile")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(colors.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(colors.primary, lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
    }

    private var coverView: some View {
        Group {
            if let s = profile?.coverImageUrl, let u = URL(string: s) {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Color(UIColor.systemGray5)
                    }
                }
            } else {
                Color(UIColor.systemGray5)
            }
        }
    }

    private var avatarView: some View {
        NavigationLink {
            EditProfileView()
        } label: {
            Group {
                if let s = profile?.avatarUrl, let u = URL(string: s) {
                    AsyncImage(url: u) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: placeholderAvatar
                        }
                    }
                } else {
                    placeholderAvatar
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(Circle().stroke(colors.background, lineWidth: 4))
        }
        .buttonStyle(.plain)
    }

    private var placeholderAvatar: some View {
        LinearGradient(colors: [colors.primary, colors.primary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay(
                Text(initials)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(colors.textOnPrimary)
            )
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("\(postCount)")
                    .font(.title3.weight(.bold))
                    .foregroundColor(colors.textPrimary)
                Text("Posts")
                    .font(.caption)
                    .foregroundColor(colors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 16)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.headline.weight(.bold))
                .foregroundColor(colors.textPrimary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NavigationLink { EditProfileView() } label: {
                        quickActionLabel(icon: "person", title: "Edit Profile")
                    }
                    NavigationLink { FavoritesPage() } label: {
                        quickActionLabel(icon: "heart", title: "Favorites")
                    }
                    NavigationLink { CommunityPage() } label: {
                        quickActionLabel(icon: "bubble.left.and.bubble.right", title: "Community")
                    }
                    Button { presentAddLocation() } label: {
                        quickActionLabel(icon: "mappin.and.ellipse", title: "Add Location")
                    }
                    NavigationLink { ProfileSettingsView() } label: {
                        quickActionLabel(icon: "gearshape", title: "Settings")
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 8)
    }

    private func presentAddLocation() {
        guard let loc = locationManager.currentLocation else {
            showLocationUnavailableAlert = true
            return
        }
        addLocationItem = AddLocationProfileItem(coordinate: loc.coordinate)
    }

    private func quickActionLabel(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(colors.primary)
                .frame(width: 28, height: 28)
                .background(colors.primaryLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colors.border, lineWidth: 1)
        )
    }

    /// User-added places from the shared store, as ProfileActivity rows.
    private var addedPlaceActivities: [ProfileActivity] {
        placesStore.places.map { place in
            ProfileActivity(
                id: "added-\(place.id)",
                icon: "mappin.and.ellipse",
                title: "Added \"\(place.name)\"",
                subtitle: "just now",
                createdAt: nil
            )
        }
    }

    private var allRecentActivities: [ProfileActivity] {
        // User-added locations always appear first (most recent), followed by Supabase activities.
        addedPlaceActivities + recentActivities
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity")
                .font(.headline.weight(.bold))
                .foregroundColor(colors.textPrimary)
                .padding(.horizontal, 16)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if allRecentActivities.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 10) {
                    ForEach(allRecentActivities) { a in
                        activityRow(a)
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private func activityRow(_ a: ProfileActivity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: a.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(colors.primary)
                .frame(width: 32, height: 32)
                .background(colors.surfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(a.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                Text(a.subtitle)
                    .font(.caption)
                    .foregroundColor(colors.textMuted)
            }
            Spacer()
        }
        .padding(12)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colors.border, lineWidth: 1)
        )
    }

    private var initials: String {
        let name = profile?.fullName ?? auth.fullName ?? auth.email ?? "??"
        let parts = name.split(separator: " ").map(String.init)
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased() }
        return String(name.prefix(2)).uppercased()
    }

    private func memberSince(_ raw: String) -> String {
        if let d = ISO8601DateFormatter().date(from: raw) {
            return DateFormatter.localizedString(from: d, dateStyle: .long, timeStyle: .none)
        }
        return raw
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        guard let uid = auth.userId else {
            profile = nil
            isAdmin = false
            postCount = 0
            recentActivities = []
            return
        }

        do {
            profile = try await SupabaseService.shared.getUserProfile(userId: uid)
            isAdmin = (try? await SupabaseService.shared.isAdmin(userId: uid)) ?? false

            let checkIns = (try? await SupabaseService.shared.getUserCheckIns(userId: uid, limit: 20)) ?? []
            let favorites = (try? await SupabaseService.shared.getFavorites(userId: uid)) ?? []
            let posts = (try? await SupabaseService.shared.getUserCommunityPosts(userId: uid, limit: 20)) ?? []
            let submissions = (try? await SupabaseService.shared.getMyLocationSubmissions(userId: uid)) ?? []

            postCount = posts.count

            var acts: [ProfileActivity] = []
            acts.append(contentsOf: checkIns.map { ci in
                ProfileActivity(
                    id: "ci-\(ci.id ?? "0")-\(ci.createdAt ?? "")",
                    icon: "mappin.circle",
                    title: "Checked in at \(ci.placeName ?? "a place")",
                    subtitle: CommunityHelpers.timeAgo(from: ci.createdAt),
                    createdAt: ci.createdAt
                )
            })
            acts.append(contentsOf: favorites.map { f in
                ProfileActivity(
                    id: "fav-\(f.id ?? "0")-\(f.createdAt ?? "")",
                    icon: "heart",
                    title: "Favorited \(f.name ?? "a place")",
                    subtitle: CommunityHelpers.timeAgo(from: f.createdAt),
                    createdAt: f.createdAt
                )
            })
            acts.append(contentsOf: posts.map { p in
                ProfileActivity(
                    id: "post-\(p.id ?? "0")-\(p.createdAt ?? "")",
                    icon: "bubble.left.and.bubble.right",
                    title: "Posted about \(p.placeName ?? "a place")",
                    subtitle: CommunityHelpers.timeAgo(from: p.createdAt),
                    createdAt: p.createdAt
                )
            })
            acts.append(contentsOf: submissions.map { s in
                let statusIcon: String
                switch s.status {
                case "approved": statusIcon = "checkmark.seal.fill"
                case "rejected": statusIcon = "xmark.seal.fill"
                default:         statusIcon = "clock.fill"          // pending
                }
                let statusLabel = (s.status ?? "pending").capitalized
                return ProfileActivity(
                    id: "sub-\(s.id ?? "0")-\(s.createdAt ?? "")",
                    icon: statusIcon,
                    title: "Submitted \"\(s.name ?? "a location")\"",
                    subtitle: "\(statusLabel) · \(CommunityHelpers.timeAgo(from: s.createdAt))",
                    createdAt: s.createdAt
                )
            })

            recentActivities = Array(acts.sorted(by: { ($0.createdAt ?? "") > ($1.createdAt ?? "") }).prefix(8))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ProfileActivity: Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let createdAt: String?
}






#Preview {
    NavigationStack {
        UserProfileView()
            .environmentObject(AuthStore())
    }
}
