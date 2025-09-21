//
//  FarmView.swift
//  Aura
//
//  Mesh-style network visualization with multi-select and frequency indicator
//

import SwiftUI

struct FarmView: View {
    @State private var alertNodeIndex: Int? = nil
    @State private var selectedAnimals: Set<String> = ["Deer", "Ground Hog", "Fox", "Rabbit", "Squirrel"]
    @State private var nodeStatusAlert: NodeStatusAlert?

    private let allAnimals: [String] = [
        "Cattle", "Sheep", "Goat", "Pig", "Chicken", "Duck", "Turkey",
        "Horse", "Donkey", "Alpaca", "Llama", "Rabbit", "Bee",
        "Dog", "Cat", "Buffalo", "Yak", "Deer", "Camel", "Ostrich",
        "Quail", "Pigeon", "Fish", "Shrimp", "Crab", "Goose", "Emu",
        "Fox", "Squirrel", "Ground Hog"
    ]

    var body: some View {
        ZStack {
            HUDTheme.background.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    header

                    HUDPanel(title: "Farm Mesh Network") {
                        MeshNetworkView(nodeCount: 5, alertIndex: alertNodeIndex, onTap: { idx, isAlerted in
                            if isAlerted {
                                nodeStatusAlert = NodeStatusAlert(title: "Node Status", message: "Currently active — noise detected.")
                            } else {
                                nodeStatusAlert = NodeStatusAlert(title: "Node Status", message: "Operational")
                            }
                        })
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: HUDTheme.cornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: HUDTheme.cornerRadius, style: .continuous)
                                    .stroke(HUDTheme.line, lineWidth: 1)
                            )
                    }

