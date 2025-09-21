//
//  ContentView.swift
//  Aura
//
//  Created by Akshaya Lohia on 9/20/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuraOn: Bool = true

    var body: some View {
        ZStack {
            HUDTheme.background.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    CarAuraPanel(isAuraOn: $isAuraOn)
                    HUDPanel(title: "Frequency (Live)") {
                        HStack(alignment: .firstTextBaseline) {
                            Text(isAuraOn ? "16" : "--")
                                .font(.hudNumber)
                                .foregroundStyle(HUDTheme.accent)
                            Text("kilohertz")
                                .font(.hudBody)
                                .foregroundStyle(HUDTheme.textSecondary)
                            Spacer()
                        }
                        .frame(height: 60)
                    }
                }
                .padding(16)
                .padding(.top, 8)
            }
        }
        .onAppear {
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("MISSION STATUS")
                .font(.hudTitle)
                .foregroundStyle(HUDTheme.textSecondary)
            Spacer()
            HStack(spacing: 12) {
                Label("Create New Session", systemImage: "plus")
                    .font(.hudBody)
                    .foregroundStyle(HUDTheme.background)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(HUDTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Car", systemImage: "car.fill")
                }
                .tag(0)

            FarmView()
                .tabItem {
                    Label("Farm", systemImage: "leaf.fill")
                }
                .tag(1)
        }
        .tint(HUDTheme.accent)
        .background(HUDTheme.background)
        .toolbarBackground(HUDTheme.panel, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    MainTabView()
}

// MARK: - Car Aura Panel

private struct CarAuraPanel: View {
    @Binding var isAuraOn: Bool
    @State private var speedScale: Double = 0.6 // slow waves

    var body: some View {
        HUDPanel(title: "Aura Sensor") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Toggle(isOn: $isAuraOn) {
                        Text(isAuraOn ? "AURA ON" : "AURA OFF")
                            .font(.hudBody)
                            .foregroundStyle(isAuraOn ? HUDTheme.textSecondary : HUDTheme.textSecondary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: HUDTheme.accent))
                    Spacer(minLength: 0)
                }

                ZStack {
                    CarTopIcon()
                        .frame(height: 320)
                        .overlay(
                            BumperDotAndPulse(isActive: isAuraOn, speedScale: speedScale)
                        )
                }
                .frame(maxWidth: .infinity)
                .background(HUDTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: HUDTheme.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: HUDTheme.cornerRadius, style: .continuous)
                        .stroke(HUDTheme.line, lineWidth: 1)
                )
            }
        }
    }
}

private struct CarTopIcon: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let carWidth = min(w * 0.35, 160)
            let carHeight = h * 0.78
            let x = w * 0.5 - carWidth / 2
            let y = h * 0.15

            ZStack {
                Image("carIcon")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: carWidth, height: carHeight)
                    .position(x: w * 0.5, y: y + carHeight / 2)
            }
        }
    }
}

private struct BumperDotAndPulse: View {
    var isActive: Bool
    var speedScale: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let carWidth = min(w * 0.25, 120)
            let carHeight = h * 0.7
            let carTopY = h * 0.15
            let bumperCenter = CGPoint(x: w * 0.5, y: carTopY)

            ZStack {
                // Bumper dot
                Circle()
                    .fill(HUDTheme.accent)
                    .frame(width: 8, height: 8)
                    .position(bumperCenter)

                if isActive {
                    TimelineView(.animation) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate * speedScale
                        PulseWaves(center: bumperCenter, time: t)
                    }
                }
            }
        }
    }
}

private struct PulseWaves: View {
    let center: CGPoint
    let time: TimeInterval

    private let waveCount: Int = 3
    private let waveDuration: Double = 2.6

    var body: some View {
        Canvas { context, size in
            let maxRadius = max(size.width, size.height) * 0.6
            let baseTime = time.remainder(dividingBy: waveDuration)

            for i in 0..<waveCount {
                let phaseOffset = Double(i) / Double(waveCount)
                let phase = (baseTime / waveDuration + phaseOffset).remainder(dividingBy: 1.0)
                let radius = max(0.0, phase) * maxRadius
                var path = Path()
                path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                let opacity = 1.0 - phase
                context.stroke(path, with: .color(HUDTheme.accent.opacity(opacity)), lineWidth: 2)
            }
        }
    }
}

struct LocationDetailSheet: View {
    let location: SightingLocation
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LOCATION")
                .font(.hudTitle)
                .foregroundStyle(HUDTheme.textSecondary)
            Divider().overlay(HUDTheme.line)
            Text("Lat: \(location.latitude, specifier: "%.2f")  Lon: \(location.longitude, specifier: "%.2f")")
                .font(.hudBody)
                .foregroundStyle(HUDTheme.textPrimary)
            Text("ANIMALS")
                .font(.hudTitle)
                .foregroundStyle(HUDTheme.textSecondary)
            ForEach(location.animals) { animal in
                HStack(spacing: 12) {
                    Image(systemName: animal.symbolSystemName ?? "pawprint")
                        .foregroundStyle(HUDTheme.accent)
                    Text(animal.name)
                        .foregroundStyle(HUDTheme.textPrimary)
                        .font(.hudBody)
                }
            }
            Spacer()
        }
        .padding(20)
        .background(HUDTheme.background)
        .presentationDetents([.medium, .large])
    }
}
