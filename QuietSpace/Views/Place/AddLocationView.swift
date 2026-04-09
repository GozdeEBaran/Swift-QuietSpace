import SwiftUI
import CoreLocation

/// Simple form to create a local `Place` at the user's current coordinates.
/// Also submits to Supabase `location_submissions` (status: pending) for admin review.
struct AddLocationView: View {
    let coordinate: CLLocationCoordinate2D
    var onSave: (Place) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore

    @State private var name: String = ""
    @State private var selectedType: String = "cafe"
    @State private var address: String = ""
    @State private var isSaving = false
    @State private var saveError: String?

    private let typeOptions: [(id: String, label: String)] = [
        ("library", "Library"),
        ("park", "Park"),
        ("cafe", "Café"),
        ("museum", "Museum")
    ]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Location name", text: $name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Required. This appears on the map and in place details.")
                }

                Section("Category") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(typeOptions, id: \.id) { opt in
                            Text(opt.label).tag(opt.id)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Address (optional)") {
                    TextField("Street or notes", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Coordinates") {
                    LabeledContent("Latitude") {
                        Text(String(format: "%.5f", coordinate.latitude))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Longitude") {
                        Text(String(format: "%.5f", coordinate.longitude))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(!canSave)
                    }
                }
            }
            .alert("Could not save", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private func save() async {
        isSaving = true
        let addr = address.trimmingCharacters(in: .whitespacesAndNewlines)

        let place = Place(
            id: "local-\(UUID().uuidString)",
            googlePlaceId: nil,
            name: trimmedName,
            type: selectedType,
            distance: nil,
            rating: 0,
            reviewCount: 0,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            address: addr.isEmpty ? nil : addr,
            isOpen: true,
            quietScore: PlaceHelpers.estimatedQuietScore(for: selectedType, rating: nil),
            photoReference: nil,
            emoji: PlaceHelpers.emojiForType(selectedType),
            favorite: false,
            phoneNumber: nil,
            website: nil,
            openingHours: nil,
            reviews: nil,
            priceLevel: nil
        )

        // Submit to Supabase for admin review (status: pending).
        // The location appears on the map for everyone once an admin approves it.
        if let userId = auth.userId {
            let submission = LocationSubmissionInsert(
                userId: userId,
                name: trimmedName,
                address: addr.isEmpty ? "Unknown" : addr,
                type: selectedType,
                description: "",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                quietScore: place.quietScore,
                imageUrl: nil,
                status: "pending"
            )
            do {
                _ = try await SupabaseService.shared.createLocationSubmission(submission)
            } catch {
                // Supabase save failed — still add locally so the user's session is not lost.
                print("[AddLocation] Supabase submission failed: \(error.localizedDescription)")
            }
        }

        isSaving = false
        onSave(place)
        dismiss()
    }
}


#Preview {
    AddLocationView(
        coordinate: CLLocationCoordinate2D(latitude: 43.65, longitude: -79.38),
        onSave: { _ in }
    )
    .environmentObject(AuthStore())
}
