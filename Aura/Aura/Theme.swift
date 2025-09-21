//
//  Theme.swift
//  Aura
//
//  Tech-Noir HUD theme primitives
//

import SwiftUI

struct HUDTheme {
    // Core palette
    static let background = Color(hex: 0x111111)
    static let panel = Color(hex: 0x161616)
    static let line = Color.white.opacity(0.12)
    static let textPrimary = Color(white: 0.92)
    static let textSecondary = Color(white: 0.75)
    static let accent = Color(hex: 0x00E5FF) // electric cyan

    // Metrics
    static let cornerRadius: CGFloat = 12
    static let panelPadding: CGFloat = 16
}

extension Font {
    static var hudTitle: Font { .system(size: 14, weight: .semibold, design: .rounded) }
    static var hudNumber: Font { .system(size: 28, weight: .bold, design: .rounded) }
    static var hudBody: Font { .system(size: 13, weight: .regular, design: .rounded) }
}

struct HUDPanel<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title.uppercased())
                    .font(.hudTitle)
                    .foregroundStyle(HUDTheme.textSecondary)
                Spacer(minLength: 0)
            }
            Divider().overlay(HUDTheme.line)
            content()
        }
        .padding(HUDTheme.panelPadding)
        .background(HUDTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: HUDTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HUDTheme.cornerRadius, style: .continuous)
                .stroke(HUDTheme.line, lineWidth: 1)
        )
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}


