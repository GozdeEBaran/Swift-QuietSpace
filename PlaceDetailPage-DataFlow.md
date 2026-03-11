# How Place Detail Page Gets Its Data (Swift-QuietSpace)

This document describes how the **Place Detail** screen receives the data it displays. The detail page does **not** fetch data itself; it is given a `Place` when you navigate to it.

---

## 1. Overview

- **PlaceDetailPage** takes a single parameter: `place: Place`.
- The `Place` model holds: `id`, `name`, `type`, `address`, `rating`, `reviewCount`, `latitude`, `longitude`, `quietScore`, `emoji`, `photoReference`, `phoneNumber`, `website`, `openingHours`, `reviews`, etc.
- Whoever navigates to the detail screen is responsible for passing the correct `Place` (from the map, search, or favorites).

---

## 2. Where the `Place` Comes From

The app can open **PlaceDetailPage** from three areas. In each case, the `Place` is already loaded by a view model or service before navigation.

| Entry point | Source of `Place` | How it’s loaded |
|-------------|-------------------|------------------|
| **Main map** | `MainMapViewModel.places` | Google Places API + Supabase approved submissions |
| **Search** | `SearchViewModel.searchResults` or `featuredPlaces` | Google Places API (search / featured) |
| **Favorites** | `FavoritesViewModel.favorites` | Supabase `user_favorites` |

---

## 3. Data Flow: Map → Place Detail

When the user taps a marker on the main map, that marker’s `Place` is passed straight into **PlaceDetailPage**.

### 3.1 Loading places for the map

**MainMapViewModel** fills `places` by:

1. **Google Places (nearby quiet spaces)**  
   - `GooglePlacesService.shared.searchNearby(latitude:longitude:radius:type:)`  
   - Uses the same categories as the React Native app (libraries, parks, cafes, museums, etc.).

2. **Approved user submissions**  
   - `SupabaseService.shared.getApprovedSubmissions()`  
   - Converts each `LocationSubmission` to `Place` with `.toPlace()`.

3. Combining both into one list:  
   `places = googlePlaces + submissionPlaces`.

```swift
// MainMapViewModel.loadAllQuietSpaces(around:)
let googlePlaces = try await GooglePlacesService.shared.searchNearby(
    latitude: coordinate.latitude,
    longitude: coordinate.longitude,
    radius: AppConfig.defaultSearchRadiusMeters,
    type: nil
)
let approvedSubmissions = try await SupabaseService.shared.getApprovedSubmissions()
let submissionPlaces = approvedSubmissions.map { $0.toPlace() }
let combined = googlePlaces + submissionPlaces
self.places = combined
```

### 3.2 Navigating from map to detail

**MainPage** shows a map and, for each place, an annotation that navigates to the detail screen with that same `Place`:

```swift
// MainPage.swift
ForEach(mapViewModel.places) { place in
    Annotation(place.name, coordinate: CLLocationCoordinate2D(...)) {
        NavigationLink(destination: PlaceDetailPage(place: place)) {
            PlaceMarkerView(place: place)
        }
        .buttonStyle(.plain)
    }
}
```

So:

- **Map** → data from `MainMapViewModel.places` (Google + Supabase).
- **Tap marker** → `PlaceDetailPage(place: place)` with that exact `Place`; no extra fetch.

---

## 4. Data Flow: Search → Place Detail

**SearchPage** uses **SearchViewModel**. When the user taps a search result or a featured place, it navigates with that `Place`:

```swift
// SearchPage – featured nearby
NavigationLink(destination: PlaceDetailPage(place: place)) { ... }

// SearchPage – search results
NavigationLink(destination: PlaceDetailPage(place: place)) {
    PlaceCard(place: place) { ... }
}
```

- **Search results / featured** → come from `SearchViewModel.searchResults` or `featuredPlaces` (when wired to real data, these are filled by **GooglePlacesService**).
- **Tap row** → `PlaceDetailPage(place: place)`; again, no fetch inside the detail page.

---

## 5. Data Flow: Favorites → Place Detail

If **FavoritesPage** shows a list of favorites and navigates to detail on tap:

- **Favorites** → loaded with `SupabaseService.shared.getFavorites(userId:)`, then converted to `[Place]` via `FavoritePlace.toPlace()`.
- **Tap favorite** → pass that `Place` into `PlaceDetailPage(place: place)`.

So the detail page receives a `Place` that was originally stored in Supabase `user_favorites` and converted to the shared `Place` model.

---

## 6. What Place Detail Page Does With the Data

- **PlaceDetailPage** keeps the `Place` in `@State private var place` and uses it for:
  - Title, type, address, rating, quiet score, open/closed.
  - Map region (centered on `place.latitude` / `place.longitude`).
  - Optional: phone, website, opening hours, reviews (if the `Place` already has them).
- It does **not** call any API or Supabase inside the detail screen; everything shown comes from the `Place` passed in.

---

## 7. Optional: Enriching With Full Details

If you want the detail page to show **full Google place details** (phone, website, hours, reviews) when the user opens it:

1. In **PlaceDetailPage**, add something like:
   - `@State private var detailedPlace: Place?`
   - On appear, if `place.googlePlaceId != nil`, call:
     - `GooglePlacesService.shared.getPlaceDetails(placeId: place.googlePlaceId!)`
   - If the result is non-nil, set `detailedPlace = result` and use `detailedPlace ?? place` for the UI.

2. That way the initial `Place` (from map/search/favorites) is still what **drives navigation and the first paint**; the extra fetch only adds richer fields when available.

---

## 8. Summary

| Step | What happens |
|------|-----------------------------|
| Map | `MainMapViewModel` loads places from Google + Supabase → `mapViewModel.places`. |
| Map tap | `NavigationLink(destination: PlaceDetailPage(place: place))` passes that `Place`. |
| Search / Favorites | Same idea: list is filled by a view model (Google or Supabase); tap passes one `Place` into `PlaceDetailPage(place:)`. |
| Detail page | Renders the received `Place` only; no fetch unless you add optional `getPlaceDetails`. |

So: **the place detail screen gets its data by receiving a `Place` from the screen that navigates to it (map, search, or favorites), and that `Place` was originally fetched by the corresponding view model (Google Places and/or Supabase).**
