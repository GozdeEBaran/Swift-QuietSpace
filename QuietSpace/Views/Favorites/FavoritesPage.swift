import SwiftUI

struct FavoritesPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var authVM = AuthViewModel() // Local instance for dummy view
    @StateObject private var favoritesVM = FavoritesViewModel()

    private var colors: AppColors {
        AppColors(colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            ScrollView {
                if favoritesVM.isLoading {
                    loadingView
                } else if favoritesVM.favorites.isEmpty {
                    emptyState
                } else {
                    favoritesListSection
                }
            }
            .refreshable {
                favoritesVM.fetchFavorites(userId: authVM.user?.id)
            }
        }
        .background(colors.background)
        .onAppear {
            favoritesVM.fetchFavorites(userId: authVM.user?.id)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Favorites")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colors.textPrimary)

            Text("\(favoritesVM.favorites.count) saved places")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Favorites List

    private var favoritesListSection: some View {
        LazyVStack(spacing: 0) {
            ForEach(favoritesVM.favorites) { place in
                ZStack(alignment: .topTrailing) {
                    PlaceCard(place: place) {
                        // Place tapped
                    }

                    Button {
                        withAnimation {
                            favoritesVM.removeFavorite(place)
                        }
                    } label: {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 14))
                            .foregroundStyle(colors.error)
                            .frame(width: 32, height: 32)
                            .background(colors.surface)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(colors.border, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 36)
                }
            }
        }
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading favorites...")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(colors.textMuted)

            Text("No favorites yet")
                .font(.headline)
                .foregroundColor(colors.textPrimary)

            Text("Start exploring and save the quiet places you love! Tap the heart icon on any place to add it here.")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(Spacing.lg)
    }
}

#Preview {
    NavigationStack {
        FavoritesPage()
    }
}
