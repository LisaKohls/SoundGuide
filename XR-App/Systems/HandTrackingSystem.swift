//
//  HandTrackingSystem.swift
//  XR-App
//
//  Created by Lisa Kohls on 01.05.25.
//  Reference: https://developer.apple.com/documentation/visionos/tracking-and-visualizing-hand-movement

/*
 Abstract:
 A system that updates entities that have hand-tracking components.
 */

import RealityKit
import ARKit

/// A system that provides hand-tracking capabilities.
struct HandTrackingSystem: System {
    
    static var handTrackingProvider: HandTrackingProvider?
    static var arSession = ARKitSession()
    
    static var latestLeftHand: HandAnchor?
    static var latestRightHand: HandAnchor?
    
    static var detectedObjects: [Entity] = []
    static var onObjectTouched: ((String) -> Void)?
    
    init(scene: RealityKit.Scene) {}
    
    @MainActor
    static func configure(with appState: AppState) {
        Task {
            self.handTrackingProvider = await appState.startHandTracking()
            await runSession()
        }
    }
    
    @MainActor
    static func runSession() async {
        guard let handTracking = self.handTrackingProvider else {
            return
        }
        
        // Start to collect each hand-tracking anchor.
        for await anchorUpdate in handTracking.anchorUpdates {
            // Check whether the anchor is on the left or right hand.
            switch anchorUpdate.anchor.chirality {
            case .left:
                self.latestLeftHand = anchorUpdate.anchor
            case .right:
                self.latestRightHand = anchorUpdate.anchor
            }
        }
    }
    
    /// The query this system uses to find all entities with the hand-tracking component.
    static let query = EntityQuery(where: .has(HandTrackingComponent.self))
    
    /// Performs any necessary updates to the entities with the hand-tracking component.
    /// - Parameter context: The context for the system to update.
    func update(context: SceneUpdateContext) {
        let handEntities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        
        for entity in handEntities {
            guard var handComponent = entity.components[HandTrackingComponent.self] else { continue }
            
            if handComponent.fingers.isEmpty {
                self.addJoints(to: entity, handComponent: &handComponent)
            }
            
            // Get the hand anchor for the component, depending on its chirality.
            guard let handAnchor: HandAnchor = switch handComponent.chirality {
            case .left: Self.latestLeftHand
            case .right: Self.latestRightHand
            default: nil
            } else { continue }
            
            // Iterate through all of the anchors on the hand skeleton.
            if let handSkeleton = handAnchor.handSkeleton {
                for (jointName, jointEntity) in handComponent.fingers {
                    // The current transform of the person's hand joint.
                    let anchorFromJointTransform = handSkeleton.joint(jointName).anchorFromJointTransform
                    
                    // Update the joint entity to match the transform of the person's hand joint.
                    jointEntity.setTransformMatrix(
                        handAnchor.originFromAnchorTransform * anchorFromJointTransform,
                        relativeTo: nil
                    )
                    
                    for object in Self.detectedObjects {
                        // Distance between hands and each found object
                        let distance = simd_distance(jointEntity.position(relativeTo: nil), object.position(relativeTo: nil))
                        if distance < 0.06 {
                            let name = object.name
                            if !name.isEmpty {
                                Self.onObjectTouched?(name)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Performs any necessary setup to the entities with the hand-tracking component.
    /// - Parameters:
    ///   - entity: The entity to perform setup on.
    ///   - handComponent: The hand-tracking component to update.
    func addJoints(to handEntity: Entity, handComponent: inout HandTrackingComponent) {
        /// The size of the sphere mesh.
        let radius: Float = 0.001
        
        /// The material to apply to the sphere entity.
        let material = SimpleMaterial(color: .white, isMetallic: false)
        
        /// The sphere entity that represents a joint in a hand.
        let sphereEntity = ModelEntity(
            mesh: .generateSphere(radius: radius),
            materials: [material]
        )
        
        // For each joint, create a sphere and attach it to the fingers.
        for bone in Hand.joints {
            // Add a duplication of the sphere entity to the hand entity.
            let newJoint = sphereEntity.clone(recursive: false)
            handEntity.addChild(newJoint)
            
            // Attach the sphere to the finger.
            handComponent.fingers[bone.0] = newJoint
        }
        
        // Apply the updated hand component back to the hand entity.
        handEntity.components.set(handComponent)
    }
}
