//
//  GlobeView.swift
//  Aura
//

import SwiftUI
import SceneKit

struct GlobeView: UIViewRepresentable {
    let locations: [SightingLocation]
    @Binding var selectedLocation: SightingLocation?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = UIColor(HUDTheme.background)
        view.scene = buildScene()
        view.allowsCameraControl = true
        view.isPlaying = true
        // Configure default camera controller for orbit + zoom
        let controller = view.defaultCameraController
        controller.interactionMode = .orbitTurntable
        controller.inertiaEnabled = true
        controller.maximumVerticalAngle = 90
        controller.minimumVerticalAngle = -90
        view.antialiasingMode = .multisampling4X

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.scnView = view
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Rebuild markers when data changes
        context.coordinator.updateMarkers(locations: locations)
    }

    private func buildScene() -> SCNScene {
        let scene = SCNScene()

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = false
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.contrast = 1.2
        cameraNode.position = SCNVector3(0, 0, 3.0)
        scene.rootNode.addChildNode(cameraNode)

        // Lighting: soft ambient + directional to add depth to icons while wireframe stays constant
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 400
        ambient.color = UIColor(white: 1.0, alpha: 1.0)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let directional = SCNLight()
        directional.type = .directional
        directional.intensity = 600
        let directionalNode = SCNNode()
        directionalNode.light = directional
        directionalNode.eulerAngles = SCNVector3(-Float.pi/3, Float.pi/4, 0)
        scene.rootNode.addChildNode(directionalNode)

        // Wireframe sphere (globe)
        let sphere = SCNSphere(radius: 1.0)
        sphere.segmentCount = 96
        let material = SCNMaterial()
        // Use constant lighting so lines are crisp and visible on dark background
        material.lightingModel = .constant
        material.diffuse.contents = UIColor(HUDTheme.accent).withAlphaComponent(0.6)
        material.fillMode = .lines
        material.isDoubleSided = true
        // Disable writing to depth for the wireframe so markers remain clearly visible
        material.writesToDepthBuffer = false
        sphere.firstMaterial = material
        let sphereNode = SCNNode(geometry: sphere)
        scene.rootNode.addChildNode(sphereNode)

        // Slow rotation
        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat(Double.pi) * 2, z: 0, duration: 40)
        let forever = SCNAction.repeatForever(rotate)
        sphereNode.runAction(forever)

        // Container for markers managed by coordinator
        let markersContainer = SCNNode()
        markersContainer.name = Coordinator.markersContainerName
        scene.rootNode.addChildNode(markersContainer)

        return scene
    }

    final class Coordinator: NSObject {
        static let markersContainerName = "markers-container"
        var parent: GlobeView
        weak var scnView: SCNView?

        init(_ parent: GlobeView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = scnView else { return }
            let location = gesture.location(in: view)
            let hits = view.hitTest(location, options: [.boundingBoxOnly: false])
            guard let node = hits.first(where: { $0.node.name?.hasPrefix("marker-") == true })?.node,
                  let id = node.name?.replacingOccurrences(of: "marker-", with: "")
            else { return }
            if let loc = parent.locations.first(where: { $0.id == id }) {
                parent.selectedLocation = loc
            }
        }

        func updateMarkers(locations: [SightingLocation]) {
            guard let scene = scnView?.scene,
                  let container = scene.rootNode.childNode(withName: Self.markersContainerName, recursively: false)
            else { return }

            // Clear existing
            container.childNodes.forEach { $0.removeFromParentNode() }

            for loc in locations {
                let node = makeMarker(for: loc)
                container.addChildNode(node)
            }
        }

        private func makeMarker(for location: SightingLocation) -> SCNNode {
            let radius: Float = 1.03
            let pos = positionOnSphere(latitude: location.latitude, longitude: location.longitude, radius: radius)

            // Glowing dot
            let dot = SCNSphere(radius: 0.02)
            let m = SCNMaterial()
            m.diffuse.contents = UIColor.clear
            m.emission.contents = UIColor(HUDTheme.accent)
            m.emission.intensity = 1.0
            dot.firstMaterial = m
            let dotNode = SCNNode(geometry: dot)
            dotNode.position = pos

            // Billboarded icon plane (single representative icon)
            let plane = SCNPlane(width: 0.1, height: 0.1)
            let iconMaterial = SCNMaterial()
            let symbolName = location.animals.first?.symbolSystemName ?? "pawprint"
            let image = UIImage(systemName: symbolName) ?? UIImage(systemName: "pawprint")!
            iconMaterial.diffuse.contents = image.withTintColor(UIColor(HUDTheme.accent), renderingMode: .alwaysOriginal)
            iconMaterial.emission.contents = UIColor(HUDTheme.accent)
            iconMaterial.emission.intensity = 0.9
            iconMaterial.isDoubleSided = true
            plane.firstMaterial = iconMaterial
            let iconNode = SCNNode(geometry: plane)
            iconNode.constraints = [SCNBillboardConstraint()] // Always face camera
            iconNode.position = SCNVector3(pos.x * 1.01, pos.y * 1.01, pos.z * 1.01)

            // Group
            let group = SCNNode()
            group.name = "marker-\(location.id)"
            group.addChildNode(dotNode)
            group.addChildNode(iconNode)

            // Subtle pulse
            let up = SCNAction.scale(to: 1.25, duration: 0.9)
            let down = SCNAction.scale(to: 1.0, duration: 0.9)
            up.timingMode = .easeInEaseOut
            down.timingMode = .easeInEaseOut
            let pulse = SCNAction.repeatForever(.sequence([up, down]))
            group.runAction(pulse)

            return group
        }

        private func positionOnSphere(latitude: Double, longitude: Double, radius: Float) -> SCNVector3 {
            let lat = Float(latitude * .pi / 180.0)
            let lon = Float(longitude * .pi / 180.0)
            let x = radius * cos(lat) * cos(lon)
            let y = radius * sin(lat)
            let z = radius * cos(lat) * sin(lon)
            return SCNVector3(x, y, z)
        }
    }
}


