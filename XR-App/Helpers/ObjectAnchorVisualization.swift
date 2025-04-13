//
//  ObjectAnchorVisualization.swift
//  XR-App
//
//  Created by Lisa Kohls on 22.03.25.

/*
Abstract:
The visualization of an object anchor.
*/

import ARKit
import RealityKit
import SwiftUI
import UIKit

@MainActor
class ObjectAnchorVisualization {
    
    private let textBaseHeight: Float = 0.08
    private let alpha: CGFloat = 1
    
    var boundingBoxOutline: BoundingBoxOutline
    var entity: Entity

    init(for anchor: ObjectAnchor, withModel model: Entity? = nil) {
        boundingBoxOutline = BoundingBoxOutline(anchor: anchor, alpha: alpha)
        let entity = Entity()
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.isEnabled = anchor.isTracked
        
        // ✅ 3D-Text erzeugen
        let font = MeshResource.Font(name: "Helvetica", size: CGFloat(textBaseHeight))!
        let mesh = MeshResource.generateText(
            anchor.referenceObject.name.replacingOccurrences(of: "_", with: " "),
            extrusionDepth: textBaseHeight * 0.05,
            font: font
        )
        
        let material = UnlitMaterial(color: .white)
        let text = ModelEntity(mesh: mesh, materials: [material])
        
        // ✅ Transform sauber setzen
        let textPosition = SIMD3<Float>(
            x: anchor.boundingBox.center.x - mesh.bounds.max.x / 2,
            y: anchor.boundingBox.extent.y,
            z: 0 // oder ggf. anchor.boundingBox.center.z
        )

        text.transform = Transform(
            scale: .one,
            rotation: .init(),
            translation: textPosition
        )

        // ✅ Komponenten hinzufügen
        entity.addChild(text)
        entity.addChild(boundingBoxOutline.entity)
        
        self.entity = entity
        
        // ✅ Optional: Drahtgittermodell anzeigen
        if let model {
            var wireFrameMaterial = PhysicallyBasedMaterial()
            wireFrameMaterial.triangleFillMode = .lines
            wireFrameMaterial.faceCulling = .back
            wireFrameMaterial.baseColor = .init(tint: .red)
            wireFrameMaterial.blending = .transparent(opacity: 0.4)
            
            self.applyMaterialRecursively(withModel: model, withMaterial: wireFrameMaterial)
            self.entity.addChild(model)
        }
    }
    
    private func applyMaterialRecursively(withModel model: Entity, withMaterial material: RealityFoundation.Material) {
        if let modelEntity = model as? ModelEntity {
            modelEntity.model?.materials = [material]
        }
        for child in model.children {
            applyMaterialRecursively(withModel: child, withMaterial: material)
        }
    }
    
    func update(with anchor: ObjectAnchor) {
        entity.isEnabled = anchor.isTracked
        guard anchor.isTracked else { return }
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        boundingBoxOutline.update(with: anchor)
    }

    // MARK: - BoundingBoxOutline
    
    @MainActor
    class BoundingBoxOutline {
        private let thickness: Float = 0.004
        private var extent: SIMD3<Float> = .zero
        private var wires: [Entity] = []
        var entity: Entity

        fileprivate init(anchor: ObjectAnchor, color: UIColor = .red, alpha: CGFloat = 1.0) {
            let entity = Entity()
            
            let materials = [UnlitMaterial(color: color.withAlphaComponent(alpha))]
            let mesh = MeshResource.generateBox(size: [1.0, 1.0, 1.0])

            for _ in 0...11 {
                let wire = ModelEntity(mesh: mesh, materials: materials)
                wires.append(wire)
                entity.addChild(wire)
            }
            
            self.entity = entity
            update(with: anchor)
        }
        
        fileprivate func update(with anchor: ObjectAnchor) {
            entity.transform = Transform(
                scale: entity.transform.scale,
                rotation: entity.transform.rotation,
                translation: anchor.boundingBox.center
            )
            
            // Nur bei Veränderung aktualisieren
            guard anchor.boundingBox.extent != extent else { return }
            extent = anchor.boundingBox.extent

            for index in 0...3 {
                wires[index].scale = SIMD3<Float>(extent.x, thickness, thickness)
                wires[index].position = [
                    0,
                    extent.y / 2 * (index % 2 == 0 ? -1 : 1),
                    extent.z / 2 * (index < 2 ? -1 : 1)
                ]
            }
            
            for index in 4...7 {
                wires[index].scale = SIMD3<Float>(thickness, extent.y, thickness)
                wires[index].position = [
                    extent.x / 2 * (index % 2 == 0 ? -1 : 1),
                    0,
                    extent.z / 2 * (index < 6 ? -1 : 1)
                ]
            }
            
            for index in 8...11 {
                wires[index].scale = SIMD3<Float>(thickness, thickness, extent.z)
                wires[index].position = [
                    extent.x / 2 * (index % 2 == 0 ? -1 : 1),
                    extent.y / 2 * (index < 10 ? -1 : 1),
                    0
                ]
            }
        }
    }
}

