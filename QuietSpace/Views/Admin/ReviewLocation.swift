import SwiftUI
import MapKit
import CoreLocation

struct ReviewLocation: View {
    let submission: LocationSubmission

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var isProcessing = false
    @State private var isRunningAI = false
    @State private var showRejectField = false
    @State private var rejectionReason = ""
    @State private var showChecklist = false

    @State private var aiPanel: LocationValidationResult?
    @State private var alertMessage: String?
    @State private var showAlert = false

    @State private var reviewChecklist: [String: Bool] = [
        "nameLooksValid": false,
        "addressLooksValid": false,
        "mapPinAccurate": false,
        "locationCrossChecked": false,
        "descriptionAppropriate": false,
        "tagsRelevant": false,
        "quietScoreReasonable": false,
        "noSpamOrFakeContent": false
    ]

    private let checklistItems: [(key: String, label: String)] = [
        ("nameLooksValid", "Location name looks valid"),
        ("addressLooksValid", "Address looks complete and real"),
        ("mapPinAccurate", "Map pin matches the submitted location"),
        ("locationCrossChecked", "Location existence verified on other platforms or by visit"),
        ("descriptionAppropriate", "Description is clear and appropriate"),
        ("tagsRelevant", "Tags are relevant to the location"),
        ("quietScoreReasonable", "Quiet score seems reasonable"),
        ("noSpamOrFakeContent", "No spam, fake, or misleading content")
    ]

