import SwiftUI

// MARK: - Enums for Options

enum NoiseLevel: String, CaseIterable {
    case noisy = "Noisy"
    case moderate = "Moderate"
    case veryQuiet = "Very Quiet"
    
    var icon: String {
        switch self {
        case .noisy: return "speaker.wave.3.fill"
        case .moderate: return "speaker.wave.2.fill"
        case .veryQuiet: return "speaker.slash.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .noisy: return Color(red: 0.85, green: 0.55, blue: 0.45)
        case .moderate: return Color(red: 0.95, green: 0.85, blue: 0.55)
        case .veryQuiet: return Color(red: 0.45, green: 0.65, blue: 0.75)
        }
    }
}

enum BusynessLevel: String, CaseIterable {
    case empty = "Empty"
    case steady = "Steady"
    case full = "Full"
    
    var icon: String {
        switch self {
        case .empty: return "person"
        case .steady: return "person.2.fill"
        case .full: return "person.3.fill"
        }
    }
}

enum WifiQuality: String, CaseIterable {
    case good = "Good Wifi"
    case poor = "No/Poor Wifi"
    
    var icon: String {
        switch self {
        case .good: return "wifi"
        case .poor: return "wifi.slash"
        }
    }
}

enum OutletAvailability: String, CaseIterable {
    case plenty = "Plenty"
    case scarce = "Scarce"
}

// MARK: - CheckInPage

struct CheckInPage: View {
    let placeName: String
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedNoise: NoiseLevel? = nil
    @State private var selectedBusyness: BusynessLevel? = nil
    @State private var selectedWifi: WifiQuality? = nil
    @State private var selectedOutlets: OutletAvailability? = nil
    @State private var note: String = ""
    
    private var colors: AppColors { AppColors(colorScheme) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(colors.textPrimary)
                        .padding(10)
                        .background(colors.surface)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                
                Text("Check In")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(colors.textPrimary)
                    .padding(.leading, 8)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // MARK: - Place Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(placeName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(colors.textPrimary)
                        
                        Text("Confirm your visit")
                            .font(.system(size: 14))
                            .foregroundStyle(colors.textSecondary)
                    }
                    
                    // MARK: - Noise Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How quiet is it right now?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(colors.textPrimary)
                        
                        HStack(spacing: 10) {
                            ForEach(NoiseLevel.allCases, id: \.self) { level in
                                OptionChip(
                                    title: level.rawValue,
                                    icon: level.icon,
                                    isSelected: selectedNoise == level,
                                    selectedColor: level.color
                                ) {
                                    selectedNoise = level
                                }
                            }
                        }
                    }
                    
                    // MARK: - Busyness
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How busy is it?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(colors.textPrimary)
                        
                        HStack(spacing: 10) {
                            ForEach(BusynessLevel.allCases, id: \.self) { level in
                                OptionChip(
                                    title: level.rawValue,
                                    icon: level.icon,
                                    isSelected: selectedBusyness == level,
                                    selectedColor: Color(red: 0.95, green: 0.85, blue: 0.55)
                                ) {
                                    selectedBusyness = level
                                }
                            }
                        }
                    }
                    
                    // MARK: - Wifi Quality
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Internet quality?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(colors.textPrimary)
                        
                        HStack(spacing: 10) {
                            ForEach(WifiQuality.allCases, id: \.self) { quality in
                                OptionChip(
                                    title: quality.rawValue,
                                    icon: quality.icon,
                                    isSelected: selectedWifi == quality,
                                    selectedColor: Color(red: 0.45, green: 0.65, blue: 0.65)
                                ) {
                                    selectedWifi = quality
                                }
                            }
                        }
                    }
                    
                    // MARK: - Outlets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Are there outlets?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(colors.textPrimary)
                        
                        HStack(spacing: 10) {
                            ForEach(OutletAvailability.allCases, id: \.self) { availability in
                                OptionChip(
                                    title: availability.rawValue,
                                    icon: nil,
                                    isSelected: selectedOutlets == availability,
                                    selectedColor: Color(red: 0.45, green: 0.65, blue: 0.65)
                                ) {
                                    selectedOutlets = availability
                                }
                            }
                        }
                    }
                    
                    // MARK: - Note
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Add a note (optional)", text: $note)
                            .font(.system(size: 14))
                            .foregroundStyle(colors.textPrimary)
                            .padding(.vertical, 12)
                        
                        Divider()
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // MARK: - Confirm Button
            Button(action: {
                // Handle check-in
                print("Check-in confirmed")
                dismiss()
            }) {
                Text("Confirm Check In")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.45, green: 0.65, blue: 0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(colors.surface)
        .navigationBarHidden(true)
    }
}

// MARK: - Option Chip Component

struct OptionChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    private var colors: AppColors { AppColors(colorScheme) }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
            }
            .foregroundStyle(isSelected ? colors.textPrimary : colors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? selectedColor : colors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : colors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    CheckInPage(placeName: "Toronto Reference Library")
}
