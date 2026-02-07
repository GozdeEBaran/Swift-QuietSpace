import SwiftUI

struct AppColors {
    let colorScheme: ColorScheme
    
    init(_ colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }
    
    var primary: Color { .blue }
    var primaryLight: Color { .blue.opacity(0.2) }
    var textPrimary: Color { colorScheme == .dark ? .white : .black }
    var textSecondary: Color { .gray }
    var textMuted: Color { .gray.opacity(0.6) }
    var accent: Color { .orange }
    var surface: Color { colorScheme == .dark ? Color(UIColor.systemGray6) : .white }
    var border: Color { .gray.opacity(0.3) }
    var background: Color { colorScheme == .dark ? .black : Color(UIColor.systemGroupedBackground) }
    var textOnPrimary: Color { .white }
    var surfaceVariant: Color { colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.systemGray6) }
    var error: Color { .red }
}