    private var colors: AppColors { AppColors(colorScheme) }

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: submission.latitude ?? AppConfig.defaultLatitude,
            longitude: submission.longitude ?? AppConfig.defaultLongitude
        )
    }

    private var isPending: Bool { (submission.status ?? "") == "pending" }

    var body: some View {
        ZStack(alignment: .bottom) {
            colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    statusBanner

                    mapSection

                    infoCards

                    aiSection

                    checklistSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }

            if isPending {
                bottomBar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            mapPosition = .region(region)
        }
        .alert("Notice", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Text("Review Location")
                .font(.title3.weight(.semibold))
                .foregroundColor(colors.textPrimary)

            Spacer()

            statusChip
        }
        .padding(.vertical, 6)
    }

    private var statusChip: some View {
        Text((submission.status ?? "unknown").capitalized)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch submission.status {
        case "pending": return colors.warning
        case "approved": return colors.primary
        case "rejected": return colors.error
        default: return colors.textMuted
        }
    }

    private var statusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(colors.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text(isPending ? "Pending Approval" : (submission.status ?? "").capitalized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(colors.warning)
                if let created = submission.createdAt {
                    Text("Submitted \(created)")
                        .font(.footnote)
                        .foregroundColor(colors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(colors.warningLight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var mapSection: some View {
        Map(position: $mapPosition) {
            Marker(submission.name ?? "Location", coordinate: coordinate)
        }
        .mapStyle(.standard)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var infoCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            card {
                labeled("LOCATION NAME", submission.name ?? "—")
                labeled("ADDRESS", submission.address ?? "—")
                labeled("TYPE", submission.type ?? "—")
                labeled("QUIET SCORE", submission.quietScore.map { String(format: "%.1f", $0) } ?? "—")
            }

            if let desc = submission.description, !desc.isEmpty {
                card {
                    labeled("DESCRIPTION", desc)
                }
            }

            if let urlStr = submission.imageUrl, let u = URL(string: urlStr) {
                card {
                    Text("PHOTOS")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(colors.textSecondary)
                    AsyncImage(url: u) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFit()
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(colors.textSecondary)
            Text(value)
                .font(.body)
                .foregroundColor(colors.textPrimary)
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                Task { await runAIChecker() }
            } label: {
                HStack {
                    if isRunningAI {
                        ProgressView()
                    }
                    Text(isRunningAI ? "Running AI…" : "Run AI Checker")
                        .font(.headline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(colors.primary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isRunningAI)

            if let ai = aiPanel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suspicion: \(ai.suspicionLevel)")
                        .font(.subheadline.weight(.semibold))
                    Text(ai.reasoning)
                        .font(.footnote)
                        .foregroundColor(colors.textSecondary)
                    if !ai.concerns.isEmpty {
                        Text("Concerns: \(ai.concerns.joined(separator: "; "))")
                            .font(.caption)
                            .foregroundColor(colors.error)
                    }
                }
                .padding(12)
                .background(colors.surfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showChecklist.toggle()
            } label: {
                HStack {
                    Text("Review checklist")
                        .font(.headline.weight(.semibold))
                    Spacer()
                    Image(systemName: showChecklist ? "chevron.up" : "chevron.down")
                }
                .foregroundColor(colors.textPrimary)
            }
            .buttonStyle(.plain)

            if showChecklist {
                ForEach(checklistItems, id: \.key) { item in
                    Button {
                        let cur = reviewChecklist[item.key] ?? false
                        reviewChecklist[item.key] = !cur
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: (reviewChecklist[item.key] ?? false) ? "checkmark.square.fill" : "square")
                                .foregroundColor((reviewChecklist[item.key] ?? false) ? colors.primary : colors.textSecondary)
                            Text(item.label)
                                .font(.footnote)
                                .foregroundColor(colors.textPrimary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    if !showRejectField {
                        showRejectField = true
                        rejectionReason = ""
                        return
                    }
                    guard !rejectionReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        alertMessage = "Please provide a reason for rejection."
                        showAlert = true
                        return
                    }
                    Task { await rejectSubmission() }
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text(showRejectField ? "Confirm reject" : "Reject")
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundColor(colors.error)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(colors.error.opacity(0.65), lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)

                Button {
                    Task { await approveSubmission() }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Approve")
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(colors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)

            if showRejectField {
                TextField("Rejection reason (user will be notified)", text: $rejectionReason, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .background(colors.surface)
        .shadow(color: .black.opacity(0.1), radius: 16, y: -4)
    }

    private func runAIChecker() async {
        isRunningAI = true
        aiPanel = nil
        defer { isRunningAI = false }

        let lat = submission.latitude ?? AppConfig.defaultLatitude
        let lng = submission.longitude ?? AppConfig.defaultLongitude
        let query = "\(submission.name ?? "") \(submission.address ?? "")"

        var placeInfo: GeminiPlaceMatchInfo?
        do {
            let results = try await GooglePlacesService.shared.searchByText(
                query: query,
                latitude: lat,
                longitude: lng
            )
            if let first = results.first {
                let strong = first.name.lowercased().contains((submission.name ?? "").lowercased())
                placeInfo = GeminiPlaceMatchInfo(
                    placeId: first.googlePlaceId,
                    name: first.name,
                    address: first.address,
                    rating: first.rating,
                    userRatingsTotal: first.reviewCount,
                    types: [first.type],
                    latitude: first.latitude,
                    longitude: first.longitude,
                    matchQuality: strong ? "strong" : "weak",
                    matchNotes: "Found via Google Places search"
                )
            }
        } catch {
            // Continue without Places match
        }

        let result = await GeminiAIService.shared.validateLocationSubmission(
            name: submission.name ?? "",
            address: submission.address ?? "",
            type: submission.type ?? "",
            description: submission.description ?? "",
            tags: [],
            placeMatchInfo: placeInfo
        )
        aiPanel = result
        alertMessage = result.isSuspicious
            ? "Warning: \(result.reasoning)"
            : "Looks good: \(result.reasoning)"
        showAlert = true
    }

    private func approveSubmission() async {
        guard let sid = submission.id else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await SupabaseService.shared.updateLocationSubmissionStatus(id: sid, status: "approved")
            if let uid = submission.userId {
                try await SupabaseService.shared.createNotification(
                    userId: uid,
                    type: "location_approved",
                    title: "Location Approved! 📍",
                    message: "Your submitted location \"\(submission.name ?? "Location")\" has been approved and added to QuietSpace."
                )
            }
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func rejectSubmission() async {
        guard let sid = submission.id else { return }
        let reason = rejectionReason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reason.isEmpty else { return }
        isProcessing = true
        defer { isProcessing = false }
        do {
            try await SupabaseService.shared.updateLocationSubmissionStatus(
                id: sid,
                status: "rejected",
                adminNotes: reason
            )
            if let uid = submission.userId {
                try await SupabaseService.shared.createNotification(
                    userId: uid,
                    type: "location_rejected",
                    title: "Location Submission Rejected",
                    message: reason
                )
            }
            dismiss()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        ReviewLocation(
            submission: LocationSubmission(
                id: "1",
                userId: nil,
                name: "Study Hub",
                address: "401 Richmond St",
                type: "Coworking",
                description: "Quiet upstairs.",
                latitude: 43.65,
                longitude: -79.38,
                quietScore: 4,
                imageUrl: nil,
                status: "pending",
                adminNotes: nil,
                createdAt: nil
            )
        )
    }
}
