# QuietSpace - Mobile App. Dev II - COMP 3097

## 1️⃣ Launch Screen

**File:** `LaunchScreen.swift`

**Features:**

- QuietSpace logo (teal location pin icon)
- App title: "QuietSpace"
- Tagline: "Find Your Focus"
- Group credits: Felix, Gozde, Daniel
- "Continue to the app" button → **Navigates to Begin Page**
- Bottom text: "Discover Your Next Productive Space"

**Design:**

- Clean white background
- Centered layout
- Teal/green color scheme
- SF Symbols for icon

---

## 2️⃣ Begin Page

**File:** `BeginPage.swift`

**Features:**

- QuietSpace logo
- App title and tagline
- **"Sign Up" button** → Navigates to Register Page (teal background)
- **"Log In" button** → Navigates to Login Page (white with border)
- "Already have an account? Log In" link
- Bottom tagline

**Design:**

- Minimalist layout
- Two prominent action buttons
- Clear call-to-action hierarchy

---

## 3️⃣ Login Page

**File:** `LoginPage.swift`

**Features:**

- Logo and "Find Your Serenity" tagline
- "Login" heading
- **Email Address field** (with envelope icon)
- **Password field** (with lock icon and eye toggle)
- "Don't know the password?" link
- **"Login" button** → Navigates to Main Page
- "Don't have an account? Register" link → Navigates to Register Page
- Divider with "or"
- **Social login buttons:**
  - "Continue with Google" (static)
  - "Continue with Apple" (static)

**Design:**

- Scrollable view
- Input fields with icons
- Rounded borders
- Social login options at bottom

---

## 4️⃣ Register Page

**File:** `RegisterPage.swift`

**Features:**

- Logo and "Find Your Serenity" tagline
- "Register" heading
- **Full Name field** (with person icon)
- **Email Address field** (with envelope icon)
- **Password field** (with lock icon and eye toggle)
- **Confirm Password field** (with lock icon and eye toggle)
- **Terms & Privacy checkbox** (must be checked to enable button)
- **"Register" button** → Navigates to Main Page (disabled until terms accepted)
- "Already have an account? Login" link → Navigates to Login Page

**Design:**

- Scrollable view
- Form validation (checkbox required)
- Disabled button state (grayed out)
- All fields with icons for better UX

---

## 5️⃣ Main Page (Map View)

**File:** `MainPage.swift`

**Features:**

**Top Section:**

- Search bar with magnifying glass icon: "Find a space..."
- "Nearby" button (teal)
- Horizontal scrolling category chips:
  - All (selected - teal)
  - Libraries
  - Cafes
  - Parks
  - Co-working

**Map Section:**

- Full-screen interactive map using **MapKit**
- Default location: San Francisco
- Map markers (can be added later)

## 👥 Group Information

**Group 33:**

- Felix
- Gozde
- Daniel

**Project:** QuietSpace - Find Your Focus
**Platform:** iOS (Swift/SwiftUI)

-
