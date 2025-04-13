//
//  ObjectTrackingRealityView.swift
//  XR-App
//
//  Created by Lisa Kohls on 22.03.25.

/*
 Abstract:
 The view shown inside the immersive space.
 */

import RealityKit
import ARKit
import SwiftUI
import RealityKitContent

// MARK: - Hilfsfunktionen

extension simd_float4x4 {
    var translation: SIMD3<Float> {
        SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension Transform {
    var translation: SIMD3<Float> {
        self.matrix.translation
    }
}

// MARK: - RealityView

@MainActor
struct ObjectTrackingRealityView: View {

    @ObservedObject var appState: AppState
    var root = Entity()
    
    @State private var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]
    @State private var toneGenerators: [UUID: SpatialToneGenerator] = [:]

    var body: some View {
        RealityView { content in
            content.add(root)

            // ✅ Kamera-Entity außerhalb der Task finden (nur einmal)
            let cameraEntity = content.entities.first(where: {
                $0.components[PerspectiveCameraComponent.self] != nil
            })

            // ✅ Starte Object Tracking in Task (MainActor-konform)
            Task { @MainActor in
                let objectTracking = await appState.startTracking()
                guard let objectTracking else { return }

                for await anchorUpdate in objectTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    let id = anchor.id
                    var detectedObject = anchor.referenceObject.name.lowercased().replacingOccurrences(of: "_", with: " ")
                    
                    switch detectedObject {
                    case "mug":
                        detectedObject = "tasse"
                    case "spices":
                        detectedObject = "gewürz"
                    case "bell peppers":
                        detectedObject = "paprika"
                    default:
                        break;
                    }
                    
                    print("detectedObject: \(detectedObject)")

                    if detectedObject == appState.recognizedText {
                        switch anchorUpdate.event {
                        case .added:
                            let model = appState.referenceObjectLoader
                                .usdzsPerReferenceObjectID[anchor.referenceObject.id]
                            let visualization = ObjectAnchorVisualization(for: anchor, withModel: model)
                            self.objectVisualizations[id] = visualization
                            root.addChild(visualization.entity)

                            let toneGen = SpatialToneGenerator()
                            toneGenerators[id] = toneGen

                            let pos = anchor.originFromAnchorTransform.translation
                            toneGen.updateSourcePosition(x: pos.x, y: pos.y, z: pos.z)

                        case .updated:
                            self.objectVisualizations[id]?.update(with: anchor)

                            if let generator = toneGenerators[id],
                               let cameraEntity {

                                let pos = anchor.originFromAnchorTransform.translation
                                generator.updateSourcePosition(x: pos.x, y: pos.y, z: pos.z)

                                let cameraPos = cameraEntity.transform.translation
                                let distance = simd_distance(cameraPos, pos)

                                generator.updateDistanceFeedback(distance: distance)
                                generator.updateListenerPosition(
                                    x: cameraPos.x,
                                    y: cameraPos.y,
                                    z: cameraPos.z
                                )
                            }

                        case .removed:
                            self.objectVisualizations[id]?.entity.removeFromParent()
                            self.objectVisualizations.removeValue(forKey: id)

                            toneGenerators[id]?.stop()
                            toneGenerators.removeValue(forKey: id)
                        }
                    }
                }
            }
        }
        .onAppear {
            appState.isImmersiveSpaceOpened = true
        }
        .onDisappear {
            for (_, visualization) in objectVisualizations {
                root.removeChild(visualization.entity)
            }
            objectVisualizations.removeAll()

            for (_, generator) in toneGenerators {
                generator.stop()
            }
            toneGenerators.removeAll()

            appState.didLeaveImmersiveSpace()
        }
    }
}
