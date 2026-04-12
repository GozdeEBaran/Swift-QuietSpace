//
//  SettingsToggleRow.swift
//  QuietSpace
//
//

import SwiftUI

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}
