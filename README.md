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

## Contributions — Nguyen Minh Triet Luu (Student ID: 101542519, *Felix*)

- **`Managers/SupabaseService.swift` + `Models/`** — Supabase client for auth, profiles, community, favorites, check-ins, submissions, notifications, admin actions, and storage; Swift models for API data (`Place`, `UserProfile`, `CommunityPost`, etc.).
- **`Views/Search/` + `ViewModels/SearchViewModel.swift` + `GooglePlacesService.swift`** — Search screen, suggestions/categories, and place results from Google Places.
- **`Views/Community/`** — Community feed, new post (with images), comments, and notifications.
- **`Views/Profile/`** — User profile, edit profile, settings, and account updates (name, email, password).
- **`Views/Admin/`** — Admin dashboard and location review (approve/reject submissions, post moderation, user tools), using Supabase from above.
- **Other `Managers/`** — `LocationManager` (GPS for map/search), `GeminiAIService` (optional place-related AI context).
