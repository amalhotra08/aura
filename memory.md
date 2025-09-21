### Aura – Developer Memory (Onboarding Notes)

This document condenses the project context, architecture, and implementation details so any developer can get productive quickly.

### What this app is
- **Purpose**: A SwiftUI iOS app that visualizes global animal congregation points on a stylized, wireframe 3D globe and displays a real‑time frequency chart sourced from a sensor.
- **Aesthetic**: “Data‑Driven Command Center” (Tech‑Noir / Sci‑Fi HUD). Dark background, high contrast light/cyan accents, thin separators, uppercase section titles.

### High‑level architecture
- **SwiftUI shell**: `AuraApp` launches `ContentView`.
- **Dashboard layout**: `ContentView` renders the header, the 3D globe panel, and a live sensor chart panel.
- **3D globe**: `GlobeView` (SceneKit via `UIViewRepresentable`) draws a rotating, interactive wireframe sphere and overlays lat/lon‑based markers with tap detection.
- **Data**: `animals.json` (bundled) → `AnimalDataStore` decodes to `SightingLocation` models.
- **Chart**: `SensorChartView` uses Swift Charts for real‑time line updates backed by `SensorDataModel` (simulated timer; replace with live sensor feed).

### Core files and roles
- `Aura/Aura/AuraApp.swift`: App entry point.
- `Aura/Aura/ContentView.swift`: Dashboard UI + sheet for marker details.
- `Aura/Aura/Theme.swift`: HUD theme (colors, fonts, `HUDPanel`).
- `Aura/Aura/Models.swift`: Data models (`Animal`, `SightingLocation`) and `AnimalDataStore` loader (with sample fallback).
- `Aura/Aura/GlobeView.swift`: SceneKit globe, camera, lighting, markers, and tap handling.
- `Aura/Aura/SensorChartView.swift`: Lhuhive frequency chart and `SensorDataModel` ticking source.
- `Aura/Aura/animals.json`: Bundled dataset for initial prototype.

### UI/UX design system
- **Colors**: Off‑black background (#111111), dark panels, thin 1px separators, primary text near‑white, accent cyan `#00E5FF`.
- **Typography**: Rounded system fonts via helpers: `hudTitle`, `hudBody`, `hudNumber`; uppercase section headers.
- **Panels**: `HUDPanel` wraps module content with header + divider + bordered rounded rectangle.

### Globe rendering details (`GlobeView`)
- **Scene setup**:
  - `SCNView` with `allowsCameraControl = true` for orbit + pinch‑zoom, multisampling antialiasing.
  - Camera at `z=3`. Ambient + directional lights. Icons benefit from light; wireframe uses constant lighting.
- **Wireframe sphere**:
  - `SCNSphere(radius: 1.0, segmentCount: 96)`.
  - Material: `lightingModel = .constant`, `fillMode = .lines`, `isDoubleSided = true`, `writesToDepthBuffer = false` (keeps markers readable above the grid).
  - Slow continuous rotation via `SCNAction` (user interaction can override at runtime).
- **Markers**:
  - Position computed from latitude/longitude on sphere radius ≈ `1.03` so they float just above the mesh.
  - Node group contains a glowing dot (`SCNSphere`) + a billboarded icon (`SCNPlane`) tinted with the accent color; subtle pulse animation.
  - Node naming: `marker-<location.id>` for simple hit testing.
- **Interaction**:
  - Tap → hit‑test nodes prefixed with `marker-` → set `selectedLocation` → SwiftUI sheet (`LocationDetailSheet`).
  - Orbit/zoom handled by SceneKit’s default camera controller (turntable mode); inertia enabled.

### Coordinate math (markers)
```swift
let lat = Float(latitude * .pi / 180.0)
let lon = Float(longitude * .pi / 180.0)
let x = r * cos(lat) * cos(lon)
let y = r * sin(lat)
let z = r * cos(lat) * sin(lon)
```

### Data model and dataset
- **Schema** (JSON array):
```json
{
  "id": "unique-id",
  "latitude": 71.0,
  "longitude": -42.0,
  "animals": [ { "name": "Polar Bear", "symbolSystemName": "pawprint" } ]
}
```
- **Loading**: `AnimalDataStore.loadBundled()` loads `animals.json` from the main bundle; falls back to in‑code sample if missing/invalid.
- **Icons**: `symbolSystemName` uses SF Symbols (e.g., "pawprint", "tortoise", "fish").

### Real‑time chart
- **View**: `SensorChartView` with Swift Charts `LineMark`; cyan gradient stroke, smoothed interpolation, fixed Y domain (0–100).
- **Model**: `SensorDataModel` appends `SensorSample` every 0.1s, keeping the last ~120 points.
- **Replace with real sensor**: Swap `startSimulated()` with your data source (Combine, delegate, sockets). Ensure updates occur on the main thread and cap array length.
```swift
func start(with publisher: AnyPublisher<Double, Never>) {
  stop()
  samples.removeAll()
  cancellable = publisher
    .receive(on: DispatchQueue.main)
    .sink { v in
      samples.append(.init(time: Date(), value: v.clamped(to: 0...100)))
      if samples.count > maxPoints { samples.removeFirst(samples.count - maxPoints) }
    }
}
```

### App flow
1. `ContentView.onAppear` → `AnimalDataStore.loadBundled()` and `SensorDataModel.startSimulated()`.
2. `GlobeView` receives `locations` and rebuilds markers on change.
3. Tap marker → shows `LocationDetailSheet` with coordinates and animal list.

### Build/run
- **Requirements**: Xcode 15+, iOS 16+ (for Swift Charts). SceneKit is available on iOS.
- **Run**: Open `Aura.xcodeproj`, choose an iOS simulator (e.g., iPhone 15 Pro), Build & Run.

### Extensibility & next steps
- Add pan gestures or custom camera limits if turntable defaults need tuning.
- Pause/resume auto‑rotation on user interaction.
- Cluster markers, group by species, or draw arcs/links between related locations.
- Stream dataset updates (websocket) and animate marker intensity based on frequency.
- Expand HUD: segmented meters, alerts, and compact info panels.

### Troubleshooting
- **Globe lines too faint**: increase material alpha or `segmentCount`.
- **Markers behind lines**: ensure sphere material `writesToDepthBuffer = false`.
- **Not interactive**: verify `allowsCameraControl = true` on `SCNView`.
- **Build errors with `.pi`**: use correctly typed constants (`Float.pi`, `CGFloat(Double.pi)`).

### Current status (first stage)
- Implemented: HUD theming, dashboard layout, interactive wireframe globe with markers + tap sheet, bundled dataset loader, and live line chart with simulated data.
- Pending: Final HUD polish, real sensor integration, optional camera behavior customizations, and richer marker/legend UI.