                HUDPanel(title: "Animals (Auto-filled by location)") {
                    VStack(alignment: .leading, spacing: 12) {
                        Menu {
                            ScrollView {
                                VStack(alignment: .leading) {
                                    ForEach(allAnimals, id: \.self) { animal in
                                        Button(action: { toggleSelection(animal) }) {
                                            HStack {
                                                Image(systemName: selectedAnimals.contains(animal) ? "checkmark.square.fill" : "square")
                                                    .foregroundStyle(HUDTheme.accent)
                                                Text(animal).foregroundStyle(HUDTheme.textPrimary)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .foregroundStyle(HUDTheme.accent)
                                Text("Select Animals")
                                    .font(.hudBody)
                                    .foregroundStyle(HUDTheme.textPrimary)
                                Spacer(minLength: 0)
                                Text("\(selectedAnimals.count) selected")
                                    .font(.hudBody)
                                    .foregroundStyle(HUDTheme.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(HUDTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(HUDTheme.line, lineWidth: 1)
                            )
                        }

                        // Selected chips
                        let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                            ForEach(Array(selectedAnimals).sorted(), id: \.self) { animal in
                                HStack(spacing: 6) {
                                    Text(animal)
                                        .font(.hudBody)
                                        .foregroundStyle(HUDTheme.textPrimary)
                                    Button(action: { toggleSelection(animal) }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(HUDTheme.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(HUDTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(HUDTheme.line, lineWidth: 1)
                                )
                            }
                        }
                    }
                }

                // Frequencies panel (three static best frequencies)
                HUDPanel(title: "Frequencies") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 16) {
                            FrequencyPill(value: 14)
                            FrequencyPill(value: 19)
                            FrequencyPill(value: 21)
                            Spacer(minLength: 0)
                        }
                        Text("Best frequencies chosen to deter selected animals: \(selectedAnimals.sorted().joined(separator: ", "))")
                            .font(.hudBody)
                            .foregroundStyle(HUDTheme.textSecondary)
                    }
                }
                }
                .padding(16)
                .padding(.top, 8)
            }
        }
        .onAppear { /* Frequencies are static for now */ }
        .alert(item: $nodeStatusAlert) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("FARM OPERATIONS")
                .font(.hudTitle)
                .foregroundStyle(HUDTheme.textSecondary)
            Spacer()
            HStack(spacing: 12) {
                Button(action: scheduleAlertAfterSync) {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
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

    private func toggleSelection(_ animal: String) {
        if selectedAnimals.contains(animal) {
            selectedAnimals.remove(animal)
        } else {
            selectedAnimals.insert(animal)
        }
    }
}

// MARK: - Mesh Network View

private struct MeshNetworkView: View {
    var nodeCount: Int
    var alertIndex: Int?
    var onTap: ((Int, Bool)) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let points = generatePoints(in: size)
                let threshold = min(size.width, size.height) * 0.18

                // Draw edges
                var edgePath = Path()
                for i in 0..<points.count {
                    for j in (i+1)..<points.count {
                        let p1 = points[i]
                        let p2 = points[j]
                        if distance(p1, p2) <= threshold {
                            edgePath.move(to: p1)
                            edgePath.addLine(to: p2)
                        }
                    }
                }
                context.stroke(edgePath, with: .color(HUDTheme.line), lineWidth: 1)

                // Draw nodes
                for (idx, p) in points.enumerated() {
                    let isAlerted = (alertIndex == idx)
                    let nodeColor = isAlerted ? Color(hex: 0xFF2D55) : Color(hex: 0x2DFF9F)
                    let rect = CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)
                    let circle = Path(ellipseIn: rect)
                    context.fill(circle, with: .color(nodeColor))
                    // Outer glow
                    let glowRect = rect.insetBy(dx: -2, dy: -2)
                    let glow = Path(ellipseIn: glowRect)
                    context.stroke(glow, with: .color(nodeColor.opacity(0.35)), lineWidth: 1)
                }
            }
            .background(HUDTheme.background)
            .contentShape(Rectangle())
            .gesture(
                TapGesture()
                    .onEnded { location in
                        // Map tap to nearest point among generated points
                        // Recompute points with current size to find nearest
                        let size = geo.size
                        let points = generatePoints(in: size)
                        let tap = CGPoint(x: size.width / 2, y: size.height / 2)
                        var nearestIndex = 0
                        var nearestDist = CGFloat.greatestFiniteMagnitude
                        for (idx, p) in points.enumerated() {
                            let d = distance(p, tap)
                            if d < nearestDist { nearestDist = d; nearestIndex = idx }
                        }
                        let isAlerted = (alertIndex == nearestIndex)
                        onTap((nearestIndex, isAlerted))
                    }
            )
        }
    }

    private func generatePoints(in size: CGSize) -> [CGPoint] {
        var points: [CGPoint] = []
        points.reserveCapacity(nodeCount)
        for i in 0..<nodeCount {
            let rx = pseudoRandom(i * 2 + 7)
            let ry = pseudoRandom(i * 2 + 13)
            let x = (0.08 + 0.84 * rx) * size.width
            let y = (0.08 + 0.84 * ry) * size.height
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }

    private func pseudoRandom(_ seed: Int) -> CGFloat {
        let s = sin(Double(seed)) * 43758.5453123
        return CGFloat(s - floor(s))
    }

    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return CGFloat(sqrt(dx * dx + dy * dy))
    }
}

// MARK: - Actions

private extension FarmView {
    func scheduleAlertAfterSync() {
        alertNodeIndex = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            alertNodeIndex = Int.random(in: 0..<5)
            // Auto-clear after 3s
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                alertNodeIndex = nil
            }
        }
    }
}

// MARK: - Frequency Pill

private struct FrequencyPill: View {
    let value: Int // kilohertz
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(value)")
                .font(.hudNumber)
                .foregroundStyle(HUDTheme.accent)
            Text("kHz")
                .font(.hudBody)
                .foregroundStyle(HUDTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(HUDTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(HUDTheme.line, lineWidth: 1)
        )
    }
}

struct NodeStatusAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}


