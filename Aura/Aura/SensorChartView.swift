//
//  SensorChartView.swift
//  Aura
//

import SwiftUI
import Charts

struct SensorSample: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}

final class SensorDataModel: ObservableObject {
    @Published var samples: [SensorSample] = []
    private var timer: Timer?
    private let maxPoints = 120 // keep last ~12s at 0.1s refresh

    func startSimulated() {
        stop()
        samples.removeAll()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let now = Date()
            // Simulated noisy frequency value 0..100
            let base = 50 + 40 * sin(now.timeIntervalSince1970 / 2.0)
            let noise = Double.random(in: -8...8)
            let v = max(0, min(100, base + noise))
            samples.append(SensorSample(time: now, value: v))
            if samples.count > maxPoints { samples.removeFirst(samples.count - maxPoints) }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

struct SensorChartView: View {
    @ObservedObject var model: SensorDataModel

    var body: some View {
        HUDPanel(title: "Frequency (Live)") {
            Chart(model.samples) { sample in
                LineMark(
                    x: .value("Time", sample.time),
                    y: .value("Value", sample.value)
                )
                .foregroundStyle(HUDTheme.accent.gradient)
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: 0...100)
            .frame(height: 180)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine().foregroundStyle(HUDTheme.line)
                    AxisTick().foregroundStyle(HUDTheme.line)
                    AxisValueLabel() { Text("\(value.as(Double.self) ?? 0, specifier: "%.0f")") }
                        .foregroundStyle(HUDTheme.textSecondary)
                        .font(.hudBody)
                }
            }
        }
    }
}


