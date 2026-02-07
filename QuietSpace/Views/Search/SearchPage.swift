import SwiftUI

struct SearchPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var locationManager = LocationManager() // Local instance for dummy view
    @StateObject private var searchVM = SearchViewModel()

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var colors: AppColors {
        AppColors(colorScheme)
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            searchBarSection

            ScrollView {
                if searchVM.isLoading {
                    loadingView
                } else if searchVM.hasSearched {
                    searchResultsSection
                } else {
                    discoverySection
                }
            }
        }
        .background(colors.background)
        .onAppear {
            searchVM.loadFeaturedPlaces(location: locationManager.currentLocation)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Search")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colors.textPrimary)

            Text("Find quiet places anywhere")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Search Bar

    private var searchBarSection: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(colors.textMuted)

                TextField("Search quiet places...", text: $searchText)
                    .font(.body)
                    .foregroundColor(colors.textPrimary)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchVM.clearSearch()
                        isSearchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(colors.textMuted)
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
            .background(colors.surface)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(colors.border, lineWidth: 1)
            )

            Button {
                performSearch()
            } label: {
                Text("Search")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.textOnPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(colors.primary)
                    .cornerRadius(CornerRadius.md)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Discovery Section (Before Search)

    private var discoverySection: some View {
        VStack(spacing: Spacing.lg) {
            suggestedSearchesSection
            popularCategoriesSection
            featuredNearbySection
        }
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Suggested Searches

    private var suggestedSearchesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock")
                    .foregroundColor(colors.primary)
                Text("Suggested Searches")
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)
            }
            .padding(.horizontal, Spacing.md)

            VStack(spacing: 0) {
                ForEach(SearchViewModel.suggestedSearches, id: \.self) { suggestion in
                    Button {
                        searchText = suggestion
                        performSearch()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .font(.subheadline)
                                .foregroundColor(colors.textMuted)

                            Text(suggestion)
                                .font(.body)
                                .foregroundColor(colors.textPrimary)

                            Spacer()

                            Image(systemName: "arrow.up.left")
                                .font(.caption)
                                .foregroundColor(colors.textMuted)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                    }

                    Divider()
                        .padding(.leading, Spacing.md + Spacing.lg)
                }
            }
            .background(colors.surface)
            .cornerRadius(CornerRadius.md)
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Popular Categories

    private var popularCategoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(colors.primary)
                Text("Popular Categories")
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)
            }
            .padding(.horizontal, Spacing.md)

            LazyVGrid(columns: gridColumns, spacing: Spacing.sm) {
                ForEach(SearchViewModel.categories) { category in
                    Button {
                        searchText = category.label
                        performSearch()
                    } label: {
                        VStack(spacing: Spacing.sm) {
                            Text(category.icon)
                                .font(.title2)

                            Text(category.label)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colors.textPrimary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(colors.surface)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(colors.border, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Featured Nearby

    private var featuredNearbySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "star")
                    .foregroundColor(colors.primary)
                Text("Featured Nearby")
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)
            }
            .padding(.horizontal, Spacing.md)

            if searchVM.featuredPlaces.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "location.slash")
                            .font(.title2)
                            .foregroundColor(colors.textMuted)
                        Text("Enable location to see nearby places")
                            .font(.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding(.vertical, Spacing.lg)
                    Spacer()
                }
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(searchVM.featuredPlaces) { place in
                        NavigationLink(destination: PlaceDetailPage()) {
                            HStack(spacing: Spacing.sm) {
                                Text(place.emoji)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(colors.surfaceVariant)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(place.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(colors.textPrimary)
                                        .lineLimit(1)

                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: "star.fill")
                                            .font(.caption2)
                                            .foregroundColor(.orange)

                                        Text(String(format: "%.1f", place.rating))
                                            .font(.caption)
                                            .foregroundColor(colors.textSecondary)

                                        if let distance = place.distance {
                                            Text("  \(distance)")
                                                .font(.caption)
                                                .foregroundColor(colors.textMuted)
                                        }
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(colors.textMuted)
                            }
                            .padding(Spacing.sm)
                            .background(colors.surface)
                            .cornerRadius(CornerRadius.sm)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        VStack(spacing: Spacing.sm) {
            if searchVM.searchResults.isEmpty {
                emptyResultsView
            } else {
                HStack {
                    Text("\(searchVM.searchResults.count) results found")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, Spacing.md)

                LazyVStack(spacing: Spacing.md) {
                    ForEach(searchVM.searchResults) { place in
                        NavigationLink(destination: PlaceDetailPage()) {
                            PlaceCard(place: place) {
                                // Place tapped
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(colors.textMuted)

            Text("No results found")
                .font(.headline)
                .foregroundColor(colors.textPrimary)

            Text("Try a different search term or adjust your filters.")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .padding(Spacing.lg)
    }

    // MARK: - Helpers

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearchFocused = false
        searchVM.search(
            query: searchText,
            location: locationManager.currentLocation
        )
    }
}

#Preview {
    NavigationStack {
        SearchPage()
    }
}
