# QuietSpace

### Prerequisites

- macOS computer
- Xcode 14.0 or later
- iOS 16.0+ simulator or device

##

**Build and Run:**

- Select a simulator (e.g., iPhone 15 Pro)
- Press **⌘ + R** or click the Play button
- The app should launch with the Launch Screen

## 🎯 Group Information

**Group 33:**

- Felix
- Gozde
- Daniel

## Contributions — Nguyen Minh Triet Luu (Student ID: 101542519, _Felix_)

- **`Managers/SupabaseService.swift` + `Models/`** — Supabase client for auth, profiles, community, favorites, check-ins, submissions, notifications, admin actions, and storage; Swift models for API data (`Place`, `UserProfile`, `CommunityPost`, etc.).
- **`Views/Search/` + `ViewModels/SearchViewModel.swift` + `GooglePlacesService.swift`** — Search screen, suggestions/categories, and place results from Google Places.
- **`Views/Community/`** — Community feed, new post (with images), comments, and notifications.
- **`Views/Profile/`** — User profile, edit profile, settings, and account updates (name, email, password).
- **`Views/Admin/`** — Admin dashboard and location review (approve/reject submissions, post moderation, user tools), using Supabase from above.
- **Other `Managers/`** — `LocationManager` (GPS for map/search), `GeminiAIService` (optional place-related AI context).

## Contributions — Gozde Baran(Student ID: 101515982)

AddLocationView.swift — I created this file from scratch. It is the form that opens when you tap the + button on the map, where the user fills in a name, picks a category, and optionally types an address. The GPS coordinates are auto-filled from the device location. When the user taps Save, it submits the location to Supabase with a pending status so an admin can review it.

UserAddedPlacesStore.swift — I created this file from scratch. It is a small shared in-memory store that holds places the user adds during their session. It is injected as an EnvironmentObject so both the map and the profile screen can read and write to it.

LocationProfileView.swift — I created this file from scratch. It is the profile card that opens when you tap a saved place in Favorites. It loads a real photo from the Google Places Photo API if one is available, and falls back to an emoji with a colored gradient if not. It shows the quiet score, rating, price level, address, and a button that navigates to the full detail page.

MainPage.swift — I added the floating + button in the bottom-right corner of the map that opens the Add Location form at the user's current GPS position. I connected the UserAddedPlacesStore so places the user adds appear on the map immediately in the same session. I also changed how map pin taps work — instead of using a NavigationLink inside the map, I switched to a selectedPlace state variable with a navigationDestination modifier so that EnvironmentObjects are properly available on the next screen.

SearchPage.swift — I changed how tapping a place card works in search results. Instead of using an inline NavigationLink, I switched to the selectedPlace plus navigationDestination pattern for the same reason — to make sure shared environment objects like auth and favoritesVM are available on the destination screen.

SearchViewModel.swift — I replaced the dummy search logic that was there before, which just filtered a hardcoded list of two places based on keywords. I replaced it with a real async call to the Google Places Text Search API, so results are live, location-aware, and come from actual Google data.

PlaceDetailPage.swift — I implemented the real favorites functionality. Before my changes, the heart button did nothing except toggle a local icon. I added the actual Supabase calls to add and remove a favorite, connected it to the shared FavoritesViewModel so the Favorites tab updates instantly without a reload, and added a loading spinner while the Supabase call is in flight. If the call fails, the heart reverts back.

FavoritesViewModel.swift — I replaced the hardcoded dummy favorites that were loaded on init with a real fetch from the Supabase user_favorites table. I also rewrote the remove function so it removes the place from the local list immediately for a snappy feel, then deletes it from Supabase in the background.

FavoritesPage.swift — I added navigation so that tapping a place card opens the LocationProfileView for that place instead of doing nothing.

UserProfileView.swift — I added the location submission history to the recent activity feed. It fetches the user's past submissions from Supabase and displays each one with a status badge showing whether it is pending, approved, or rejected.

## Contributions — Daniil Orlov (Student ID: 101542519)
- Created the UI for the User Profile, Admin Dashboard, Add location, and Review location screens
- Created multiple reusable UI components (Nagivation bar, Settings Rows, Buttons)
- `LocationManager.swift` — ensured currentLocation starts as nil, improved permission handling, and added fallback only when denied/failure
- `MainPage.swift` — (temporarily) added reactive map centering using .onChange of location; later reverted after confirming emulator issue
- `SupabaseService.swift` — added session persistence (save/restore/clear tokens using UserDefaults)
- `AuthStore.swift` — implemented session restore on app launch, updated auth flow to persist user state, and refactored signUp to support email-confirmation flow (no auto-login)
- `QuietSpaceApp.swift` — added loading state and conditional routing based on restored session (isLoading / isLoggedIn)
- `RegisterPage.swift` — improved validation, sanitized inputs, disabled button correctly, added success alert, and redirected to login after registration
