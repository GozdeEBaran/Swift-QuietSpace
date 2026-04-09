// MainPage.swift
import SwiftUI
import MapKit
import CoreLocation

private struct AddLocationSheetItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MainPage: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var placesStore: UserAddedPlacesStore

    @State private var searchText: String = ""
    @StateObject private var locationManager = LocationManager()
    @StateObject private var mapViewModel = MainMapViewModel()
    @State private var selectedPlace: Place? = nil  // Drives navigation outside Map block

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: AppConfig.defaultLatitude, longitude: AppConfig.defaultLongitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    @State private var selectedCategory: MainMapViewModel.Category = .all
    @State private var searchRadius: Double = 5000
    @State private var showMap = true
    @State private var showTransit = false
    @State private var showCommunityPlaces = false
    @State private var showTimer = false

    @State private var unreadNotifications = 0

    @State private var addLocationSheet: AddLocationSheetItem?
    @State private var showAddLocationUnavailableAlert = false

    var body: some View {
        ZStack {
            if showMap {
                Map(position: $position) {
                    ForEach(combinedPlaces) { place in
                        Annotation(place.name, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)) {
                            Button { selectedPlace = place } label: {
                                PlaceMarkerView(place: place)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if showTransit {
                        ForEach(mapViewModel.transitStops) { stop in
                            Marker(stop.name ?? "Transit", coordinate: CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude))
                        }
                    }
                }
                .mapStyle(.standard)
                .edgesIgnoringSafeArea(.all)
                .navigationDestination(item: $selectedPlace) { place in
                    PlaceDetailPage(place: place)
                }
            } else {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            }
            
            VStack {
                header
                
                Spacer()
                
                if !showMap {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(combinedPlaces) { place in
                                PlaceCard(place: place) { selectedPlace = place }
                            }
                        }
                        .padding(.top, 8)
                    }
                }

                NavBar(isRoot: true)
            }

        }
        .overlay(alignment: .bottomTrailing) {
            if showMap {
                Button {
                    presentAddLocation()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showTimer) {
            PomodoroTimerView()
        }
        .sheet(item: $addLocationSheet) { item in
            AddLocationView(coordinate: item.coordinate) { place in
                placesStore.add(place)
            }
        }
        .alert("Location unavailable", isPresented: $showAddLocationUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Could not read your current position. Try again after enabling Location Services for QuietSpace in Settings.")
        }
        .onAppear {
            locationManager.startIfNeeded()
            let coordinate: CLLocationCoordinate2D
            if let loc = locationManager.currentLocation {
                coordinate = loc.coordinate
            } else {
                coordinate = CLLocationCoordinate2D(latitude: AppConfig.defaultLatitude, longitude: AppConfig.defaultLongitude)
            }

            position = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )

            mapViewModel.loadQuietSpaces(
                around: coordinate,
                radiusMeters: Int(searchRadius),
                category: selectedCategory,
                showCommunityPlaces: showCommunityPlaces
            )

            Task {
                if let uid = auth.userId {
                    unreadNotifications = await SupabaseService.shared.getUnreadNotificationCount(userId: uid)
                } else {
                    unreadNotifications = 0
                }
            }
        }
        .onChange(of: selectedCategory) { _, _ in reload() }
        .onChange(of: searchRadius) { _, _ in reload() }
        .onChange(of: showCommunityPlaces) { _, _ in reload() }
        .onChange(of: showTransit) { _, new in
            guard let loc = locationManager.currentLocation else { return }
            if new { mapViewModel.loadTransitStops(around: loc.coordinate, radiusMeters: Int(searchRadius)) }
            else { mapViewModel.transitStops = [] }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(firstName)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                    Text("Find your quiet space")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 10) {
                    if auth.userId != nil {
                        NavigationLink {
                            NotificationsListView()
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell")
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(width: 40, height: 40)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                if unreadNotifications > 0 {
                                    Text(unreadNotifications > 9 ? "9+" : "\(unreadNotifications)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                        .offset(x: 6, y: -6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        showTimer = true
                    } label: {
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    if showMap {
                        Button {
                            showTransit.toggle()
                        } label: {
                            Image(systemName: "tram")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(showTransit ? .white : .blue)
                                .frame(width: 40, height: 40)
                                .background(showTransit ? Color.blue : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        showMap.toggle()
                    } label: {
                        Image(systemName: showMap ? "list.bullet" : "map")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MainMapViewModel.Category.allCases) { c in
                        Button {
                            selectedCategory = c
                        } label: {
                            Text(c.label)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedCategory == c ? Color.blue.opacity(0.2) : Color.white)
                                .foregroundColor(selectedCategory == c ? .blue : .gray)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Distance")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(searchRadius / 1000)) km")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                Slider(value: $searchRadius, in: 1000...20000, step: 500)
                Toggle("Show community places", isOn: $showCommunityPlaces)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 50)
        .padding(.bottom, 12)
        .background(Color.white.opacity(0.96))
    }

    /// API places + session-local user-added places, filtered by the active category chip.
    private var combinedPlaces: [Place] {
        let extra = placesStore.places.filter {
            selectedCategory == .all || $0.type == selectedCategory.rawValue
        }
        return mapViewModel.places + extra
    }

    private var firstName: String {
        if let n = auth.fullName, let first = n.split(separator: " ").first { return String(first) }
        return "Explorer"
    }

    private func presentAddLocation() {
        guard let loc = locationManager.currentLocation else {
            showAddLocationUnavailableAlert = true
            return
        }
        addLocationSheet = AddLocationSheetItem(coordinate: loc.coordinate)
    }

    private func reload() {
        guard let loc = locationManager.currentLocation else { return }
        mapViewModel.loadQuietSpaces(
            around: loc.coordinate,
            radiusMeters: Int(searchRadius),
            category: selectedCategory,
            showCommunityPlaces: showCommunityPlaces
        )
        if showTransit {
            mapViewModel.loadTransitStops(around: loc.coordinate, radiusMeters: Int(searchRadius))
        }
    }
}

// Helper view for category chips
struct CategoryChip: View {
    var name: String
    var isSelected: Bool = false
    
    var body: some View {
        Text(name)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color(red: 0.6, green: 0.8, blue: 0.7) : Color.white)
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
    }
}

